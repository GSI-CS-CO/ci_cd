#!/bin/bash

# =========================================================
# Job Settings (User Settings)
export BRANCH="master"

# =========================================================
# Build Steps (Don't Edit This Area!)
# Clone Repository
git clone https://github.com/GSI-CS-CO/ci_cd.git

# Edit Branch Settings
cd ci_cd/scripts/deployment/RTE_Timing
sed -i -e 's/BEL_BRANCH=\"\"/BEL_BRANCH=\"'$BRANCH'\"/g' build-rte.sh

# Build
./build-rte.sh

# Plausibility Check
cd rte-build
test `find . -name saftd`
test `find . -name eb-console`
test `find . -name pcie_wb.ko`
test `find . -name wishbone-serial.ko`
test `find . -name wishbone.ko`
test `find . -name vme_wb.ko`

# Build TAR File
cd ..
tar -cvf timing-rte.tar rte-build
