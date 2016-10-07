#!/bin/bash
set -e

# Settings
clock_io="IO1"
measure_io="IO2"
device=dut
sample_count=0
max_samples=5000
sample_pid=65535
first_edge=0
found_edge=0
file_iter_count=0

# Test cases
# !!! Provide array here with test settings

# Start clock test
echo "Clock generator test started..."

echo "Configuring $clock_io as output..."
saft-io-ctl $device -n $clock_io -o 1
saft-io-ctl $device -n $clock_io -t 0

echo "Configuring $measure_io as input..."
saft-io-ctl $device -n $measure_io -o 0
saft-io-ctl $device -n $measure_io -t 1

echo "Starting measurement..."
saft-io-ctl $device -w
saft-io-ctl $device -n $measure_io -s > log/raw.txt &
sample_pid=$!

echo "Starting clock..."
saft-clk-gen $device -n $clock_io -f 100000 0

while [ $sample_count -lt $max_samples ]; do
  printf "\rTest progress: %d/%d samples" "$sample_count" "$max_samples"
  sleep 0.5
  sample_count=$(wc -l log/raw.txt | awk '{print $1}')
done
printf "\rTest progress: %d/%d samples\n" "$max_samples" "$max_samples"
printf "Test finished!\n"

echo "Stopping clock..."
saft-clk-gen $device -n $clock_io -s
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
