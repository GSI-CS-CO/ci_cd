#!/bin/bash
#===========================================================
# First parameter must be the saftlib directory
DIRECTORY=$1

if [ -d "$DIRECTORY" ]; then
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



