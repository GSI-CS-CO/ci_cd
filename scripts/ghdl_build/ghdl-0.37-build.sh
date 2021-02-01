# This script builds gcc-10.2 with ghdl-gcc version GHDL 0.37
# Executables and libraries are installed into `pwd`/local/...


BUILDDIR=`pwd`
INSTALLDIR=$BUILDDIR/local

cd $BUILDDIR
mkdir -p $INSTALLDIR

# install GMP
wget https://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.gz
tar -xvf gmp-5.1.3.tar.gz
cd gmp-5.1.3/
./configure --prefix=$INSTALLDIR
make -j 8 install
cd ..
cd $BUILDDIR

#install MPFR
wget https://www.mpfr.org/mpfr-4.0.2/mpfr-4.0.2.tar.bz2
tar -xvf mpfr-4.0.2.tar.bz2
cd mpfr-4.0.2/
./configure --prefix=$INSTALLDIR --with-gmp=$INSTALLDIR
make -j 8 install
cd ..
cd $BUILDDIR

#install MPC
wget https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz
tar -xvf mpc-1.1.0.tar.gz
cd mpc-1.1.0/
./configure --prefix=$INSTALLDIR --with-gmp=$INSTALLDIR
make -j 8 install
cd ..
cd $BUILDDIR

#install ISL
wget http://isl.gforge.inria.fr/isl-0.22.tar.bz2
tar -xvf isl-0.22.tar.bz2
cd isl-0.22/
./configure --prefix=$INSTALLDIR --with-gmp-prefix=$INSTALLDIR
make -j 8 install
cd ..
cd $BUILDDIR



# build and install gcc-10.2
wget ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-10.2.0/gcc-10.2.0.tar.gz
tar -xvf gcc-10.2.0.tar.gz
mkdir gcc-build
cd gcc-build
../gcc-10.2.0/configure --prefix=$INSTALLDIR --disable-bootstrap --with-isl=$INSTALLDIR --with-mpc=$INSTALLDIR --with-mpfr=$INSTALLDIR --with-gmp=$INSTALLDIR --enable-multilib --enable-shared --enable-languages=c,c++,ada
LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make -j 16
make install
cd $BUILDDIR

# install verilator 
git clone https://github.com/verilator/verilator.git
cd verilator/
git checkout tags/v3.926
autoconf
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 ./configure --prefix=$INSTALLDIR
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make -j 8
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make install
cd ..
cd $BUILDDIR


# clone GHDL repo
git clone https://github.com/ghdl/ghdl.git
cd ghdl
git checkout tags/v0.37
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 ./configure --prefix=$INSTALLDIR --with-gcc=../gcc-10.2.0 --enable-libghdl 
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make copy-sources 
cd $BUILDDIR
mkdir gcc-ghdl-build
cd gcc-ghdl-build
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 ../gcc-10.2.0/configure --prefix=$INSTALLDIR --with-isl=$INSTALLDIR --with-mpc=$INSTALLDIR --with-mpfr=$INSTALLDIR --with-gmp=$INSTALLDIR --enable-__cxa_atexit --disable-libunwind-exceptions --enable-shared --enable-clocale=gnu --disable-libstdcxx-pch --disable-libssp --enable-gnu-unique-object --enable-linker-build-id --enable-lto --enable-plugin --enable-install-libiberty --with-linker-hash-style=gnu --enable-gnu-indirect-function --disable-multilib --disable-werror --enable-checking=release --enable-default-pie --enable-default-ssp --enable-languages=vhdl,c,c++ --disable-bootstrap --disable-libgomp --disable-libquadmath --enable-languages=c,c++,ada,vhdl
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make -j 16
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make install
cd $BUILDDIR

# build libraries
cd ghdl 
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make ghdllib
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 make install
cd $BUILDDIR

# compile vendor libs 
cd $INSTALLDIR/lib/ghdl/vendors
PATH=$INSTALLDIR/bin:$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:$INSTALLDIR/lib64 ./compile-altera.sh --vhdl93 --all --out . --src /opt/quartus/18/quartus/eda/sim_lib
cd $BUILDDIR




