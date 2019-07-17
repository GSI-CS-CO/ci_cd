#!/bin/bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/common/usr/timing/lib
export PATH=$PATH:/common/usr/timing/bin

# Usage: ./script -H 10.10.10.1 -O eb-cmd -A <<optional parameter>>
# Example: ./service_check_generic_snmp.sh -H 192.168.20.51 -O eb-ls
# Example: ./service_check_tr_eb_command.sh -H 192.168.160.52 -O eb-find -A "0x651 0x68202b22"
while getopts H:O:A: option
do
 case "${option}"
 in
H) addr=${OPTARG};;
O) eb_cmd=${OPTARG};;
A) add_param=${OPTARG};;
 esac
done

# Get SNMP string
ret_str=$($eb_cmd udp/$addr $add_param)
if [ $? -ne 0 ]; then
    echo "Connection error!"
    exit 3
fi

echo $ret_str
exit 0
