#!/bin/bash

# Usage: ./script -H 10.10.10.1 -O <<MIB OPTION>>
# Example: ./service_check_generic_snmp.sh -H 192.168.20.51 -O wrsMainSystemStatus
while getopts H:O: option
do
 case "${option}"
 in
H) addr=${OPTARG};;
O) mib_op=${OPTARG};;
 esac
done

# Get SNMP string
ret_str=$(snmpwalk -c public -v 2c $addr -m /etc/icinga2/conf.d/WR-SWITCH-MIB.txt WR-SWITCH-MIB::$mib_op)
if [ $? -ne 0 ]; then
    echo "SNMP error!"
    exit 3
fi

# Parse SNMP string
dump=$(echo $ret_str | grep na )
if [ $? -eq 0 ]; then
    echo "$ret_str"
    exit 3
fi

dump=$(echo $ret_str | grep ok )
if [ $? -eq 0 ]; then
    echo "$ret_str"
    exit 0
fi

dump=$(echo $ret_str | grep error )
if [ $? -eq 0 ]; then
    echo $ret_str
    exit 1
fi

dump=$(echo $ret_str | grep warning )
if [ $? -eq 0 ]; then
    echo $ret_str
    exit 1
fi

dump=$(echo $ret_str? | grep warningNA )
if [ $ret_val -eq 0 ]; then
    echo $ret_str
    exit 1
fi

dump=$(echo $ret_str? | grep bug )
if [ $ret_val -eq 0 ]; then
    echo $ret_str
    exit 2
fi

echo $ret_str
exit 3
