<!---
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
-->

# Apache Arrow Website

## Overview

[Jekyll](https://jekyllrb.com/) is used to generate HTML files from the
Markdown + templates in this repository. The built version of the site is kept
on the `asf-site` branch, which gets deployed to https://arrow.apache.org.

## Adding Content

To add a blog post, create a new markdown file in the `_posts` directory,
following the model of existing posts. In the front matter, you should specify
an "author". This should be your Apache ID if you have one, or it can just be
your name. To add additional metadata about yourself (GitHub ID, website), add
yourself to `_data/contributors.yml`. This object is keyed by `apacheId`, so
use that as the `author` in your post. (It doesn't matter if the ID actually
exists in the ASF; all metadata is local to this project.)

## Prerequisites

With a recent version of [Ruby](https://www.ruby-lang.org/) (i.e. one that does not have
an [End-Of-Life (EOL) status](https://www.ruby-lang.org/en/downloads/branches/)) installed,
run the following commands to install [Jekyll](https://jekyllrb.com/).

```shell
gem install bundler
bundle install
```

We also need [Node.JS](https://nodejs.org/) to use
[webpack](https://webpack.js.org/) for maintaining dependent
JavaScript and CSS libraries.

We can install webpack and dependent JavaScript and CSS libraries
automatically by following command lines to preview or build the site. So
we just need to install Node.JS here.

## Previewing the site

Run the following and open http://localhost:4000/ to preview generated
site locally:

```shell
bundle exec rake
```

## Deployment

### apache/arrow-site

On a commit to the `main` branch of `apache/arrow-site`, the rendered
static site will be published to the `asf-site` branch using GitHub
Actions.

### Forks

When implementing changes to the website on a fork, the GitHub Actions
workflow behaves differently.

On a commit to all branches, the rendered static site will be
published to GitHub Pages using GitHub Actions. The latest commit is
only visible because all publications use the same output location:
https://${YOUR_GITHUB_ACCOUNT}.github.io/arrow-site/

You need to configure your fork repository to use this feature:

1. Enable GitHub Pages on your fork:
   1. Open https://github.com/${YOUR_GITHUB_ACCOUNT}/arrow-site/settings/pages
   2. Select "GitHub Actions" as "Source"
2. Accept publishing GitHub Pages from all branches on your fork:
   1. Open https://github.com/${YOUR_GITHUB_ACCOUNT}/arrow-site/settings/environments
   2. Select the "github-pages" environment
   3. Change the default "Deployment branches and tags" rule:
      1. Press the "Edit" button
      2. Change the "Name pattern" to `*` from `main` or `gh-pages`

See also the [GitHub Pages documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow).

FYI: We can also generate the site for https://arrow.apache.org/
to `_site/` locally by the following command line:

```shell
JEKYLL_ENV=production bundle exec rake generate
```

## Using Docker Compose

If you don't wish to change or install `ruby` and `nodejs` locally,
you can use Docker Compose to build and preview the site with a command like:

```shell
docker compose up
```

Then open http://localhost:4000 locally.
