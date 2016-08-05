#!/bin/bash
# ===========================================================
# Example: ./start.sh upd/10.10.10.10 schedule.xml

data_master="udp/192.168.191.96"
schedule="ring.xml"

echo "Date:"
date
echo "Uptime:"
uptime
echo ""

while [ $? -eq 0 ]; do
  ./start-data-master.sh $data_master $schedule
  ./parse.py temp.xml
  ./snoop.py pexaria5_18t `wc -l expected_events.txt | cut -f1 -d' '`
  cmp expected_events.txt snooped_events.txt
done

