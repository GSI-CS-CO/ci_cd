#!/bin/bash

# Get all ttf devices
source ../probe_0001/devices.sh

# Get names and ipv4 addresses
devices_by_name=(${ttf_pexaria_names[@]} ${ttf_scu_names[@]} ${ttf_vetar_names[@]})
devices_by_ipv4=(${ttf_pexaria_ipv4[@]} ${ttf_scu_ipv4[@]} ${ttf_vetar_ipv4[@]})

# Internal values
fail_count=0
fail_count_prev=0
dev_id=0
ip=0.0.0.0
count=1000
interval=0.1
end_test=0
test_loops=0
loop_count=0

# Start
# Check arguments
if test "$#" -eq 1; then
  test_loops=$1
else
  echo "Usage ./start.h <loop(s)> (0 for endless testing)"
  exit 1
fi

# Start loop
while [ $end_test -eq 0 ]; do
  dev_id=0
  for i in ${devices_by_name[@]}; do
    ip=${devices_by_ipv4[$dev_id]}
    sleep 0.1
    echo "Checking device ($i@$ip) -> Using gateway s$ttf_gateway_host.$tff_postfix"
    ssh $ttf_gateway_user@$ttf_gateway_host.$tff_postfix "ping $ip -c $count -i $interval 2>&1" > log/$i.txt &
    dev_id=$((dev_id+1))
  done
  
  dev_id=0
  echo ""
  for job in `jobs -p`; do
    echo "Waiting for job $job... (${devices_by_name[$dev_id]})"
    wait $job || let "fail_count+=1"
    if [ $fail_count_prev -ne $fail_count ]; then
      echo "Warning: Test failed for ${devices_by_name[$dev_id]}!"
    fi
    fail_count_prev=$fail_count
    dev_id=$((dev_id+1))
  done
  
  loop_count=$((loop_count+1))
  if [ "$fail_count" == "0" ]; then
    echo "Iteration finished without error(s) ($loop_count iteration(s))!"
    echo ""
  else
    echo ""
    echo "Test finished with error(s) after $loop_count iteration(s)! ($fail_count error(s))"
    end_test=1
    exit 1
  fi
  
  if [ $test_loops -ne 0 ]; then
    if [ $loop_count -eq $test_loops ]; then
      echo ""
      echo "Test finished without errors after $loop_count iterations!"
      end_test=1
    fi
  fi
done
