#!/bin/bash

# =========================================================
# Job Settings (User Settings)
export CFG_BRANCH=fallout # doomsday, master, ...
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
make bg

# Archive: bel_projects/**/wrc.bin, bel_projects/**/wrc.elf, bel_projects/**/burstgen.bin, bel_projects/**/burstgen.elf
