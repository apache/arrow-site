#!/bin/bash
set -ev

if [ "${TRAVIS_BRANCH}" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then

    if [ -z "${GITHUB_PAT}" ]; then
        # Don't build because we can't publish
        echo "To publish the site, you must set a GITHUB_PAT at"
        echo "https://travis-ci.org/${TRAVIS_REPO_SLUG}/settings"
        exit 1
    fi

    # Set git config so that the author of the deployed site commit is the same
    # as the author of the commit we're building
    AUTHOR_EMAIL=$(git log -1 --pretty=format:%ae)
    AUTHOR_NAME=$(git log -1 --pretty=format:%an)
    git config --global user.email "${AUTHOR_EMAIL}"
    git config --global user.name "${AUTHOR_NAME}"

    if [ "${TRAVIS_REPO_SLUG}" = "apache/arrow-site" ]; then
        # Production
        TARGET_BRANCH=asf-site
        BASE_URL=
    else
        # On a fork, so we'll deploy to GitHub Pages
        TARGET_BRANCH=gh-pages
        # You could supply an alternate BASE_URL, but that's not necessary
        # because we can infer it based on GitHub Pages conventions
        if [ -z "${BASE_URL}" ]; then
            BASE_URL=$(echo $TRAVIS_REPO_SLUG | sed -e 's@.*/@/@')
        fi
    fi

    # Build
    JEKYLL_ENV=production bundle exec jekyll build --baseurl="${BASE_URL}"

    # Publish
    git clone -b ${TARGET_BRANCH} https://${GITHUB_PAT}@github.com/$TRAVIS_REPO_SLUG.git OUTPUT
    rsync -a --delete --exclude '/.git/' --exclude '/docs/' build/ OUTPUT/
    cd OUTPUT

    if [ "$(git status --porcelain)" != "" ]; then
        # There are changes to the built site
        git add .
        git commit -m "Updating built site (build ${TRAVIS_BUILD_NUMBER})"
        git push origin ${TARGET_BRANCH}
    else
        echo "No changes to the built site"
    fi
fi
