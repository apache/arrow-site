---
layout: article
title: Committers
description: "List of project-management committee (PMC) members and committers on the Apache Arrow project."
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

## Apache Arrow Project Governance

The Arrow project is a part of the Apache Software Foundation and follows
its [project management guidelines](https://www.apache.org/foundation/how-it-works.html#management),
which promote community-led consensus decisionmaking,
[independent](https://community.apache.org/projectIndependence.html) of
commercial influence.

### Project Management Committee (PMC)

The [PMC](https://www.apache.org/foundation/how-it-works.html#pmc-members)
governs the project. Members [vote](https://www.apache.org/foundation/voting.html)
on important decisions, including releases and inviting committers to join the PMC.

<table class="table table-striped"><thead>
<tr>
<th>Name</th>
<th>Affiliation</th>
</tr>
</thead><tbody>
  {% assign sorted_committers = site.data.committers | sort: "name" %}
  {% for person in sorted_committers %}
    {% if person.role == "VP" %}
  <tr>
    <td><a href="https://people.apache.org/phonebook.html?uid={{ person.alias }}">{{ person.name }}</a> (Chair)</td>
    <td>{{ person.affiliation }}</td>
  </tr>
    {% endif %}
  {% endfor %}
  {% for person in sorted_committers %}
    {% if person.role == "PMC" %}
  <tr>
    <td><a href="https://people.apache.org/phonebook.html?uid={{ person.alias }}">{{ person.name }}</a></td>
    <td>{{ person.affiliation }}</td>
  </tr>
    {% endif %}
  {% endfor %}
</tbody></table>

### Committers

Contributors who have demonstrated a sustained commitment to the
project may be invited by the PMC to become
[committers](https://www.apache.org/foundation/how-it-works.html#committers).
Committers are authorized to merge code patches to the project's
repositories and serve as non-voting project maintainers. See the
"Becoming a committer" section below for more details.

<table class="table table-striped"><thead>
<tr>
<th>Name</th>
<th>Affiliation</th>
</tr>
</thead><tbody>
  {% assign sorted_committers = site.data.committers | sort: "name" %}
  {% for person in sorted_committers %}
    {% if person.role == "Committer" %}
  <tr>
    <td><a href="https://people.apache.org/phonebook.html?uid={{ person.alias }}">{{ person.name }}</a></td>
    <td>{{ person.affiliation }}</td>
  </tr>
    {% endif %}
  {% endfor %}
</tbody></table>

### **Becoming a committer**

There are many ways to [contribute](https://arrow.apache.org/docs/developers/contributing.html)
to the Apache Arrow project, including issue reports,
documentation, tests, and code. Contributors with sustained, high-quality activity
may be invited to become a committer by the PMC.

Becoming a committer is a recognition of sustained
contribution to the project, and comes with the privilege of
committing changes directly in all Arrow github repositories. Becoming
a committer is also a significant responsibility, and committers are
expected to use their status and access to improve the Arrow project
for the entire community.

When considering to invite someone to be a committer, the PMC looks for
contributors who are doing the work and exercising the judgment expected
of a committer already. After all, any contributor can do all of the things a
committer does except for merge a PR. While there is no set list of
requirements, nor a checklist that entitles one to commit privileges,
typical behaviors include:

* Contributions beyond pull requests, such as reviewing other pull requests,
  fixing bugs and documentation, triaging issues, answering community
  questions, improving usability, reducing technical debt, helping
  with CI, verifying releases, debugging in strange environments, etc.

* These contributions to the project should be consistent in quality
  and sustained over time, typically on the order of 6 months or more.

* Assistance growing the size and health of the community via constructive and
  respectful interactions with the rest of the community. Maintaining a
  professional and diplomatic approach and try to find consensus
  amongst other community members.

The mechanics of how the process works is [documented here].  If you
feel you should be offered committer privileges, but have not been,
you can reach out to one of the PMC members or the private at arrow
dot apache dot org mailing list.


[documented here]: https://cwiki.apache.org/confluence/display/ARROW/Inviting+New+Committers+and+PMC+Members
