#!/bin/bash

set -e

REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo '## Setting initial git global configurations'
git config --global --add safe.directory /github/workspace

echo "## Initializing git repo..."
git init
echo "### Adding git remote..."
git remote add origin https://x-access-token:$GITHUB_TOKEN@github.com/$REPO_FULLNAME.git
echo "### Getting branch"
BRANCH=${GITHUB_REF#*refs/heads/}
echo "### git fetch $BRANCH ..."
git fetch origin $BRANCH
echo "### Branch: $BRANCH (ref: $GITHUB_REF )"
git checkout $BRANCH

echo "## Login into git..."
git config --global user.email "formatter@1337z.ninja"
git config --global user.name "Node Code Formatter"

echo "## Ignore workflow files (we may not touch them)"
git update-index --assume-unchanged .github/workflows/*

echo "## Your environment is not ready yet. Installing modules..."
if [ -f yarn.lock ]; then
    echo "## Detected yarn as package manager"
    yarn --non-interactive --silent --ignore-scripts --ignore-engines --production=false
    yarn config set ignore-engines true
    echo "## Installing dependencies..."
    yarn install
    echo "## Formatting code..."
    yarn run format --if-present
    echo "## Linting code..."
    yarn run lint --if-present
else
    echo "## Detected NPM as package manager"
    echo "## Setting environment variables..."
    NODE_ENV=development
    echo "## Installing dependencies..."
    npm ci
    echo "## Formatting code..."
    npm run format --if-present
    echo "## Linting code..."
    npm run lint --if-present
fi

echo "## Deleting node_modules..."
rm -rf node_modules/
echo "## Staging changes..."
git add .
echo "## Commiting files..."
git commit -m "Formatted code" || true
echo "## Pushing to $BRANCH"
git push -u origin $BRANCH
