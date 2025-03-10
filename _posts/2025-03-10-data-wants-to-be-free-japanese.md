---
layout: post
lang: ja-JP
title: "データは自由になりたい：Apache Arrowでデータ交換は高速"
description: ""
date: "2025-02-28 00:00:00"
author: David Li, Ian Cook, Matt Topol
categories: [application]
image:
  path: /img/arrow-result-transfer/part-1-share-image.png
  height: 1200
  width: 705
translations:
  - language: 原文（English）
    post_id: 2025-02-28-data-wants-to-be-free
---

<!--
{% comment %}
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to you under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
{% endcomment %}
-->

<style>
.a-header {
  color: #984EA3;
  font-weight: bold;
}
.a-data {
  color: #377EB8;
  font-weight: bold;
}
.a-length {
  color: #FF7F00;
  font-weight: bold;
}
.a-padding {
  color: #E41A1C;
  font-weight: bold;
}
</style>

_この記事はデータベースとクエリーエンジン間のデータ交換フォーマットとしてなぜArrowが使われているのかという謎を解くシリーズの２記事目です。_

{% include arrow_result_transfer_series_japanese.md %}

データ技術者として、データはよく「人質に取られた」ことをわかっています。
データをもらい次第データを使わずに、まず時間を掛けなければいけません。
非効率的で雑然ＣＳＶファイルを整理する時間を掛けたり、
型落ちのクエリエンジンが数GBのデータに苦労するのを待つ時間を掛けたり、
データがソケットを介して受信するのを待つ時間を掛けたり。
今回はこの三目の問題を注目します。
マルチギガビットネットワークの時代に、そもそもこの問題がまだ起こっているのはどうしてでしょうか？
間違いなく、この問題はぜったいまだ起こっています。
[Mark RaasveldtとHannes Mühleisenの２０１７年の論文](https://doi.org/10.14778/3115404.3115408)[^freepdf]によって、１０秒しかかからないはずのデータセットを送受信はあるデータシステムが**１０分**以上をかかります[^ten]。

[^freepdf]: [VLDB](https://www.vldb.org/pvldb/vol10/p1022-muehleisen.pdf)から論文を無料でダウンロードできます。
[^ten]: 論文のFigure 1に、ベースラインとしてnetcatは１０秒でＣＳＶファイルを送信にたいして、HiveとMongoDBは６００秒以上がかかるのを示します。もちろん、ＣＳＶは解析されてないので、この比較は完全に平等のではありません。でも問題の規模を把握できます。

どうして必要より６０倍以上の時間がかかるでしょうか？
[この前に論じていた通り、ツールはデータシリアライズのオーバーヘッドに悩まされています。]({% link _posts/2025-01-10-arrow-result-transfer.md %})
でもArrowは手伝えます。
それでもっと具体的にします：データシリアライズフォーマットの影響を示すために、PostgreSQLとArrowは同じデータをどうやってエンコードするのを比較します。
その後、Arrow HTTPやArrow FlightなどというArrowでプロトコルを作る色々な方法を説明し、各方法の使い方も説明します。

## PostgreSQL対Arrow：データシリアライズ

Let’s compare the [PostgreSQL binary
format](https://www.postgresql.org/docs/current/sql-copy.html#id-1.9.3.55.9.4)
and [Arrow
IPC](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc)
on the same dataset, and show how Arrow (with all the benefit of hindsight)
makes better trade-offs than its predecessors.

When you execute a query with PostgreSQL, the client/driver uses the
PostgreSQL wire protocol to send the query and get back the result.  Inside
that protocol, the result set is encoded with the PostgreSQL binary format[^textbinary].

[^textbinary]: There is a text format too, and that is often the default used by many clients.  We won't discuss it here.

First, we’ll create a table and fill it with data:

```
postgres=# CREATE TABLE demo (id BIGINT, val TEXT, val2 BIGINT);
CREATE TABLE
postgres=# INSERT INTO demo VALUES (1, 'foo', 64), (2, 'a longer string', 128), (3, 'yet another string', 10);
INSERT 0 3
```

We can then use the COPY command to dump the raw binary data from PostgreSQL into a file:

```
postgres=# COPY demo TO '/tmp/demo.bin' WITH BINARY;
COPY 3
```

Then we can annotate the actual bytes of the data based on the [documentation](https://www.postgresql.org/docs/current/sql-copy.html#id-1.9.3.55.9.4):

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>00000000: <span class="a-header">50 47 43 4f 50 59 0a ff  PGCOPY..</span>  <span class="a-header">COPY signature, flags,</span>
00000008: <span class="a-header">0d 0a 00 00 00 00 00 00  ........</span>  <span class="a-header">and extension</span>
00000010: <span class="a-header">00 00 00</span> <span class="a-padding">00 03</span> <span class="a-length">00 00 00</span>  <span class="a-header">...</span><span class="a-padding">..</span><span class="a-length">...</span>  <span class="a-padding">Values in row</span>
00000018: <span class="a-length">08</span> <span class="a-data">00 00 00 00 00 00 00</span>  <span class="a-length">.</span><span class="a-data">.......</span>  <span class="a-length">Length of value</span>
00000020: <span class="a-data">01</span> <span class="a-length">00 00 00 03</span> <span class="a-data">66 6f 6f</span>  <span class="a-data">.</span><span class="a-length">....</span><span class="a-data">foo</span>  <span class="a-data">Data</span>
00000028: <span class="a-length">00 00 00 08</span> <span class="a-data">00 00 00 00</span>  <span class="a-length">....</span><span class="a-data">....</span>
00000030: <span class="a-data">00 00 00 40</span> <span class="a-padding">00 03</span> <span class="a-length">00 00</span>  <span class="a-data">...@</span><span class="a-padding">..</span><span class="a-length">..</span>
00000038: <span class="a-length">00 08</span> <span class="a-data">00 00 00 00 00 00</span>  <span class="a-length">..</span><span class="a-data">......</span>
00000040: <span class="a-data">00 02</span> <span class="a-length">00 00 00 0f</span> <span class="a-data">61 20</span>  <span class="a-data">..</span><span class="a-length">....</span><span class="a-data">a </span>
00000048: <span class="a-data">6c 6f 6e 67 65 72 20 73  longer s</span>
00000050: <span class="a-data">74 72 69 6e 67</span> <span class="a-length">00 00 00</span>  <span class="a-data">tring</span><span class="a-length">...</span>
00000058: <span class="a-length">08</span> <span class="a-data">00 00 00 00 00 00 00</span>  <span class="a-length">.</span><span class="a-data">.......</span>
00000060: <span class="a-data">80</span> <span class="a-padding">00 03</span> <span class="a-length">00 00 00 08</span> <span class="a-data">00</span>  <span class="a-data">.</span><span class="a-padding">..</span><span class="a-length">....</span><span class="a-data">.</span>
00000068: <span class="a-data">00 00 00 00 00 00 03</span> <span class="a-length">00</span>  <span class="a-data">.......</span><span class="a-length">.</span>
00000070: <span class="a-length">00 00 12</span> <span class="a-data">79 65 74 20 61</span>  <span class="a-length">...</span><span class="a-data">yet a</span>
00000078: <span class="a-data">6e 6f 74 68 65 72 20 73  nother s</span>
00000080: <span class="a-data">74 72 69 6e 67</span> <span class="a-length">00 00 00</span>  <span class="a-data">tring</span><span class="a-length">...</span>
00000088: <span class="a-length">08</span> <span class="a-data">00 00 00 00 00 00 00</span>  <span class="a-length">.</span><span class="a-data">.......</span>
00000090: <span class="a-data">0a</span> <span class="a-padding">ff ff</span>                 <span class="a-data">.</span><span class="a-padding">..</span>       <span class="a-padding">End of stream</span></code></pre></div></div>

Honestly, PostgreSQL’s binary format is quite understandable, and compact at first glance. It's just a series of length-prefixed fields. But a closer look isn’t so favorable. **PostgreSQL has overheads proportional to the number of rows and columns**:

* Every row has a 2 byte prefix for the number of values in the row. *But the data is tabular—we already know this info, and it doesn’t change\!*
* Every value of every row has a 4 byte prefix for the length of the following data, or \-1 if the value is NULL. *But we know the data types, and those don’t change—plus, values of most types have a fixed, known length\!*
* All values are big-endian. *But most of our devices are little-endian, so the data has to be converted.*

For example, a single column of int32 values would have 4 bytes of data and 6 bytes of overhead per row—**60% is “wasted\!”**[^1] The ratio gets a little better with more columns (but not with more rows); in the limit we approach “only” 50% overhead.  And then each of the values has to be converted (even if endian-swapping is trivial).  To PostgreSQL’s credit, its format is at least cheap and easy to parse—[other formats](https://protobuf.dev/programming-guides/encoding/) get fancy with tricks like “varint” encoding which are quite expensive.

How does Arrow compare? We can use [ADBC](https://arrow.apache.org/adbc/current/driver/postgresql.html) to pull the PostgreSQL table into an Arrow table, then annotate it like before:

```console
>>> import adbc_driver_postgresql.dbapi
>>> import pyarrow.ipc
>>> conn = adbc_driver_postgresql.dbapi.connect("...")
>>> cur = conn.cursor()
>>> cur.execute("SELECT * FROM demo")
>>> data = cur.fetchallarrow()
>>> writer = pyarrow.ipc.new_stream("demo.arrows", data.schema)
>>> writer.write_table(data)
>>> writer.close()
```

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>00000000: <span class="a-length">ff ff ff ff d8 00 00 00  ........  IPC message length</span>
00000008: <span class="a-header">10 00 00 00 00 00 0a 00  ........  IPC schema</span>
&vellip;         <span class="a-header">(208 bytes)</span>
000000e0: <span class="a-length">ff ff ff ff f8 00 00 00  ........  IPC message length</span>
000000e8: <span class="a-header">14 00 00 00 00 00 00 00  ........  IPC record batch</span>
&vellip;         <span class="a-header">(240 bytes)</span>
000001e0: <span class="a-data">01 00 00 00 00 00 00 00  ........  Data for column #1</span>
000001e8: <span class="a-data">02 00 00 00 00 00 00 00  ........</span>
000001f0: <span class="a-data">03 00 00 00 00 00 00 00  ........</span>
000001f8: <span class="a-length">00 00 00 00 03 00 00 00  ........  String offsets</span>
00000200: <span class="a-length">12 00 00 00 24 00 00 00  ....$...</span>
00000208: <span class="a-data">66 6f 6f 61 20 6c 6f 6e  fooa lon  Data for column #2</span>
00000210: <span class="a-data">67 65 72 20 73 74 72 69  ger stri</span>
00000218: <span class="a-data">6e 67 79 65 74 20 61 6e  ngyet an</span>
00000220: <span class="a-data">6f 74 68 65 72 20 73 74  other st</span>
00000228: <span class="a-data">72 69 6e 67</span> <span class="a-padding">00 00 00 00</span>  <span class="a-data">ring</span><span class="a-padding">....  Alignment padding</span>
00000230: <span class="a-data">40 00 00 00 00 00 00 00  @.......  Data for column #3</span>
00000238: <span class="a-data">80 00 00 00 00 00 00 00  ........</span>
00000240: <span class="a-data">0a 00 00 00 00 00 00 00  ........</span>
00000248: <span class="a-length">ff ff ff ff 00 00 00 00  ........  IPC end-of-stream</span></code></pre></div></div>

Arrow looks quite…intimidating…at first glance. There’s a giant header that don’t seem related to our dataset at all, plus mysterious padding that seems to exist solely to take up space. But the important thing is that **the overhead is fixed**. Whether you’re transferring one row or a billion, the overhead doesn’t change. And unlike PostgreSQL, **no per-value parsing is required**.

Instead of putting lengths of values everywhere, Arrow groups values of the same column (and hence same type) together, so it just needs the length of the buffer[^header].  Overhead isn't added where it isn't otherwise needed.  Strings still have a length per value.  Nullability is instead stored in a bitmap, which is omitted if there aren’t any NULL values (as it is here). Because of that, more rows of data doesn’t increase the overhead; instead, the more data you have, the less you pay.

[^header]: That's what's being stored in that ginormous header (among other things)—the lengths of all the buffers.

Even the header isn’t actually the disadvantage it looks like. The header contains the schema, which makes the data stream self-describing. With PostgreSQL, you need to get the schema from somewhere else. So we aren’t making an apples-to-apples comparison in the first place: PostgreSQL still has to transfer the schema, it’s just not part of the “binary format” that we’re looking at here[^binaryheader].

[^binaryheader]: And conversely, the PGCOPY header is specific to the COPY command we executed to get a bulk response.

There’s actually another problem with PostgreSQL: alignment. The 2 byte field count at the start of every row means all the 8 byte integers after it are unaligned. And that requires extra effort to handle properly (e.g. explicit unaligned load idioms), lest you suffer [undefined behavior](https://port70.net/~nsz/c/c11/n1570.html#6.3.2.3p7), a performance penalty, or even a runtime error. Arrow, on the other hand, strategically adds some padding to keep data aligned, and lets you use little-endian or big-endian byte order depending on your data. And Arrow doesn’t apply expensive encodings to the data that require further parsing. So generally, **you can use Arrow data as-is without having to parse every value**.

That’s the benefit of Arrow being a standardized data format. By using Arrow for serialization, data coming off the wire is already in Arrow format, and can furthermore be directly passed on to [DuckDB](https://duckdb.org), [pandas](https://pandas.pydata.org), [polars](https://pola.rs), [cuDF](https://docs.rapids.ai/api/cudf/stable/), [DataFusion](https://datafusion.apache.org), or any number of systems. Meanwhile, even if the PostgreSQL format addressed these problems—adding padding to align fields, using little-endian or making endianness configurable, trimming the overhead—you’d still end up having to convert the data to another format (probably Arrow) to use downstream.

Even if you really did want to use the PostgreSQL binary format everywhere[^3], the documentation rather unfortunately points you to the C source code as the documentation. Arrow, on the other hand, has a [specification](https://github.com/apache/arrow/tree/main/format), [documentation](https://arrow.apache.org/docs/format/Columnar.html), and multiple [implementations](https://arrow.apache.org/docs/#implementations) (including third-party ones) across a dozen languages for you to pick up and use in your own applications.

Now, we don’t mean to pick on PostgreSQL here. Obviously, PostgreSQL is a full-featured database with a storied history, a different set of goals and constraints than Arrow, and many happy users. Arrow isn’t trying to compete in that space. But their domains do intersect. PostgreSQL’s wire protocol has [become a de facto standard](https://datastation.multiprocess.io/blog/2022-02-08-the-world-of-postgresql-wire-compatibility.html), with even brand new products like Google’s AlloyDB using it, and so its design affects many projects[^4]. In fact, AlloyDB is a great example of a shiny new columnar query engine being locked behind a row-oriented client protocol from the 90s. So [Amdahl’s law](https://en.wikipedia.org/wiki/Amdahl's_law) rears its head again—optimizing the “front” and “back” of your data pipeline doesn’t matter when the middle is what's holding you back.

## A quiver of Arrow (projects)

So if Arrow is so great, how can we actually use it to build our own protocols? Luckily, Arrow comes with a variety of building blocks for different situations.

* We just talked about [**Arrow IPC**](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc) before. Where Arrow is the in-memory format defining how arrays of data are laid out, er, in memory, Arrow IPC defines how to serialize and deserialize Arrow data so it can be sent somewhere else—whether that means being written to a file, to a socket, into a shared buffer, or otherwise. Arrow IPC organizes data as a sequence of messages, making it easy to stream over your favorite transport, like WebSockets.
* [**Arrow HTTP**](https://github.com/apache/arrow-experiments/tree/main/http) is “just” streaming Arrow IPC over HTTP. The Arrow community is working on standardizing it, so that different clients agree on how exactly to do this. There’s examples of clients and servers across several languages, how to use HTTP Range requests, using multipart/mixed requests to send combined JSON and Arrow responses, and more. While not a full protocol in and of itself, it’ll fit right in when building REST APIs.
* [**Disassociated IPC**](https://arrow.apache.org/docs/format/DissociatedIPC.html) combines Arrow IPC with advanced network transports like [UCX](https://openucx.org/) and [libfabric](https://ofiwg.github.io/libfabric/). For those who require the absolute best performance and have the specialized hardware to boot, this allows you to send Arrow data at full throttle, taking advantage of scatter-gather, Infiniband, and more.
* [**Arrow Flight SQL**](https://arrow.apache.org/docs/format/FlightSql.html) is a fully defined protocol for accessing relational databases. Think of it as an alternative to the full PostgreSQL wire protocol: it defines how to connect to a database, execute queries, fetch results, view the catalog, and so on. For database developers, Flight SQL provides a fully Arrow-native protocol with clients for several programming languages and drivers for ADBC, JDBC, and ODBC—all of which you don’t have to build yourself.
* And finally, [**ADBC**](https://arrow.apache.org/docs/format/ADBC.html) actually isn’t a protocol. Instead, it’s an API abstraction layer for working with databases (like JDBC and ODBC—bet you didn’t see that coming), that’s Arrow-native and doesn’t require transposing or converting columnar data back and forth. ADBC gives you a single API to access data from multiple databases, whether they use Flight SQL or something else under the hood, and if a conversion is absolutely necessary, ADBC handles the details so that you don’t have to build out a dozen connectors on your own.

So to summarize:

* If you’re *using* a database or other data system, you want [**ADBC**](https://arrow.apache.org/adbc/).
* If you’re *building* a database, you want [**Arrow Flight SQL**](https://arrow.apache.org/docs/format/FlightSql.html).
* If you’re working with specialized networking hardware (you’ll know if you are—that stuff doesn’t come cheap), you want the [**Disassociated IPC Protocol**](https://arrow.apache.org/docs/format/DissociatedIPC.html).
* If you’re *designing* a REST-ish API, you want [**Arrow HTTP**](https://github.com/apache/arrow-experiments/tree/main/http).
* And otherwise, you can roll-your-own with [**Arrow IPC**](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc).

![A flowchart of the decision points.]({{ site.baseurl }}/assets/data_wants_to_be_free/flowchart.png){:class="img-responsive" width="100%"}

## まとめ

Existing client protocols can be wasteful. Arrow offers better efficiency and avoids design pitfalls from the past. And Arrow makes it easy to build and consume data APIs with a variety of standards like Arrow IPC, Arrow HTTP, and ADBC. By using Arrow serialization in protocols, everyone benefits from easier, faster, and simpler data access, and we can avoid accidentally holding data captive behind slow and inefficient interfaces.

---

[^1]: Of course, it’s not fully wasted, as null/not-null is data as well. But for accounting purposes, we’ll be consistent and call lengths, padding, bitmaps, etc. “overhead”.

[^2]: And if your data really benefits from heavy compression, you can always use something like Apache Parquet, which implements lots of fancy encodings to save space and can still be decoded to Arrow data reasonably quickly.

[^3]: [And people do…](https://datastation.multiprocess.io/blog/2022-02-08-the-world-of-postgresql-wire-compatibility.html)

[^4]: [We have some experience with the PostgreSQL wire protocol, too.](https://github.com/apache/arrow-adbc/blob/ed18b8b221af23c7b32312411da10f6532eb3488/c/driver/postgresql/copy/reader.h)
