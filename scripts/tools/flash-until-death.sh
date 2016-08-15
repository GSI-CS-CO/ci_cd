#!/bin/bash
#===========================================================
# Parameters:
#   [1]: device name
#   [2]: file name (rpd)
#   [3]: attempts (0=infinite)
#
# Example: ./flash-until-death bitstream.rpd dev/wbm0 10

device_name=$1;
stream_name=$2;
attempts=$3;

attempt_cnt=0

if [ $# -ne 3 ]; then
  echo "Sorry we need at least 3 parameters..."
  echo "Example: ./flash-until-death dev/wbm0 bitstream.rpd 10"
  exit 1
fi

false;
while [ $? -eq 1 ]; do
  if [ $attempts -ne 0 ]; then
    if [[ $attempts -ne $attempt_cnt ]]; then
      attempt_cnt=$(($attempt_cnt+1))
    else
      exit 1
    fi
  fi
  sleep 0.5
  echo "Trying to flash $device_name with $stream_name..."
  if [ $attempts -ne 0 ]; then
    echo "Attempt $attempt_cnt of $attempts:"
  fi
  echo ""
  eb-flash $device_name $stream_name
done
