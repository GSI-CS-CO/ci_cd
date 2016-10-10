# Create/change to workspace directory
if [ -d workspace ]; then
  mkdir workspace
fi

# Remove old saftlib stuff
cd workspace
if [ -d saftlib ]; then
  rm -rf saftlib
fi

# Get latest saftlib master
git clone https://github.com/GSI-CS-CO/saftlib.git saftlib
cd saftlib
git clean -xfd .

# Compile and install
./autogen.sh
./configure --enable-maintainer-mode --prefix=/usr --sysconfdir=/etc
make clean
make
sudo make install
