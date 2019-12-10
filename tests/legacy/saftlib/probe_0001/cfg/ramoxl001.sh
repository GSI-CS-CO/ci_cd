# !/bin/bash

# Constants
device_name="dut"
device_path="dev/wbm0"
device_type="pexarria5a"
device_ref_io="IO1"
device_input_io="IO2"
device_output_io="IO3"

# Stop all saftlib applications
sudo killall saft-* || true
sleep 1

# Stop running saft daemon
sudo killall saftd || true
sleep 15

# Probe gateware and bus structure
sudo eb-info $device_path
sudo eb-ls $device_path

# Start saft daemon
sudo saftd $device_name:$device_path

# Get generic saftlib information
saft-ctl $device_name -i
saft-ctl $device_name -j
saft-ctl $device_name -s

# Get information about IOs
saft-io-ctl $device_name -i
saft-io-ctl $device_name -l

# Dump information to a shared file
echo "name $device_name" > /tmp/saftlib_test
echo "path $device_path" >> /tmp/saftlib_test
echo "type $device_type" >> /tmp/saftlib_test
echo "ref $device_ref_io" >> /tmp/saftlib_test
echo "input $device_input_io" >> /tmp/saftlib_test
echo "output $device_output_io" >> /tmp/saftlib_test
echo "date \"$(date)\"" >> /tmp/saftlib_test

# Set up IOs
saft-io-ctl $device_name -n $device_ref_io -o 0 -t 1 # Reference In
saft-io-ctl $device_name -n $device_input_io -o 0 -t 1 # In
saft-io-ctl $device_name -n $device_output_io -o 1 -t 0 # Out
