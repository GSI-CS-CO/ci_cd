#!/bin/bash

# Get all ttf devices
source ../probe_0001/devices.sh

# Internals
sub_line_count=0
eventid=""
parameter=""
timestamp=""
rm log/raw.txt
tcpdump -i eth5 -n "src host 192.168.191.92 and dst host 255.255.255.255" -x > log/raw.txt
sync
sleep 0.5

# Prepage cmp file
rm log/$ttf_gateway_host.txt
touch log/$ttf_gateway_host.txt

while read line
do
  # Get Event ID, Parameter and Execution timestamp
  if [ $sub_line_count -eq 3 ]; then
    eventid=`echo "$line" | awk '{print $6 $7 $8 $9}'`
  elif [ $sub_line_count -eq 4 ]; then
    parameter=`echo "$line" | awk '{print $2 $3 $4 $5}'`
  elif [ $sub_line_count -eq 5 ]; then
    timestamp=`echo "$line" | awk '{print $2 $3 $4 $5}'`
  fi
  # Check for end of message
  if [ $sub_line_count -eq 5 ]; then
    sub_line_count=0
    # Append stuff to log file
    echo "0x"$timestamp "0x"$eventid "0x"$parameter >> log/$ttf_gateway_host.txt
  else
    sub_line_count=$((sub_line_count+1))
  fi
done <log/raw.txt

# Remove PPS and sort events
cat log/$ttf_gateway_host.txt | grep -v "0xffff000000000000" > log/$ttf_gateway_host_no_pps.txt
sort -k1 -n log/$ttf_gateway_host_no_pps.txt > log/s_cmp_$ttf_gateway_host.txt
sync
sleep 0.5
