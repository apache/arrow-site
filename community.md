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

## Questions?

### Mailing lists

These arrow.apache.org mailing lists are for project discussion:

<ul>
  <li> <code>user@</code> is for questions on using Apache Arrow libraries {% include mailing_list_links.html list="user" %} </li>
  <li> <code>dev@</code> is for discussions about contributing to the project development {% include mailing_list_links.html list="dev" %} </li>
</ul>

#### Tags

The mailing lists follow the convention of prefixing subjects with one or more
tags in order to clarify the scope and purpose of messages. For example:

- [ANNOUNCE] Apache Arrow 11.0.0 released
- [DISCUSS][C++] C++ API as a user-facing API
- [Java][Arrow IPC] Extreme memory usage when reading feather files

When emailing one of the lists, please prefix the subject line with one or more
tags. Depending the topic of your email, tags may include one or more:

- Supported Enivronments: e.g., `[C++]`, `[Java]`, `[Python]`, etc.
- Specifications and Protocols: e.g., `[Format]`, `[Flight RPC]`, `[ADBC]`, etc.

You may also prefix your subject line with `[DISCUSS]` if your email is intended
to prompt a discussion rather than get an answer to a specific question.

#### Voting

Votes are held periodically on the dev@ mailing list and are indicated by the
`[VOTE]` prefix. These votes are part of the formal [Apache Software Foundation
voting process](https://community.apache.org/committers/voting.html). Members of
the community are encouraged to engage with these posts by replying with a body
of "+1 (non-binding)" if they are in support of the respective proposal. The
result of a vote will be posted back to the dev@ mailing list with the prefix
`[VOTE][RESULT]`.

#### Other Lists

You may also wish to subscribe to these lists, which capture some activity streams:

<ul>
  <li> <code>issues@</code> for the creation of GitHub issues {% include mailing_list_links.html list="issues" %} </li>
  <li> <code>commits@</code> for commits to the <a href="https://github.com/apache/arrow">apache/arrow</a> and <a href="https://github.com/apache/arrow-site">apache/arrow-site</a> repositories (typically to <code>master</code> only) {% include mailing_list_links.html list="commits" %} </li>
  <li> <code>builds@</code> for nightly build reports {% include mailing_list_links.html list="builds" %} </li>
</ul>

In addition, we have some "firehose" lists, which exist so that development
activity is captured in email form for archival purposes.

<ul>
  <li> <code>github@</code> for all activity on the GitHub repositories {% include mailing_list_links.html list="github" %} </li>
</ul>

### Stack Overflow

For questions on how to use Arrow libraries, you may want to use the Stack
Overflow tag
[apache-arrow](https://stackoverflow.com/questions/tagged/apache-arrow) in
addition to the programming language. Some languages and subprojects may have
their own tags (for example,
[pyarrow](https://stackoverflow.com/questions/tagged/pyarrow)).

### GitHub issues

We use GitHub issues as a way to ask questions and engage with the Arrow developer
community and for maintaining a queue of development work and as the public
record of work on the project. We use the mailing lists for development discussions,
where a lengthy discussions is required.

## Contributing

As mentioned above, we use [GitHub](https://github.com/apache/arrow) for our issue
tracker and for source control. See the
[contribution guidelines]({{ site.baseurl }}/docs/developers/contributing.html) for more.
