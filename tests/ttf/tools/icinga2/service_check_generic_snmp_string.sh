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

echo $ret_str
exit 0
