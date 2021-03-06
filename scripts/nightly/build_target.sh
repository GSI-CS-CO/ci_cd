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
v_build_type=$4

# =============================================================================
# Check arguments
if [ $# -ne 4 ]; then
  echo "Sorry we need at least 3 parameters..."
  echo "Example: ./build_target.sh <target> <branch> <webserver target> <build type>"
  exit 1
fi

# =============================================================================
# Prepare environmet
source quartus16.sh
./git_init.sh

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
# Start build
./fix-git.sh
./install-hdlmake.sh
export GSI_BUILD_TYPE=$v_build_type
make $v_build_target

# =============================================================================
# Copy files to webserver
cp `find . -name *.rpd` $v_webserver_base$v_webserver_target/$v_build_target.rpd
cp `find . -name *.sof` $v_webserver_base$v_webserver_target/$v_build_target.sof
cp `find . -name *.jic` $v_webserver_base$v_webserver_target/$v_build_target.jic
