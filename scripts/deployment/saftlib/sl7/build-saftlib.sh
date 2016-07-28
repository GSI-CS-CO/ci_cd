#! /bin/bash

BUILD_DIRECTORY="tmp-saftlib"
LIBS_DIRECTORY=$BUILD_DIRECTORY/"build"
BEL_BRANCH="proposed_master"
DEST_DIRECTORY=`pwd`"/"$BUILD_DIRECTORY
BASE_DIR=`pwd`
JOBS=32
DEPLOY_TARGET="/common/export/saftlib-dev/rc8"

# Create a new checkout
if [ -d "$BUILD_DIRECTORY" ]; then
  rm -fr $BUILD_DIRECTORY
fi
mkdir $BUILD_DIRECTORY
cd $BUILD_DIRECTORY
git clone https://github.com/GSI-CS-CO/bel_projects.git --recursive

# Update all submodules and checkout the select branch
cd bel_projects
git checkout $BEL_BRANCH
git submodule init
git submodule update --recursive

# Build saftlib
cd ip_cores/saftlib
git clean -xfd .
./autogen.sh
export PKG_CONFIG_PATH=/common/usr/timing/root/lib/pkgconfig
#./configure --prefix="" --sysconfdir=/etc

./configure --prefix="" --sysconfdir=/etc \
CFLAGS="-I$DEPLOY_TARGET/usr" \
GIOMM_CFLAGS="-pthread -I/c/usr/include/giomm-2.4 -I/common/usr/timing/root/usr/lib64/giomm-2.4/include -I/common/usr/timing/root/usr/include/glibmm-2.4 -I/common/usr/timing/root/usr/lib64/glibmm-2.4/include -I/common/usr/timing/root/usr/include/sigc++-2.0 -I/common/usr/timing/root/usr/lib64/sigc++-2.0/include -I/common/usr/timing/root/usr/include/glib-2.0 -I/common/usr/timing/root/usr/lib64/glib-2.0/include" GIOMM_LIBS="-L/common/usr/timing/root/usr/lib64/ -lgiomm-2.4 -lgio-2.0 -lglibmm-2.4 -lgobject-2.0 -lsigc-2.0 -lglib-2.0"

make -j $JOBS DESTDIR=$DEST_DIRECTORY/saftlib/x86_64 install
make -j $JOBS DESTDIR=$DEST_DIRECTORY/saftlib/i386 EXTRA_FLAGS="-m32" install
cd ../../..

# Leave bel_projects
cd ..

# Get stuff we depent on
if [ -d "$LIBS_DIRECTORY" ]; then
  rm -fr $LIBS_DIRECTORY
fi
mkdir $LIBS_DIRECTORY
cd $LIBS_DIRECTORY

for i in x86_64 i386; do
  # set ARCH and download our stuff
  ARCH=$i
  yumdownloader --destdir tmp glibmm24.$ARCH lib dbus glib2.$ARCH libselinux.$ARCH libcap-ng.$ARCH audit-libs.$ARCH expat.$ARCH libsigc++20.$ARCH 
  rm -rf staging
  mkdir staging
  cd staging
  # Extract all rpms
  for i in ../tmp/*; do rpm2cpio "$i" | cpio -idmv; done
  # Remove unwanted ko files
  find . -name *.ko -exec rm -rf {} \;
  cd ..
  # Create output
  tar cvJf ../saftlib-$ARCH.tar.xz .
  # Clean up
  cd ..
  rm -rf staging
  rm -rf tmp
done

cp saftlib-x86_64.tar.xz $DEPLOY_TARGET
cp saftlib-i386.tar.xz $DEPLOY_TARGET

rm -rf $DEPLOY_TARGET/x86_64
rm -rf $DEPLOY_TARGET/i386
rm $DEPLOY_TARGET/i686

cd $DEST_DIRECTORY

cp -r saftlib/x86_64 $DEPLOY_TARGET/x86_64
cp -r saftlib/i386 $DEPLOY_TARGET/i386
cd $DEPLOY_TARGET
ln -s i386 i686
cd $BASE_DIR

cp saftlib-dev.sh $DEPLOY_TARGET

