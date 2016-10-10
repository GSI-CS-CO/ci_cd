# !/bin/bash

# Constants
device_name="dut"
device_path="dev/wbm0"
device_type="pexarria5a"

# Stop running saft daemon
sudo killall saftd || true
sleep 15

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
echo $device_name > /tmp/saftlib_dev
echo $device_path >> /tmp/saftlib_dev
echo $device_type >> /tmp/saftlib_dev

# Set up IOs to safe settings
saft-io-ctl $device_name -n IO1 -o 0 -t 1
saft-io-ctl $device_name -n IO2 -o 0 -t 1
saft-io-ctl $device_name -n IO3 -o 0 -t 1
