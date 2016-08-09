#!/bin/bash
################################################################################

# Variables
data_master=$1 # Data Master must be the first argument (dev/ttyUSBX, udp/192.168.0.1, ...)
#eca_pattern=0xffff000000000000 # FID=MAX & GRPID=MAX
schedule=$2
schedule_next=schedule.xml
schedule_keyword="___STARTTIME___"
#start_offset=0x0000000100000000
start_offset=0x0000000050000000
start_time=0x0
period=1000000000
wait_time=0

# Copy old schedule
#cp "$schedule" "$schedule_next"

# Get time from ECA
#time=`eca-ctl $data_master -n | grep time | cut -d: -f2` # Legacy ECA tools
time=`ftm-ctl $data_master -t | grep "ECA TIME" | cut -c 32-49`

time="$(($time+0))" # To dec
start_time="$(($time+$start_offset))" # Add offset
#start_time="$(((start_time+period+period-1)/period*period))" # Round up to the next second

# Print debug infos
printf "Current time at Data Master: 0x%x (%d)\n" $time $time
printf "Start time at Data Master:   0x%x (%d)\n" $start_time $start_time

# Get right start time in the schedule
sed -i "s/$schedule_keyword/$start_time/g" "$schedule_next"

# Finally set up the Data Master

ftm-ctl $data_master -c 1 preptime 500000
echo "DM Preptime 500000..."
ftm-ctl $data_master -c 1 put $schedule_next
echo "DM Put..."
ftm-ctl $data_master -c 1 swap
echo "DM Swap..."
ftm-ctl $data_master -c 1 run
echo "DM Run..."
#cd ..

# Wait until Data Master should start
#while [ $start_time -ge  $time ]; do
#  wait_time="$(($start_time-$time))"
#  printf "\rData Master will start in %dns..." "$wait_time"
#  #time=`eca-ctl $data_master -n | grep time | cut -d: -f2` # Legacy ECA tools
#  time=`ftm-ctl $data_master -t | grep "ECA TIME" | cut -c 32-49`
#  time="$(($time+0))" # To dec
#  #printf "Current time at Data Master: 0x%x (%d)\n" $time $time
#  #printf "Start time at Data Master:   0x%x (%d)\n" $start_time $start_time
#done

#printf "\rData Master will start in 0ns...                         \n" 
#echo "Data Master started!"
