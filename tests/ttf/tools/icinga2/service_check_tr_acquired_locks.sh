#!/bin/bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/common/usr/timing/lib
export PATH=$PATH:/common/usr/timing/bin

# Usage: ./script 10.10.10.1
while getopts H: option
do
 case "${option}"
 in
H) addr=${OPTARG};;
 esac
done

# Get acquired locks
locks=$(eb-mon udp/$addr -g | grep "of acquired locks" | awk '{print $5}')
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo "Acquired locks unknown"
    exit 2
fi

# Process number of acquired locks
if [ $locks -eq 0 ]; then
    echo "Lock acquired once"
    exit 0
elif [ $locks -gt 0 ]; then
    echo "Lock(s) acquired: $locks"
    exit 1
else
    echo "Lock(s) acquired: $locks"
    exit 2
fi
