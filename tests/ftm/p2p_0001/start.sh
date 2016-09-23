#!/bin/bash
set -e

# Dynamic settings
p2p_interface=eth3
p2p_ip_addr=10.10.10.1 # sudo ifconfig $p2p_interface 10.10.10.1 
ftm_access=dev/wbm0
ftm_schedule=../../ttf/dm_0001/test_cases/cryring_injector.xml
ftm_ip_addr=10.10.10.2 # eb-console $ftm_access => set ip 10.10.10.2

# Fixed settings
dm_schedule_keyword="___STARTTIME___"
dm_start_offset=0x00000000200000000
dm_start_time=0x0
dm_schedule_ts_name="ping.xml"
glue_path=../../ttf/dm_0001
sub_line_count=0
eventid=""
parameter=""
timestamp=""

# Start data master and set start time in schedule
function start_data_master()
{
  # Copy old schedule
  cp "$ftm_schedule" log/$dm_schedule_ts_name
  
  # Get time from ECA
  dm_time=`ftm-ctl $ftm_access -t | grep "ECA TIME" | cut -c 32-49`
  dm_time="$(($dm_time+0))" # To dec
  dm_start_time="$(($dm_time+$dm_start_offset))" # Add offset
  echo $dm_start_time > log/start_time.txt
  
  # Print debug infos
  printf "Current time at Data Master: 0x%x (%d)\n" $dm_time $dm_time
  printf "Start time at Data Master:   0x%x (%d)\n" $dm_start_time $dm_start_time
  
  # Get right start time in the schedule
  sed -i "s/$dm_schedule_keyword/$dm_start_time/g" log/$dm_schedule_ts_name
  
  # Finally set up the Data Master
  ftm-ctl $ftm_access -c 0 preptime 500000
  echo "DM Set Preptime 500000..."
  ftm-ctl $ftm_access -c 0 put log/$dm_schedule_ts_name
  echo "DM Put..."
  ftm-ctl $ftm_access -c 0 swap
  echo "DM Swap..."
  ftm-ctl $ftm_access -c 0 run
  echo "DM Run..."
}

# Wait until schedule should have finished
function poll_dm_time()
{
  # Get time from ECA
  duration=`cat log/duration.txt`
  dm_time_now=`ftm-ctl $ftm_access -t | grep "ECA TIME" | cut -c 32-49`
  dm_time_now="$(($dm_time_now+0))" # To dec
  dm_duration_ns="$((${duration%.*}*1000000000))"
  dm_end_time="$(($dm_start_time+$dm_duration_ns))"
  time_left="$(($dm_end_time-$dm_time_now))"
  
  # Wait for end of schedule
  while [ $time_left -ge 0 ]; do
    sleep 0.5
    printf "\rTest will finish in: %dns..." "$time_left"
    dm_time_now=`ftm-ctl $ftm_access -t | grep "ECA TIME" | cut -c 32-49`
    dm_time_now="$(($dm_time_now+0))" # To dec
    time_left="$(($dm_end_time-$dm_time_now))"
  done
  printf "\rTest will finish in: %dns...                                   " "0"
  printf "\n\n\n"
}

start_data_master
./$glue_path/parse.py log/$dm_schedule_ts_name
tcpdump -i $p2p_interface -n "src host $ftm_ip_addr and dst host 255.255.255.255" -x > log/raw.txt &
poll_dm_time
sleep 2
killall tcpdump
sleep 2

rm log/host.txt
touch log/host.txt
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
    echo "0x"$timestamp "0x"$eventid "0x"$parameter >> log/host.txt
  else
    sub_line_count=$((sub_line_count+1))
  fi
done <log/raw.txt

sort -k1 -n log/expected_events.txt > log/e_cmp.txt
sort -k1 -n log/host.txt > log/s_cmp_host.txt
sync
sleep 0.5
cmp log/e_cmp.txt log/s_cmp_host.txt
if [ $? -eq 0 ]; then
  echo "Got all events!"
else
  echo "Lost event(s)!"
fi

