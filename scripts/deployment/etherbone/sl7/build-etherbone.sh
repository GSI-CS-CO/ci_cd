#! /bin/bash

BUILD_DIRECTORY="tmp-etherbone"
BEL_BRANCH="vme_driver_test"
DEST_DIRECTORY=`pwd`"/"$BUILD_DIRECTORY
BASE_DIR=`pwd`
JOBS=32
DEPLOY_TARGET="/common/export/etherbone-dev/rc8"

## Create a new checkout
#if [ -d "$BUILD_DIRECTORY" ]; then
#  rm -fr $BUILD_DIRECTORY
#fi
#mkdir $BUILD_DIRECTORY
#cd $BUILD_DIRECTORY
#git clone https://github.com/GSI-CS-CO/bel_projects.git --recursive
#
## Update all submodules and checkout the select branch
#cd bel_projects
#git checkout $BEL_BRANCH
#git submodule init
#git submodule update --recursive
#
## Build all tools
#make -j $JOBS tools
## TBD: copy tools
#
## Build etherbone
#cd ip_cores/etherbone-core/api
#git clean -xfd .
#./autogen.sh
#export PKG_CONFIG_PATH=/common/usr/timing/root/lib/pkgconfig
#./configure --prefix=""
#make -j $JOBS DESTDIR=$DEST_DIRECTORY/etherbone/x86_64 install
#make -j $JOBS DESTDIR=$DEST_DIRECTORY/etherbone/i386 EXTRA_FLAGS="-m32" install
#cd ../../..
#
## Build all tools and copy them
#cd tools
#make -j $JOBS
#for i in flash console info sflash time; do
#  cp eb-$i $DEST_DIRECTORY/etherbone/x86_64/bin
#done
#make -j $JOBS EXTRA_FLAGS="-m32"
#for i in flash console info sflash time; do
#  cp eb-$i $DEST_DIRECTORY/etherbone/i386/bin
#done
#cd ..

## Update submodules bel_projects
#cd $DEST_DIRECTORY/bel_projects/ip_cores/fpga-config-space
#git submodule init
#git submodule update --recursive
#cd legacy-vme64x-core
#git submodule init
#git submodule update --recursive
cd $DEST_DIRECTORY/

# Build kernel drivers
#wget http://packages.acc.gsi.de/opkg/el7/x86_64/linux-scu-source_3.10.101-01_x86_64.opk
#opkg-util unpack linux-scu-source_3.10.101-01_x86_64.opk

#Download socat
yumdownloader socat 
cd $DEST_DIRECTORY/etherbone/x86_64
rpm2cpio $DEST_DIRECTORY/socat-1.7.2.2-5.el7.x86_64.rpm | cpio -idmv;

cd $DEST_DIRECTORY
# Build sources and install
targets="driver@"

# Build 64bit and 32bit
export KERNELDIR=`pwd`/linux-scu-source-3.10.101-01
#make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/x86_64 VME_SOURCE=external distclean ${targets//@/}
#make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/x86_64 VME_SOURCE=external ${targets//@/-install}
#make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/i386 VME_SOURCE=external EXTRA_FLAGS="-m32" distclean ${targets//@/}
#make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/i386 VME_SOURCE=external EXTRA_FLAGS="-m32" ${targets//@/-install}

make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/x86_64 VME_SOURCE=external distclean driver
make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/x86_64 VME_SOURCE=external driver
make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/x86_64 VME_SOURCE=external driver-install

make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/i386 VME_SOURCE=external EXTRA_FLAGS="-m32" distclean driver
make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/i386 VME_SOURCE=external EXTRA_FLAGS="-m32" driver
make -C bel_projects PREFIX="" STAGING=`pwd`/etherbone/i386 VME_SOURCE=external EXTRA_FLAGS="-m32" driver-install

rm -rf $DEPLOY_TARGET/x86_64
rm -rf $DEPLOY_TARGET/i386
rm $DEPLOY_TARGET/i686

cp -r etherbone/x86_64 $DEPLOY_TARGET/x86_64
cp -r etherbone/i386 $DEPLOY_TARGET/i386
cd $DEPLOY_TARGET
ln -s i386 i686
cd $BASE_DIR
#ATENTION Compile and copy tools
cp etherbone-dev.sh $DEPLOY_TARGET
