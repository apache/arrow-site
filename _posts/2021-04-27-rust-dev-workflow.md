---
layout: post
title: "A New Development Workflow for Arrow's Rust Implementation"
date: "2021-05-04 00:00:00"
author: ruanpa
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

The Apache Arrow Rust community is excited to announce that its migration to a new development workflow is now complete! If you're considering Rust as a language for working with columnar data, read on and see how your use case might benefit from our new and improved project setup.

In recent months, members of the community have been working closely with Arrow's [Project Management Committee][1] and other contributors to expand the set of available workflows for Arrow implementations. The goal was to define a new development process that ultimately:
- Enables a faster release cadence that adheres to [SemVer][15] where appropriate
- Encourages maximum participation from the wider community with unified tooling
- Ensures that we continue to uphold the tenets of [The Apache Way][2]

If you're just here for the highlights, the major outcomes of these discussions are as follows:
- The Rust projects have moved to separate repositories, outside the main Arrow [monorepo][9]
	- [arrow-rs][7] for the core Arrow, Arrow Flight, and Parquet implementations in Rust
	- [arrow-datafusion][8] for DataFusion and Ballista (more on these projects below!)
- The Rust community will use GitHub Issues for tracking feature development and issues, replacing the Jira instance maintained by the Apache Software Foundation (ASF)
- DataFusion and Ballista will follow a new release cycle, independent of the main Arrow releases

But why, as a community, have we decided to change our processes? Let's take a slightly more in-depth look at the Rust implementation's needs.

## Project Structure
The Rust implementation of Arrow actually consists of several distinct projects, or in Rust parlance, ["crates"][3]. In addition to the core crates, namely `arrow`, `arrow-flight`, and `parquet`, we also maintain:
- [DataFusion][4]: an extensible in-memory query execution engine using Arrow as its format
- [Ballista][5]: a distributed compute platform, powered by Apache Arrow and DataFusion

Whilst these projects are all closely related, with many shared contributors, they're very much at different stages in their respective lifecycles. The core Arrow crate, as an implementation of a spec, has strict compatibility requirements with other versions of Arrow, and this is tested via rigorous cross-language integration tests.

However, at the other end of the spectrum, DataFusion and Ballista are still nascent projects in their own right that undergo frequent backwards-incompatible changes. In the old workflow, DataFusion was released in lockstep with Arrow; because DataFusion users often need newly-contributed features or bugfixes on a tighter schedule than Arrow releases, we observed that many people in the community simply resorted to referencing our GitHub repository directly, rather than properly versioned builds on [crates.io][6], Rust's package registry.

Ultimately, the decision was made to split the Rust crates into two separate repositories: [arrow-rs][7] for the core Arrow functionality, and [arrow-datafusion][8] for DataFusion and Ballista. There's still work to be done on determining the exact release workflows for the latter, but this leaves us in a much better position to meet the broader Rust community's expectations of crate versioning and stability.

## Community Participation
All Apache projects are built on volunteer contribution; it's a core principle of both the ASF and open-source software development more broadly. One point of friction that was observed in the previous workflow for the Rust community in particular was the requirement for issues to be logged in Arrow's Jira project. This step required would-be contributors to first register an account, and then receive a permissions grant to manage tickets.

To streamline this process for new community members, we've taken the decision to migrate to GitHub Issues for tracking both new development work and known bugs that need addressing, and bootstrapped our new repositories by importing their respective tickets from Jira. Creating issues to track non-trivial proposed features and enhancements is still required; this creates an opportunity for community review and helps ensure that feedback is delivered as early in the process as possible. We hope that this strikes a better balance between organization and accessibility for prospective contributors.

## Get Involved
To further improve the onboarding flow for new Arrow contributors, we have started the process of labeling select issues as "good first issue" in [arrow-rs][11] and [arrow-datafusion][12]. These issues are small in scope but still serve as valuable contributions to the project, and help new community members to get familiar with our development workflows and tools.

Not quite sure where to start with a particular issue, or curious about the status of one of our projects? Join the Arrow [mailing lists][13] or the #arrow-rust channel on the [ASF Slack][14] server.

## In Closing
As a final note: nothing here is intended as prescriptive advice. As a community, we've decided that these processes are the best fit for the current status of our projects, but this may change over time! There is, after all, [no silver bullet][10] for software engineering.

[1]: https://arrow.apache.org/committers/
[2]: https://www.apache.org/theapacheway/
[3]: https://doc.rust-lang.org/book/ch07-01-packages-and-crates.html
[4]: https://github.com/apache/arrow-datafusion/datafusion
[5]: https://github.com/apache/arrow-datafusion/ballista
[6]: https://crates.io/
[7]: https://github.com/apache/arrow-rs
[8]: https://github.com/apache/arrow-datafusion
[9]: https://en.wikipedia.org/wiki/Monorepo
[10]: https://en.wikipedia.org/wiki/No_Silver_Bullet
[11]: https://github.com/apache/arrow-rs/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
[12]: https://github.com/apache/arrow-datafusion/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
[13]: https://arrow.apache.org/community
[14]: https://s.apache.org/slack-invite
[15]: https://semver.org/
