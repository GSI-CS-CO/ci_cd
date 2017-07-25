#!/bin/bash
set -ex

# =============================================================================
# Settings
v_repository=https://github.com/GSI-CS-CO/bel_projects.git;
v_repo_name=bel_projects;
v_webserver_base=/var/www/html/releases/;

# =============================================================================
# Get command line arguments
v_build_target=$1;
v_target_branch=$2;
v_webserver_target=$3;

# =============================================================================
# Check arguments
if [ $# -ne 3 ]; then
  echo "Sorry we need at least 3 parameters..."
  echo "Example: ./build_software.sh <target> <branch> <webserver target>"
  exit 1
fi

# =============================================================================
# Checkout files
if [ -d $v_build_target ]; then
   rm -rf $v_build_target
fi
mkdir $v_build_target
cd $v_build_target
git clone $v_repository $v_repo_name
cd $v_repo_name
git checkout $v_target_branch

# =============================================================================
# Prepare environmet
./fix-git.sh

# =============================================================================
# Start build
if [ -d /tmp/$v_build_target ]; then
  rm -r /tmp/$v_build_target
fi
if [ -f /tmp/$v_build_target.tar.xz ]; then
  rm /tmp/$v_build_target.tar.xz
fi
make $v_build_target
make $v_build_target-install STAGING=/tmp/$v_build_target
cd /tmp
tar cfJ $v_build_target.tar.xz $v_build_target

# =============================================================================
# Copy files to webserver
if [ -f $v_webserver_base$v_webserver_target/$v_build_target.tar.xz ]; then
  rm $v_webserver_base$v_webserver_target/$v_build_target.tar.xz
fi
cp $v_build_target.tar.xz $v_webserver_base$v_webserver_target/
