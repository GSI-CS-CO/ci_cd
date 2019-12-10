#!/bin/bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/common/usr/timing/lib
export PATH=$PATH:/common/usr/timing/bin

# Usage: ./script 10.10.10.1
trackphase="TRACKING"
while getopts H: option
do
 case "${option}"
 in
H) addr=${OPTARG};;
 esac
done

# Check White Rabbit Status
state=$(eb-mon udp/$addr -y)
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo "White Rabbit state: Unknown"
    exit 2
fi

# Check for current release
res=$(echo $state | grep $trackphase)
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo "White Rabbit state: $res"
    exit 1
else
    echo "White Rabbit state: $res"
    exit 0
fi
