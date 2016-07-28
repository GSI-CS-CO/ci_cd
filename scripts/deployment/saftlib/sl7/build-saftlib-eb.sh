#! /bin/bash
BASE_DIR=`pwd`
ENV_DIR=$BASE_DIR/"env"
BUILD_DIRECTORY="saftlib-build"
SAFTLIB_BRANCH="master"
DEST_DIRECTORY=`pwd`"/"$BUILD_DIRECTORY
JOBS=32
DEPLOY_TARGET="/common/export/saftlib-dev/rc8"
SYSROOT=$ENV_DIR

# Create a new checkout
if [ -d "$BUILD_DIRECTORY" ]; then
  rm -fr $BUILD_DIRECTORY
fi
mkdir $BUILD_DIRECTORY
mkdir $BUILD_DIRECTORY/tmp
cd $BUILD_DIRECTORY

git clone https://github.com/GSI-CS-CO/saftlib.git tmp/saftlib

# Update all submodules and checkout the select branch
cd tmp/saftlib
git checkout $SAFTLIB_BRANCH
#git checkout 3edce2751bf0d217f95cb9403739d1f00b28bcf4

# Build saftlib
git clean -xfd .
./autogen.sh

export PKG_CONFIG_PATH=$ENV_DIR/lib/pkgconfig:$ENV_DIR/usr/lib64/pkgconfig
#export PKG_CONFIG_LIBDIR=${SYSROOT}/lib/pkgconfig:${SYSROOT}/usr/lib64/pkgconfig
#export PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
#pkg-config "$@"

./configure --prefix="" --sysconfdir=/etc

#CFLAGS="-I$ENV_DIR/usr"
#./configure --prefix="" --sysconfdir=/etc \
#./configure --prefix="" --with-sysroot=$ENV_DIR 

make -j $JOBS DESTDIR=$DEST_DIRECTORY install
#make -j $JOBS install

cd ../../

## Get stuff we depent on
#if [ -d "$LIBS_DIRECTORY" ]; then
#  rm -fr $LIBS_DIRECTORY
#fi
#mkdir $LIBS_DIRECTORY
#cd $LIBS_DIRECTORY
#
## set ARCH and download our stuff
ARCH=x86_64
#yumdownloader --destdir tmp glibmm24.$ARCH glibmm24-devel.$ARCH dbus glib2.$ARCH glib2-devel.$ARCH libselinux.$ARCH libcap-ng.$ARCH audit-libs.$ARCH expat.$ARCH libsigc++20.$ARCH libffi.$ARCH pcre.$ARCH pcre-devel.$ARCH
yumdownloader --destdir tmp glibmm24.$ARCH glib2.$ARCH glibmm24-devel.$ARCH dbus libselinux.$ARCH libcap-ng.$ARCH audit-libs.$ARCH expat.$ARCH libsigc++20.$ARCH dbus-devel.$ARCH dbus-glib.$ARCH dbus-glib-devel.$ARCH dbus-libs.$ARCH libffi.$ARCH pcre.$ARCH xz-libs.$ARCH

## Extract all rpms
for i in tmp/*.rpm; do rpm2cpio "$i" | cpio -idmv; done

# Remove unwanted ko files
#find . -name *.ko -exec rm -rf {} \;
rm -rf tmp

cd $BASE_DIR

# Create output
tar cvJf saftlib-$ARCH.tar.xz saftlib-build/*

#Deploy
rm -rf $DEPLOY_TARGET/*
cp saftlib-x86_64.tar.xz $DEPLOY_TARGET
mkdir $DEPLOY_TARGET/x86_64

cp -r saftlib-build/* $DEPLOY_TARGET/x86_64
#tar xvf $DEPLOY_TARGET/saftlib-x86_64.tar.xz
#mv $DEPLOY_TARGET/saftlib-build $DEPLOY_TARGET/x86_64
cp saftlib-dev.sh $DEPLOY_TARGET
