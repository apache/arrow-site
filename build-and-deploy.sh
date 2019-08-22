#!/bin/bash
set -ev

if [ "${TRAVIS_BRANCH}" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then

    if [ "${GITHUB_PAT}" = "" ] && [ "${DEPLOY_KEY}" = "" ]; then
        # Don't build because we can't publish
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

    if [ "${TRAVIS_REPO_SLUG}" = "apache/arrow-site" ]; then
        # Production
        TARGET_BRANCH=asf-site
        BASE_URL=
    else
        # On a fork, so we'll deploy to GitHub Pages
        TARGET_BRANCH=gh-pages
        # You could supply an alternate BASE_URL, but that's not necessary
        # because we can infer it based on GitHub Pages conventions
        if [ "${BASE_URL}" = "" ]; then
            BASE_URL=$(echo $TRAVIS_REPO_SLUG | sed -e 's@.*/@/@')
        fi
    fi

    # Build
    JEKYLL_ENV=production bundle exec jekyll build --baseurl="${BASE_URL}"

    # Publish
    if [ "${DEPLOY_KEY}" != "" ]; then
        echo "Setting deploy key"
        # Stick it in "scripts" because Jekyll ignores it
        echo $DEPLOY_KEY > scripts/deploy_key
        # Hack to make the key from the env var have real newlines
        sed -i 's/\\n/\
/g' scripts/deploy_key
        chmod 600 scripts/deploy_key
        eval $(ssh-agent -s)
        ssh-add scripts/deploy_key
        git clone -b ${TARGET_BRANCH} git@github.com:$TRAVIS_REPO_SLUG.git OUTPUT
    else
        echo "Using GitHub PAT"
        git clone -b ${TARGET_BRANCH} https://${GITHUB_PAT}@github.com/$TRAVIS_REPO_SLUG.git OUTPUT
    fi

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
