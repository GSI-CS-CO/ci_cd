#!/bin/bash

# Settings
production_repo="https://github.com/GSI-CS-CO/bel_projects.git"
production_branch="c_release_giga_merge"
development_repo="https://github.com/GSI-CS-CO/saftlib.git"
development_branch="master"

# Create/change to workspace directory
if [ -d workspace ]; then
  mkdir workspace
fi
cd workspace

# Select installation source
case "$1" in
  "production")
    if [ -d bel_projects ]; then
      rm -rf bel_projects
    fi
    git clone $production_repo bel_projects
    cd bel_projects
    git checkout $production_branch
    git submodule init
    git submodule update --recursive
    make
    make saftlib
    sudo make saftlib-install
    ;;
  "development")
    if [ -d saftlib ]; then
      rm -rf saftlib
    fi
    git clone $development_repo saftlib
    cd saftlib
    git clean -xfd .
    git checkout $development_branch
    ./autogen.sh
    ./configure --enable-maintainer-mode --prefix=/usr/local --sysconfdir=/etc
    make clean
    make
    sudo make install
    ;;
  *)
    echo "Please specify the installation source"
    echo "Available sources are:"
    echo "  - production (bel_projects repository (submodule) -> $production_branch)"
    echo "  - development (saftlib repository -> $development_branch)"
    exit 1
    ;;
esac
