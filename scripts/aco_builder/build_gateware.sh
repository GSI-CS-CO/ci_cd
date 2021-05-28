#!/bin/bash

# =========================================================
# Job Settings (User Settings)
export CFG_QUARTUS_VERSION=18 # 16 or 18
export CFG_BRANCH=fallout # doomsday, master, ...
export CFG_TARGET=$gateware # scu2, scu3, vetar2a, vetar2a-ee-butis, exploder5, pexarria5, microtca, pmc
export GSI_BUILD_TYPE="fallout-v6.0.1" # release name

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
if [ -d "$CHECKOUT_NAME" ]; then
  rm -rf $CHECKOUT_NAME
fi
git clone https://github.com/GSI-CS-CO/bel_projects.git
cd $CHECKOUT_NAME
git checkout $CFG_BRANCH
make
make $CFG_TARGET
make $CFG_TARGET-check

# Archive: bel_projects/syn/**/*.rpd, bel_projects/syn/**/*.sof, bel_projects/syn/**/*.jic, bel_projects/syn/**/*.rpt
