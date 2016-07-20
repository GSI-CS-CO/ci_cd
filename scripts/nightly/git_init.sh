#!/bin/bash

git submodule init
git submodule update --recursive
git config --global user.name "Jenkins Nightly Build"
git config --global user.email "csco-tg@gsi.de"
