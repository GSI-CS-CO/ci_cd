#!/bin/bash
#===========================================================
# Initialize all GIT repositories

git submodule init
git submodule update --recursive
cd submodules/bel_projects
git checkout proposed_master
git submodule init
git submodule update --recursive
