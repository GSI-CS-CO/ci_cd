#!/bin/bash

# Etherbone packet layout (ECA input):
# WB Address [32 bit]
# EventID [64 bit]
# Parameter [64 bit]
# TEF [32 bit]
# Reserved [32 bit]

# Get all ttf devices
source ../probe_0001/devices.sh

# Arguments
snoop_interface=$1
dm_addr=$2

# Internals
sub_line_count=0
word_count=0
length=0
num_of_packets=0
header_passed=0
eventid=""
parameter=""
timestamp=""
rm log/raw.txt
tcpdump -i $snoop_interface -n "src host $dm_addr and dst host 255.255.255.255" -x > log/raw.txt
rm log/capture.txt
echo "tcpdump done" >> log/capture.txt
sync
sleep 0.5

# Prepage cmp file
rm log/$ttf_gateway_host.txt
touch log/$ttf_gateway_host.txt

# Format raw log file from tcpdump
rm log/raw_one_line.txt
touch log/raw_one_line.txt

# Transform log file format into "one line" format
while read line
do
  inspect=`echo $line | awk '{print $2}'`
  if [[ $inspect == "IP" ]]; then
    length=`echo $line | awk '{print $8}'`
    num_of_packets=$(($length-4))
    num_of_packets=$((num_of_packets/40))
    if [ $header_passed -eq 1 ]; then
      echo "" >> log/raw_one_line.txt
    fi
    header_passed=1
  else
    echo $line | tr '\n' ' ' | sed 's/0x....: //g' >> log/raw_one_line.txt
  fi
done <log/raw.txt

echo "oneline done" >> log/capture.txt

item_count=0
frame_word=0
frame_len=0

eventid_hh=0
eventid_hl=0
eventid_lh=0
eventid_ll=0
parameter_hh=0
parameter_hl=0
parameter_lh=0
parameter_ll=0
timestamp_hh=0
timestamp_hl=0
timestamp_lh=0
timestamp_ll=0

# Parse each line for eventid, parameter and timestamp
while read line
do
  #echo $line
  for i in $line; do
    #echo $i
    if [ $item_count -eq 1 ]; then
      frame_len=$i
      frame_len=$((16#$frame_len))
    elif [ $item_count -le 15 ]; then
      frame_word=0
    else
      # Find eventid, parameter and timestamp
      case $frame_word in
          4)  
            eventid_hh=$i ;;
          5)  
            eventid_hl=$i ;;
          6)   
            eventid_lh=$i ;;
          7)  
            eventid_ll=$i ;;
          8)  
            parameter_hh=$i ;;
          9)  
            parameter_hl=$i ;;
          10)   
            parameter_lh=$i ;;
          11)  
            parameter_ll=$i ;;
          16)  
            timestamp_hh=$i ;;
          17)  
            timestamp_hl=$i ;;
          18)   
            timestamp_lh=$i ;;
          19)  
            timestamp_ll=$i ;;
          *)
            ;;
      esac
      # Next frame? Dump eventid, parameter and timestamp to log/comparision file
      if [ $frame_word -eq 19 ]; then
        frame_word=0
        echo "0x$timestamp_hh$timestamp_hl$timestamp_lh$timestamp_ll 0x$eventid_hh$eventid_hl$eventid_lh$eventid_ll 0x$parameter_hh$parameter_hl$parameter_lh$parameter_ll" >> log/$ttf_gateway_host.txt
      else
        frame_word=$((frame_word+1))
      fi
    fi
    item_count=$((item_count+1))
  done
  item_count=0
done <log/raw_one_line.txt

echo "parser done" >> log/capture.txt

# Remove PPS and sort events
cat log/$ttf_gateway_host.txt | grep -v "0xffff000000000000" > log/$ttf_gateway_host_no_pps.txt
echo "pps remover done" >> log/capture.txt

sort -k1 -n log/$ttf_gateway_host_no_pps.txt > log/s_cmp_$ttf_gateway_host.txt
echo "sort done" >> log/capture.txt
sync
sleep 0.5
