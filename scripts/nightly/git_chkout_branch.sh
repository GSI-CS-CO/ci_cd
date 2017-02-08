#!/bin/bash

export NEW_BRANCH=${GIT_BRANCH#*/}

git checkout $NEW_BRANCH
echo $NEW_BRANCH
git pull
