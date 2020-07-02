---
layout: article
title: Committers
description: "List of project-management committee (PMC) members and committers on the Apache Arrow project."
---

## Apache Arrow Project Governance

The Arrow project is a part of the Apache Software Foundation and follows its [project management guidelines](https://www.apache.org/foundation/how-it-works.html#management), which promote community-led consensus decisionmaking, [independent](http://community.apache.org/projectIndependence.html) of commercial influence.

### Project Management Committee (PMC)

The [PMC](https://www.apache.org/foundation/how-it-works.html#pmc-members) governs the project. Members [vote](https://www.apache.org/foundation/voting.html) on important decisions, including releases and inviting committers to join the PMC.

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

Contributors who have demonstrated a sustained commitment to the project, not only authoring code but also reviewing others' patches and exercising good judgment, may be invited by the PMC to become [committers](https://www.apache.org/foundation/how-it-works.html#committers). Committers are authorized to merge code patches to the project and serve as non-voting project maintainers.

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
