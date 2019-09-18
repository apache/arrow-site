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

## Deployment

On commits to the `master` branch of `apache/arrow-site`, the rendered static site will be published to the `asf-site` branch using GitHub Actions. On a fork, it will deploy to your `gh-pages` branch for deployment via GitHub Pages; this is useful for previewing changes you're proposing. To enable this deployment on your fork, you'll need to sign up for GitHub Actions [here](https://github.com/features/actions/signup).

## Updating Code Documentation

To update the documentation, you can run the script `./dev/gen_apidocs.sh` in
the `apache/arrow` repository. This script will run the code documentation
tools in a fixed environment.

### C (GLib)

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

### JavaScript

```
cd ../js
npm run doc
rsync -r doc/ ../../arrow-site/asf-site/docs/js
```

Then add/commit/push from the `asf-site/` git checkout.
