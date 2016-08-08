#!/bin/bash

data_master="udp/192.168.191.96"
schedule="schedule.xml"
device="pexaria5_18t"

echo "Date:"
date
echo "Uptime:"
uptime
echo ""

while [ $? -eq 0 ]; do
  ./generate.py
  ./start-data-master.sh $data_master $schedule
  ./parse.py $schedule
  ./snoop.py $device `wc -l expected_events.txt | cut -f1 -d' '`
  cmp expected_events.txt snooped_events.txt
done

