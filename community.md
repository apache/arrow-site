---
layout: article
title: Apache Arrow Community
description: Links and resources for participating in Apache Arrow
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

# Apache Arrow Community

<hr class="mt-4 mb-3">

We welcome participation from everyone and encourage you to join us, ask
questions, and get involved.

All participation in the Apache Arrow project is governed by the Apache
Software Foundation's [code of conduct](https://www.apache.org/foundation/policies/conduct.html).

## Mailing Lists

These arrow.apache.org mailing lists are for project discussion:

<ul>
  <li> <code>user@</code> is for questions on using Apache Arrow libraries {% include mailing_list_links.html list="user" %} </li>
  <li> <code>dev@</code> is for discussions about contributing to the project development {% include mailing_list_links.html list="dev" %} </li>
</ul>

### Tags

The mailing lists follow the convention of prefixing subjects with one or more
tags in order to clarify the scope and purpose of messages. For example:

- [ANNOUNCE] Apache Arrow 11.0.0 released
- [DISCUSS][C++] C++ API as a user-facing API
- [Java][Arrow IPC] Extreme memory usage when reading feather files

When emailing one of the lists, please prefix the subject line with one or more
tags. Depending the topic of your email, tags may include one or more:

- Supported Environments: e.g., `[C++]`, `[Java]`, `[Python]`, etc.
- Specifications and Protocols: e.g., `[Format]`, `[Flight RPC]`, `[ADBC]`, etc.

You may also prefix your subject line with `[DISCUSS]` if your email is intended
to prompt a discussion rather than get an answer to a specific question.

### Voting

Votes are held periodically on the dev@ mailing list and are indicated by the
`[VOTE]` prefix. These votes are part of the formal [Apache Software Foundation
voting process](https://community.apache.org/committers/voting.html). Members of
the community are encouraged to engage with these posts by replying with a body
of "+1 (non-binding)" if they are in support of the respective proposal. The
result of a vote will be posted back to the dev@ mailing list with the prefix
`[RESULT][VOTE]`.

#### Other Lists

You may also wish to subscribe to these lists, which capture some activity streams:

<ul>
  <li> <code>issues@</code> for the creation of GitHub issues {% include mailing_list_links.html list="issues" %} </li>
  <li> <code>commits@</code> for commits to the <a href="https://github.com/apache/arrow">apache/arrow</a> and <a href="https://github.com/apache/arrow-site">apache/arrow-site</a> repositories (typically to <code>main</code> only) {% include mailing_list_links.html list="commits" %} </li>
  <li> <code>builds@</code> for nightly build reports {% include mailing_list_links.html list="builds" %} </li>
</ul>

In addition, we have some "firehose" lists, which exist so that development
activity is captured in email form for archival purposes.

<ul>
  <li> <code>github@</code> for all activity on the GitHub repositories {% include mailing_list_links.html list="github" %} </li>
</ul>

## GitHub

<p>We use GitHub Issues as a place to report bugs, request new features, and track the queue of development work. For usage questions, our repositories use GitHub Discussions as an alternative to the <code>user@</code> mailing list {% include mailing_list_links.html list="user" %}. Discussions are mirrored to the <code>user@</code> mailing list {% include mailing_list_links.html list="user" %} and users are welcome to ask usage questions in either location. Maintainers may convert usage type Issues to Discussions as appropriate.</p>

Please create Issues or start Discussions on the appropriate repository:

Implementations:

- Go: [apache/arrow-go](http://github.com/apache/arrow-go) ([Issues](http://github.com/apache/arrow-go/issues), [Discussions](https://github.com/apache/arrow-go/discussions))
- Java: [apache/arrow-java](http://github.com/apache/arrow-java) ([Issues](http://github.com/apache/arrow-java/issues), [Discussions](https://github.com/apache/arrow-java/discussions))
- Julia: [apache/arrow-julia](http://github.com/apache/arrow-julia) ([Issues](http://github.com/apache/arrow-julia/issues), [Discussions](https://github.com/apache/arrow-julia/discussions))
- nanoarrow: [apache/arrow-nanoarrow](https://github.com/apache/arrow-nanoarrow) ([Issues](https://github.com/apache/arrow-nanoarrow/issues), [Discussions](https://github.com/apache/arrow-nanoarrow/discussions))
- Rust: [apache/arrow-rs](http://github.com/apache/arrow-rs) ([Issues](http://github.com/apache/arrow-rs/issues), [Discussions](http://github.com/apache/arrow-rs/discussions))
- .NET: [apache/arrow-dotnet](https://github.com/apache/arrow-dotnet) ([Issues](https://github.com/apache/arrow-dotnet/issues), [Discussions](https://github.com/apache/arrow-dotnet/discussions))
- All Others: [apache/arrow](http://github.com/apache/arrow) ([Issues](http://github.com/apache/arrow/issues), [Discussions](http://github.com/apache/arrow/discussions))

Standards:

- ADBC: [apache/arrow-adbc](https://github.com/apache/arrow-adbc) ([Issues](https://github.com/apache/arrow-adbc/issues), [Discussions](https://github.com/apache/arrow-adbc/discussions))
- All Others: [apache/arrow](http://github.com/apache/arrow) ([Issues](http://github.com/apache/arrow/issues), [Discussions](http://github.com/apache/arrow/discussions))

## Stack Overflow

For questions on how to use Arrow libraries, you may want to use the Stack
Overflow tag
[apache-arrow](https://stackoverflow.com/questions/tagged/apache-arrow) in
addition to the programming language. Some languages and subprojects may have
their own tags (for example,
[pyarrow](https://stackoverflow.com/questions/tagged/pyarrow)).

## Meetings

We host online meetings to provide spaces for synchronous discussions about the Arrow project. These discussions usually focus on topics of interest to developers who are contributing to Arrow, but we welcome users of Arrow to join. Currently there are three series of regularly held meetings:

<table class="table table-striped"><thead>
<tr>
<th>Meeting</th>
<th>Frequency</th>
<th>Notes</th>
</tr>
</thead><tbody>
  <tr>
    <td>Arrow community meeting</td>
    <td>Biweekly</td>
    <td><a href="https://docs.google.com/document/d/1xrji8fc6_24TVmKiHJB4ECX1Zy2sy2eRbBjpVJMnPmk/">Google Doc</a></td>
  </tr>
  <tr>
    <td>Arrow R package development meeting</td>
    <td>Biweekly</td>
    <td><a href="https://docs.google.com/document/d/1nSIfJw8mfqtvScqvSVqmktpWff80pFmkqiZT7nTtiDo/">Google Doc</a></td>
  </tr>
  <tr>
    <td>Arrow Rust sync meeting</td>
    <td>Varies</td>
    <td><a href="https://docs.google.com/document/d/1atCVnoff5SR4eM4Lwf2M1BBJTY6g3_HUNR6qswYJW_U/">Google Doc</a></td>
  </tr>
  <tr>
    <td>PyArrow development meeting</td>
    <td>Every 4 weeks</td>
    <td><a href="https://docs.google.com/document/d/1ioiJdEYf5mJwQ-rOjzjPYCeHTjOhAPo5ppUHy6iBrxU/">Google Doc</a></td>
  </tr>
</tbody></table>

For information about how to attend these meetings, see the meeting notes and subscribe to the <code>dev@</code> mailing list as described above. The hosts of some of these meetings send reminder emails to the mailing list prior to each meeting with information about how to join.

## Contributing

As mentioned above, we use [GitHub](https://github.com/apache/arrow) for our issue
tracker and for source control. See the
[contribution guidelines]({{ site.baseurl }}/docs/developers/index.html) for more.
