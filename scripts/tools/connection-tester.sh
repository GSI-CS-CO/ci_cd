#!/bin/bash
#===========================================================
# Synopsis:
# Writes random values and reads it back. Simple "Connection" test.
#
# Parameters:
#   [1]: device name
#   [2]: read write iterations
#
# Example: ./connection-tester.sh dev/wbm0 10"

# Check Arguments
if [ $# -ne 2 ]; then
  echo "Sorry we need at least 2 parameters..."
  echo "Example: ./connection-tester.sh dev/wbm0 10"
  exit 1
fi

# Arguments
arg_device_name=$1
arg_iterations=$2

# Fixed settings
test_slave_vendor_id=0x0000000000000651
test_slave_device_id=0x10c05791

# Find slave
slave_id=`eb-find $arg_device_name $test_slave_vendor_id $test_slave_device_id`

# Start read write cycles
for (( cyc_cnt=1; cyc_cnt<=$arg_iterations; cyc_cnt++ )); do
  set_val=`hexdump -n 4 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr '[A-Z]' '[a-z]'`
  eb-write $arg_device_name $slave_id/4 0x$set_val
  get_val=`eb-read $arg_device_name $slave_id/4`
  if [ $set_val == $get_val ]; then
    echo "Iteration #$cyc_cnt: Succeeded! 0x$get_val == 0x$set_val"
  else
    echo "Iteration #$cyc_cnt: Failed! 0x$get_val != 0x$set_val"
    exit 1
  fi
done
exit 0
