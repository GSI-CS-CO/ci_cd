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

# If there is a NUL character anywhere in the file, grep will consider it as a binary file. TR will help here.
gateware=$(eb-info udp/$addr | tr -d '\000' | grep "Build type")
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo "Error : Firmware unknown"
    exit 2
fi

# Check for current release
res=$(echo $gateware | grep $current_release)
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo $gateware
    exit 1
else
    echo $gateware
    exit 0
fi
