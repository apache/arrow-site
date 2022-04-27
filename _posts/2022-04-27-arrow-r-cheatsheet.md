---
layout: post
title: Apache Arrow for R Cheatsheet
date: "2022-04-27 00:00:00"
author: stephhazlitt
categories: [application]
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

We are excited to introduce the new [Apache Arrow for R Cheatsheet](https://github.com/apache/arrow/blob/master/r/cheatsheet/arrow-cheatsheet.pdf).

<div align="center">
<a href="https://github.com/apache/arrow/blob/master/r/cheatsheet/arrow-cheatsheet.pdf">
<img src="{{ site.baseurl }}/img/20220427-arrow-r-cheatsheet-thumbnail.png"
     alt="Thumbnail image of the first page of the Arrow for R cheatsheet."
     width="70%" height="70%">
</a>
</div>

## Helping (Not Cheating)

While [cheatsheets](https://en.wikipedia.org/wiki/Cheat_sheet) may have started as a set of notes used without an instructor’s knowledge&mdash;so, ummm, cheating&mdash;using the Arrow for R cheatsheet is definitely not cheating! Today, cheatsheets are a common tool to provide users an introduction to software’s functionality and a quick reference guide to help users get started.

The Arrow for R cheatsheet is intended to be an easy-to-scan introduction to the Arrow R package and Arrow data structures, with getting started sections on some of the package’s main functionality. The cheatsheet includes introductory snippets on using Arrow to read and work with larger-than-memory multi-file data sets, sending and receiving data with Flight, reading data from cloud storage without downloading the data first, and more. The Arrow for R cheatsheet also directs users to the full [Arrow for R package documentation and articles](https://arrow.apache.org/docs/r/index.html) and the [Arrow Cookbook](https://arrow.apache.org/cookbook/r/), both full of code examples and recipes to support users build their Arrow-based data workflows. Finally, the cheatsheet debuts one of the first uses of the hot-off-the-presses Arrow hex sticker, recently made available as part of the [Apache Arrow visual identity guidance](https://arrow.apache.org/visual_identity/).

## Cheatsheet Maintenance

See something that needs updating? Or want to suggest a change? Like software itself, a package cheatsheet needs maintenance to keep pace with new features or user-facing changes. Contributions can be made by downloading and making changes to the [`arrow-cheatsheet.pptx` file](https://github.com/apache/arrow/tree/master/r/cheatsheet) (in Microsoft PowerPoint or Google Slides), and offering the revised `.pptx` and rendered PDF back to the project following the _new_ [New Contributors Guide](https://arrow.apache.org/docs/developers/guide/step_by_step/set_up.html). Since a cheatsheet contribution does not touch the Arrow codebase, cheatsheet contributors don’t need to build the package or worry about running (or writing!) code tests. The New Contributors Guide will walk you through how to get set up with git, fork the Arrow GitHub repository, make a branch, replace the `.pptx` and `.pdf` files with your editions, and contribute the changes with a [Pull Request](https://arrow.apache.org/docs/developers/guide/step_by_step/pr_and_github.html). Questions and support are always available through the [community mailing list](https://arrow.apache.org/community/).

## By the Community For the Community

The Arrow for R cheatsheet was initiated by Mauricio (Pachá) Vargas Sepúlveda ([ARROW-13616](https://issues.apache.org/jira/browse/ARROW-13616)) and was co-developed and reviewed by many Apache Arrow community members. The cheatsheet was created by the community for the community, and anyone in the Arrow community is welcome and encouraged to help with maintenance and offer improvements. Thank you for your support!