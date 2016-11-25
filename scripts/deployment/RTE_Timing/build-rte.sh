#! /bin/bash
#PLEASE ADJUST THIS SCRIPT FOR YOUR NEED
BEL_BRANCH="balloon"
#Targets for the TG: R8-balloon_0 RC8-balloon_0 tg-dev tg-testing
#For the rest of the Groups, you can create one for your need
DEPLOY_TARGET="/dev/null"

# FROM HERE ON, IF YOU WANT TO MODIFY SOMETHING
# YOU'RE ON YOUR OWN. MAY THE FORCE BE WITH YOU
BASE_DIR=`pwd`
BUILD_DIR="rte-build"
BEL_PROJECTS="bel_projects"
RTE_DIR=`pwd`"/"$BUILD_DIR
TMP_DIR=`pwd`"/rte-tmp"
ROOT_DIR=`pwd`"/rte-root"
LINUX_KERNEL="linux-scu-source-3.10.101-01"
KERNEL="linux-scu-source_3.10.101-01"
JOBS=32
ARCH=x86_64

#logging
LOG_FILE="RTE_log"_$(date '+%d-%m-%Y_%H-%M-%S')
echo $LOG_FILE
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$LOG_FILE 2>&1

# Clean up installation folders
#rm -rf $ROOT_DIR $RTE_DIR $TMP_DIR
rm -rf $ROOT_DIR $RTE_DIR
mkdir $ROOT_DIR 
mkdir $RTE_DIR

# Get the building files
if [ ! -d "$TMP_DIR" ]; then
  mkdir $TMP_DIR
fi

cd $TMP_DIR
# Get bel_projects
if [ ! -d "$BEL_PROJECTS" ]; then
#git clone https://github.com/GSI-CS-CO/bel_projects.git --recursive #TO BE CHECK WHAT IT IS THE BEST OPTION
  git clone https://github.com/GSI-CS-CO/bel_projects.git
fi

cd $BEL_PROJECTS
git clean -xfd .
git fetch --all
git checkout $BEL_BRANCH
git pull origin $BEL_BRANCH
git submodule init
git submodule update --recursive

cd $TMP_DIR
# Get the kernel
if [ ! -d "$LINUX_KERNEL" ]; then
  wget http://packages.acc.gsi.de/opkg/el7/x86_64/"$KERNEL"_x86_64.opk
  opkg-util unpack "$KERNEL"_x86_64.opk
  rm "$KERNEL"_x86_64.opk
fi

export KERNELDIR=`pwd`/linux-scu-source-3.10.101-01

# Build etherbone 
cd $TMP_DIR/$BEL_PROJECTS/ip_cores/etherbone-core/api
# Build for the root environment
git clean -xfd .
./autogen.sh
export PKG_CONFIG_PATH=$ROOT_DIR/lib/pkgconfig
./configure --prefix=$ROOT_DIR
#make -j $JOBS DESTDIR=$ROOT_DIR install
make -j $JOBS install

# Build etherbone for RTE
git clean -xfd .
./autogen.sh
export PKG_CONFIG_PATH=$RTE_DIR/lib/pkgconfig
./configure --prefix=""
make -j $JOBS DESTDIR=$RTE_DIR install

# Build all tools and copy them
cd $TMP_DIR/$BEL_PROJECTS
make tlu DESTDIR=$RTE_DIR EXTRA_FLAGS=-I"$RTE_DIR/lib/" EB=$TMP_DIR/$BEL_PROJECTS/ip_cores/etherbone-core/api
make eca DESTDIR=$RTE_DIR EXTRA_FLAGS=-I"$RTE_DIR/lib/" EB=$TMP_DIR/$BEL_PROJECTS/ip_cores/etherbone-core/api

cd $TMP_DIR/$BEL_PROJECTS/tools
make -j $JOBS
for i in flash console info sflash time; do
  cp eb-$i $RTE_DIR/bin
done
cp monitoring/wr-mon $RTE_DIR/bin

# Build drivers
cd $TMP_DIR
make -C bel_projects PREFIX="" STAGING=$RTE_DIR VME_SOURCE=external distclean driver
make -C bel_projects PREFIX="" STAGING=$RTE_DIR VME_SOURCE=external driver
make -C bel_projects PREFIX="" STAGING=$RTE_DIR VME_SOURCE=external driver-install

# Saftlib
yumdownloader --destdir $TMP_DIR/rpm glibmm24-devel.$ARCH glibmm24.$ARCH libsigc++20-devel.$ARCH libsigc++20.$ARCH

# Extract all rpms
cd $ROOT_DIR 
for i in $TMP_DIR/rpm/*; do rpm2cpio "$i" | cpio -idmv; done

#cp $BASE_DIR/pkgconfig/* $ROOT_DIR/usr/lib64/pkgconfig
#patch the pkgconfig with a right prefix path
sed -i 1,1d $ROOT_DIR/usr/lib64/pkgconfig/*
sed -i "1i prefix=$ROOT_DIR" $ROOT_DIR/usr/lib64/pkgconfig/*

#building saftlib
export ROOT_DIR
export PKG_CONFIG_PATH=$ROOT_DIR/lib/pkgconfig:$ROOT_DIR/usr/lib64/pkgconfig

cd $TMP_DIR/$BEL_PROJECTS/ip_cores/saftlib
git clean -xfd .
./autogen.sh
./configure --prefix="" --sysconfdir=/etc
make -j $JOBS DESTDIR=$RTE_DIR install

# installing dependencies for the saftlib RTE
yumdownloader --destdir $TMP_DIR/rpm glib2.$ARCH dbus libselinux.$ARCH libcap-ng.$ARCH audit-libs.$ARCH expat.$ARCH dbus-devel.$ARCH dbus-glib.$ARCH dbus-glib-devel.$ARCH dbus-libs.$ARCH libffi.$ARCH pcre.$ARCH xz-libs.$ARCH 

#installing socat & dependencies
yumdownloader --destdir $TMP_DIR/rpm socat openssl-libs.$ARCH readline.$ARCH openssl-libs.$ARCH ncurses-libs.$ARCH libcom_err.$ARCH keyutils-libs.$ARCH krb5-libs-1.13.2-12.el7_2.$ARCH

## Extract all rpms
cd $RTE_DIR
for i in $TMP_DIR/rpm/*.rpm; do rpm2cpio "$i" | cpio -idmv; done

# Deployment
rm -rf $DEPLOY_TARGET/*
mkdir $DEPLOY_TARGET/$ARCH
cp -r $RTE_DIR/* $DEPLOY_TARGET/$ARCH

#run init script
cp $BASE_DIR/timing-rte.sh $DEPLOY_TARGET
