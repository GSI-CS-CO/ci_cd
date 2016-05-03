#!/bin/bash
#===========================================================
# First parameter must be the saftlib directory and the 
# second parameter should be a device (with path)
#
# Example: ./install-run-deb.sh ../somewhere/saftlib baseboard:dev/wbm0

directory=$1
saftd_arg=$2

if [ $# -ne 1 ]; then
  echo "Sorry we need at least 1 parameter..."
  echo "Example: ./install-run-deb.sh ../somewhere/saftlib"
  exit 1
fi

if [ -d "$directory" ]; then
  cd $DIRECTORY
  ./autogen.sh
  ./configure --enable-maintainer-mode --prefix=/usr --sysconfdir=/etc
  make -j 32
  sudo make install
  sleep 0.5
  sudo killall saftd | true
  sleep 0.5
  sudo saftd $2
  exit 0
else
  echo "Saftlib directory not found!"
  exit 1
fi



