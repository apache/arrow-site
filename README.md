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
markdown + templates in this repository. The built version of the site is kept
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

With Ruby >= 2.1 installed, run the following commands to install
[Jekyll](https://jekyllrb.com/).

```shell
gem install jekyll bundler
bundle install
```

On some platforms, the Ruby `nokogiri` library may fail to build, in
such cases the following configuration option may help:

```
bundle config build.nokogiri --use-system-libraries
```


`nokogiri` depends on the `libxml2` and `libxslt1` libraries, which can be
installed on Debian-like systems with

```
apt-get install libxml2-dev libxslt1-dev
```

## Previewing the site

Run the following to generate HTML files and run the web site locally.

```
bundle exec jekyll serve
```

## Automatic deployment

If you're working on a fork of `apache/arrow-site`, you can get a development
version of the site built off of your `master` branch published using GitHub
Pages and Travis-CI. There are a couple of quick steps to enable this:

1. Create a `gh-pages` branch on your fork, based on the `asf-site` branch
(`git checkout asf-site && git checkout -b gh-pages && git push origin gh-pages`)
2. In the settings for your fork (https://github.com/$YOU/arrow-site/settings),
turn on GitHub Pages and set it to the gh-pages branch
3. Go to https://travis-ci.org/account/repositories and enable Travis builds on
your fork
4. Set up an auth token or deploy key:

### With a personal access token:

A GitHub personal access token takes the least effort to set up, but its scope
is broader (all public repositories you have access to), so some may be worried
about setting one in Travis (even though Travis encrypts them).

1. Go to https://github.com/settings/tokens and create a GitHub personal access
token with `public_repo` scope
2. In the settings in Travis for your fork
(https://travis-ci.org/$YOU/arrow-site/settings), add an environment variable
called GITHUB_PAT, using the token you just created. To keep the token value
secret, **do not toggle on "Display value in build log"** (i.e. the default is
secret).

### With a deploy key

GitHub deploy keys are tied to a repository, so they have much narrower scope
and aren't connected to an individual contributor, but they take a little more
work to set up.

1. On your computer, do `ssh-keygen -t rsa -b 4096 -f 'github_deploy_key' -N ''`
2. Go to https://github.com/$YOU/arrow-site/settings/keys and put the public
key there (found in `github_deploy_key.pub`). Check the box to give the token
write access.
3. In the settings in Travis for your fork
(https://travis-ci.org/$YOU/arrow-site/settings), add an environment variable
called DEPLOY_KEY. This takes the contents of the private key file you just
made (`github_deploy_key`), but you have to preprocess it to escape whitespace.
Replace the spaces ` ` in the first and last lines with `\ ` (i.e. the first
line becomes `-----BEGIN\ OPENSSH\ PRIVATE\ KEY-----`), and replace the
newlines with `\\n`. The result should be a very long string on a single line.
To keep this ssh key value secret, **do not toggle on "Display value in build
log"** (i.e. the default is secret).

After doing this, commits to the master branch of your fork will be
automatically built and published to https://$YOU.github.io/arrow-site/. This
can help Arrow committers preview your changes more easily before accepting
patches.

## Publishing

Publishing the site happens automatically on commits to the `master` branch on
`apache/arrow-site`. Alternatively, to build and publish locally, clone the
`arrow-site` repository again as a subdirectory:

```shell
git clone --branch=asf-site https://github.com/apache/arrow-site.git asf-site
```

To build and copy the contents of the built site to that second clone,

```shell
JEKYLL_ENV=production bundle exec jekyll build
rsync -r build/ asf-site/
cd asf-site
git status
```

Now `git add` any new files, then commit everything, and push:

```
git push
```

### Updating Code Documentation

To update the documentation, you can run the script `./dev/gen_apidocs.sh` in
the `apache/arrow` repository. This script will run the code documentation
tools in a fixed environment.

#### C (GLib)

First, build Apache Arrow C++ and Apache Arrow GLib. This assumes that you have checkouts your forks of `arrow` and `arrow-site` alongside each other in your file system.

```
mkdir -p ../cpp/build
cd ../cpp/build
cmake .. -DCMAKE_BUILD_TYPE=debug
make
cd ../../c_glib
./autogen.sh
./configure \
  --with-arrow-cpp-build-dir=$PWD/../cpp/build \
  --with-arrow-cpp-build-type=debug \
  --enable-gtk-doc
LD_LIBRARY_PATH=$PWD/../cpp/build/debug make GTK_DOC_V_XREF=": "
rsync -r doc/reference/html/ ../../arrow-site/asf-site/docs/c_glib/
```

#### Javascript

```
cd ../js
npm run doc
rsync -r doc/ ../../arrow-site/asf-site/docs/js
```

Then add/commit/push from the `asf-site/` git checkout.
