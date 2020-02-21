#!/bin/bash

# =========================================================
# Job Settings (User Settings)
export CFG_QUARTUS_VERSION=16 # 16 or 18
export CFG_BRANCH=doomsday # doomsday, master, ...
export CFG_TARGET=scu2 # scu2, scu3, vetar2a, vetar2a-ee-butis, exploder5, pexarria5, microtca, pmc
export GSI_BUILD_TYPE="Doomsday-v4.X.Y" # release name

# =========================================================
# Environmental Settings (Don't Edit This Area!)
export QSYS_ROOTDIR=/opt/quartus/$CFG_QUARTUS_VERSION/quartus/sopc_builder/bin
export QUARTUS_ROOTDIR=/opt/quartus/$CFG_QUARTUS_VERSION/quartus
export QUARTUS=$QUARTUS_ROOTDIR
export QUARTUS_64BIT=1
export PATH=$PATH:$QUARTUS
export PATH=$PATH:$QSYS_ROOTDIR
export CHECKOUT_NAME=bel_projects

# =========================================================
# Build Steps (Don't Edit This Area!)
git clone https://github.com/GSI-CS-CO/bel_projects.git
cd bel_projects
git checkout $CFG_BRANCH
./autogen.sh
make
make $CFG_TARGET-clean
make $CFG_TARGET
make $CFG_TARGET-check
