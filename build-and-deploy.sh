#!/bin/bash
set -ev

UPSTREAM="apache/arrow-site"
# GITHUB_TOKEN set in .travis.yml, encrypted
# `hub` installed outside of this script, requires token called GITHUB_TOKEN with repo scope

if [ "${TRAVIS_BRANCH}" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then

    if [ "${GITHUB_PAT}" = "" ] && [ "${DEPLOY_KEY}" = "" ] && [ "${TRAVIS_REPO_SLUG}" != "${UPSTREAM}" ]; then
        # Don't build test site because we can't publish
        echo "To publish the site, you must set a GITHUB_PAT or DEPLOY_KEY at"
        echo "https://travis-ci.org/${TRAVIS_REPO_SLUG}/settings"
        exit 1
    fi

    # Set git config so that the author of the deployed site commit is the same
    # as the author of the commit we're building
    AUTHOR_EMAIL=$(git log -1 --pretty=format:%ae)
    AUTHOR_NAME=$(git log -1 --pretty=format:%an)
    git config --global user.email "${AUTHOR_EMAIL}"
    git config --global user.name "${AUTHOR_NAME}"
    COMMIT_MESSAGE=$(git log -1 --pretty=format:%s)

    if [ "${TRAVIS_REPO_SLUG}" = "${UPSTREAM}" ]; then
        # Production
        TARGET_BRANCH=asf-site
        BASE_URL=
        GITHUB_PAT=$GITHUB_TOKEN
        # We're going to push to this and make a PR back to $UPSTREAM
        DESTINATION_REPO="ursa-labs/arrow-site"
    else
        # On a fork, so we'll deploy to GitHub Pages
        TARGET_BRANCH=gh-pages
        # You could supply an alternate BASE_URL, but that's not necessary
        # because we can infer it based on GitHub Pages conventions
        if [ "${BASE_URL}" = "" ]; then
            BASE_URL=$(echo $TRAVIS_REPO_SLUG | sed -e 's@.*/@/@')
        fi
        # We're going to push to a branch in the same repo
        DESTINATION_REPO=$TRAVIS_REPO_SLUG
    fi

    # Build
    JEKYLL_ENV=production bundle exec jekyll build --baseurl="${BASE_URL}"

    # Publish
    if [ "${DEPLOY_KEY}" != "" ]; then
        echo "Setting deploy key"
        eval $(ssh-agent -s)
        # Hack to make the key from the env var have real newlines
        echo "${DEPLOY_KEY}" | sed -e 's/\\n/\n/g' | ssh-add -
        git clone -b ${TARGET_BRANCH} git@github.com:$DESTINATION_REPO.git OUTPUT
    else
        echo "Using GitHub PAT"
        git clone -b ${TARGET_BRANCH} https://${GITHUB_PAT}@github.com/$DESTINATION_REPO.git OUTPUT
    fi

    rsync -a --delete --exclude '/.git/' --exclude '/docs/' build/ OUTPUT/
    cd OUTPUT

    if [ "$(git status --porcelain)" != "" ]; then
        # There are changes to the built site
        git add .
        git commit -m "Build ${COMMIT_MESSAGE}"
        git push origin ${TARGET_BRANCH}
        if [ "${TRAVIS_REPO_SLUG}" = "${UPSTREAM}" ]; then
            UPSTREAM_ORG=$(echo $UPSTREAM | sed -e 's@/.*@@')
            hub pull-request -b ${UPSTREAM_ORG}:asf-site -m "Publish ${COMMIT_MESSAGE}"
        fi
    else
        echo "No changes to the built site"
    fi
fi
