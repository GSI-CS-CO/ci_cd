#!/bin/bash

# Settings
clock_io="IO2"
measure_io="IO3"
device="dut"

# Internals
max_samples=5000
sample_pid=65535
first_edge=0
found_edge=0
file_iter_count=0
sample_count=0
mode=0

# Get arguments
if [ $# -eq 1 ]; then
  frequency_hz=$1
  mode=0
elif [ $# -eq 2 ]; then
  high_phase_ns=$1
  low_phase_ns=$2
  mode=1
else
  echo "Arguments are not valid!"
  exit 1
fi

# Start clock test
echo "Clock generator test started..."
sample_count=0
file_iter_count=0
 
echo "Configuring $clock_io as output..."
saft-io-ctl $device -n $clock_io -o 1 -t 0

echo "Configuring $measure_io as input..."
saft-io-ctl $device -n $measure_io -o 0 -t 1

echo "Starting measurement..."
if [ -f log/raw.txt ]; then
  echo "Removing old raw log file..."
  rm log/raw.txt;
fi
saft-io-ctl $device -w
saft-io-ctl $device -n $measure_io -s > log/raw.txt &
sample_pid=$!

echo "Starting clock..."
if [ $mode -eq 0 ]; then
  saft-clk-gen $device -n $clock_io -f $frequency_hz 0
else
  saft-clk-gen $device -n $clock_io -p $high_phase_ns $low_phase_ns 0
fi

while [ $sample_count -lt $max_samples ]; do
  printf "\rTest progress: %d/%d samples" "$sample_count" "$max_samples"
  sleep 0.5
  sample_count=$(wc -l log/raw.txt | awk '{print $1}')
done
printf "\rTest progress: %d/%d samples\n" "$max_samples" "$max_samples"
printf "Test finished!\n"

echo "Stopping clock..."
saft-clk-gen $device -n $clock_io -s

echo "Configuring $measure_io as input..."
saft-io-ctl $device -n $clock_io -o 0 -t 1

echo "Stopping measurement..."
kill $sample_pid >/dev/null 2>&1
sleep 0.5

if [ -f log/edges.txt ]; then
  echo "Removing old log file..."
  rm log/edges.txt;
fi

echo "Parsing and transforming log file..."
while read io_name edge flags flags_hex id timestamp date; do
  # Ignore table/file headers
  if [ $file_iter_count -ge 2 ]; then
    # Turn everything to decimal values
    if [ $file_iter_count -le $((max_samples+1)) ]; then
      if [ "$edge" == "Rising" ]; then
        echo "1" $(($timestamp)) >> log/edges.txt
      elif [ "$edge" == "Falling" ]; then
        echo "0" $(($timestamp)) >> log/edges.txt
      else
        echo "Log file seems to be broken!"
        exit 1
      fi
    fi
  fi
  file_iter_count=$((file_iter_count+1))
done <log/raw.txt
sleep 0.5

echo "Checking results..."
if [ $mode -eq 0 ]; then
  ./analyze.py log/edges.txt $frequency_hz
else
  ./analyze.py log/edges.txt $high_phase_ns $low_phase_ns
fi


