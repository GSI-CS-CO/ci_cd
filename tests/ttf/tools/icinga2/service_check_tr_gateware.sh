#!/bin/bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/common/usr/timing/lib
export PATH=$PATH:/common/usr/timing/bin

# Usage: ./script 10.10.10.1
current_release="Enigma"
while getopts H: option
do
 case "${option}"
 in
H) addr=${OPTARG};;
 esac
done

# Check gateware
gateware=$(eb-mon udp/$addr -a)
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo "Gateware: Unknown"
    exit 2
fi

# Check for current release
res=$(echo $gateware | grep $current_release)
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo "Gateware: $gateware"
    exit 1
else
    echo "Gateware: $gateware"
    exit 0
fi
