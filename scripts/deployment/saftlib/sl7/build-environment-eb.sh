#! /bin/bash

BUILD_ENVIRONMENT="env"
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
git clone git://ohwr.org/hdl-core-lib/etherbone-core.git tmp/etherbone

#yumdownloader --destdir tmp glibmm24-devel.$ARCH glibmm24.$ARCH lib dbus glib2.$ARCH glib2-devel.$ARCH libselinux.$ARCH libcap-ng.$ARCH audit-libs.$ARCH expat.$ARCH libsigc++20-devel.$ARCH  libsigc++20.$ARCH  

#yumdownloader --destdir tmp glibmm24-devel.$ARCH glibmm24.$ARCH glib2.$ARC glib2-devel.$ARCH libselinux.$ARCH libcap-ng.$ARCH audit-libs.$ARCH expat.$ARCH libsigc++20-devel.$ARCH libsigc++20.$ARCH

yumdownloader --destdir tmp glibmm24-devel.$ARCH glibmm24.$ARCH libsigc++20-devel.$ARCH libsigc++20.$ARCH

# Extract all rpms
for i in tmp/*
do 
	rpm2cpio "$i" | cpio -idmv; 
done

cd tmp/etherbone
git checkout $BEL_BRANCH

# Get into Etherbone API
cd api

#Clean it
git clean -xfd

#Compile Etherbone
./autogen.sh
export PKG_CONFIG_PATH=$BASE_DIR/$BUILD_ENVIRONMENT/lib/pkgconfig/
./configure --prefix="$BASE_DIR/$BUILD_ENVIRONMENT"
make -j $JOBS install

# Remove unwanted ko files
find . -name *.ko -exec rm -rf {} \;

#clean up installations files
cd $BASE_DIR/$BUILD_ENVIRONMENT 
rm -rf tmp
