#!/bin/bash
set -ev

if [ "${TRAVIS_BRANCH}" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then

    if [ -z "${GITHUB_PAT}" ]; then
        # Don't build because we can't publish
        echo "To publish the site, you must set a GITHUB_PAT at"
        echo "https://travis-ci.org/"${TRAVIS_REPO_SLUG}"/settings"
        exit 1
    fi

    # Set git config so that the author of the deployed site commit is the same
    # as the author of the commit we're building
    export AUTHOR_EMAIL=$(git log -1 --pretty=format:%ae)
    export AUTHOR_NAME=$(git log -1 --pretty=format:%an)
    git config --global user.email "${AUTHOR_EMAIL}"
    git config --global user.name "${AUTHOR_NAME}"

    if [ "${TRAVIS_REPO_SLUG}" = "apache/arrow-site" ]; then
        # Production
        export TARGET_BRANCH=asf-site
        export BASE_URL=https://arrow.apache.org
    else
        # On a fork, so we'll deploy to GitHub Pages
        export TARGET_BRANCH=gh-pages
        # You could supply an alternate BASE_URL, but that's not necessary
        # because we can infer it based on GitHub Pages conventions
        if [ -z "${BASE_URL}" ]; then
            export BASE_URL="https://"$(echo $TRAVIS_REPO_SLUG | sed 's@/@.github.io/@')
        fi
    fi
    # Set the site.baseurl
    perl -pe 's@^baseurl.*@baseurl: '"${BASE_URL}"'@' -i _config.yml

    # Build
    gem install jekyll bundler
    bundle install
    JEKYLL_ENV=production bundle exec jekyll build

    # Publish
    git clone -b ${TARGET_BRANCH} https://${GITHUB_PAT}@github.com/$TRAVIS_REPO_SLUG.git OUTPUT
    rsync -r build/ OUTPUT/
    cd OUTPUT

    git add .
    # Use `|| true` after these commands so that the build doesn't fail if
    # there are no changes to the published site (e.g. when editing the README)
    git commit -m "Updating built site (build ${TRAVIS_BUILD_NUMBER})" || true
    git push origin ${TARGET_BRANCH} || true
fi
