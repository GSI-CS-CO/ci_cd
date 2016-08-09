#!/bin/bash

data_master="udp/192.168.191.96"
schedule="schedule.xml"
device="pexaria5_18t"
spin='-\|/'
echo "Test started..."

while [ $? -eq 0 ]; do
  echo "Date:"
  date
  echo "Uptime:"
  uptime
  echo ""
  spin_i=0
  ./generate.py
  ./start-data-master.sh $data_master $schedule
  ./parse.py $schedule
  expected_events=`wc -l expected_events.txt | cut -f1 -d' '`
  ./snoop.py $device $expected_events &
  #pid=$!
  #trap "kill $pid 2> /dev/null" EXIT
  snooped_events=0
  rm snooped_events.txt
  # Wait until snoop is done
  #while kill -0 $pid 2> /dev/null; do
  while [ $snooped_events -ne $expected_events ]; do
    if [ -f snooped_events.txt ]
    then
      snooped_events=`wc -l snooped_events.txt | cut -f1 -d' '`
    fi
    sleep 0.1
    spin_i=$(( (spin_i+1) %4 ))
    printf "\rProgress: $snooped_events/$expected_events ${spin:$spin_i:1}"
  done
  printf "\rProgress: $expected_events/$expected_events   \n"
  #trap - EXIT
  # Sort event lists
  sort -k1 -n snooped_events.txt > s_cmp.txt
  sort -k1 -n expected_events.txt > e_cmp.txt
  # Finally compare the lists
  cmp s_cmp.txt e_cmp.txt
  echo ""
done
