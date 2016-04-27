#!/bin/bash
#===========================================================
# First parameter must be the saftlib directory
#
# Example: ./install-run-deb.sh ../somewhere/saftlib

directory=$1

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
  sudo saftd baseboard:dev/wbm0
  exit 0
else
  echo "Saftlib directory not found!"
  exit 1
fi



