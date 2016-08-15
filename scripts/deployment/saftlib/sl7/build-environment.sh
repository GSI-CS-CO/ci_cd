#! /bin/bash

BUILD_ENVIRONMENT="root"
LIBS_DIRECTORY=$BUILD_ENVIRONMENT/"build"
BEL_BRANCH="proposed_master"
BASE_DIR=`pwd`
JOBS=32
ARCH=x86_64

rm -rf $BUILD_ENVIRONMENT
mkdir $BUILD_ENVIRONMENT
cd $BUILD_ENVIRONMENT
mkdir tmp

#download the files and projects
#git clone https://github.com/GSI-CS-CO/bel_projects.git tmp/bel_projects --recursive 
git clone git://ohwr.org/hdl-core-lib/etherbone-core.git tmp/etherbone
yumdownloader --destdir tmp glibmm24-devel.$ARCH glibmm24.$ARCH lib dbus glib2-devel.$ARCH libselinux.$ARCH libcap-ng.$ARCH audit-libs.$ARCH expat.$ARCH libsigc++20-devel.$ARCH 

# Extract all rpms
for i in tmp/*
do 
	rpm2cpio "$i" | cpio -idmv; 
done

cd tmp/bel_projects
git checkout $BEL_BRANCH
git submodule init
git submodule update --recursive

# Build all tools
make -j $JOBS tools

# Get into Etherbone
cd ip_cores/etherbone-core/api

#Clean it
git clean -xfd

#Compile Etherbone
./autogen.sh
export PKG_CONFIG_PATH=$BASE_DIR/$BUILD_ENVIRONMENT/usr/lib64/pkgconfig/
./configure --prefix=""
make -j $JOBS DESTDIR=$BASE_DIR/$BUILD_ENVIRONMENT install

# Remove unwanted ko files
find . -name *.ko -exec rm -rf {} \;

#clean up installations files
cd $BASE_DIR/$BUILD_ENVIRONMENT 
rm -rf tmp
