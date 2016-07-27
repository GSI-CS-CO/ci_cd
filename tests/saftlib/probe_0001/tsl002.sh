# !/bin/bash

# Constants
device_name="dut"
device_path="dev/wbm0"
device_type="pexarria5a"

# Stop running saft daemon
sudo killall saftd || true
sleep 15

# Start saft daemon get some information
sudo saftd $device_name:$device_path
saft-ctl $device_name -i
saft-ctl $device_name -j
saft-ctl $device_name -s

# Dump information to a shared file
echo $device_name > /tmp/saftlib_dev
echo $device_path >> /tmp/saftlib_dev
echo $device_type >> /tmp/saftlib_dev

# Get information about IOs
saft-io-ctl $device_name -i
saft-io-ctl $device_name -l

# Set up IOs to safe settings
saft-io-ctl $device_name -n IO1 -o 0 -t 1
saft-io-ctl $device_name -n IO2 -o 0 -t 1
saft-io-ctl $device_name -n IO3 -o 0 -t 1

# Set up LEDs to indicate activity
saft-io-ctl $device_name -n LED1_ADD_R -c 0x0 0x0 0 0xf 1 -u
saft-io-ctl $device_name -n LED1_ADD_R -c 0x0 0x0 31250000 0xf 0 -u

saft-io-ctl $device_name -n LED2_ADD_B -c 0x0 0x0 0 0xf 1 -u
saft-io-ctl $device_name -n LED2_ADD_B -c 0x0 0x0 62500000 0xf 0 -u

saft-io-ctl $device_name -n LED3_ADD_G -c 0x0 0x0 0 0xf 1 -u
saft-io-ctl $device_name -n LED3_ADD_G -c 0x0 0x0 125000000 0xf 0 -u

saft-io-ctl $device_name -n LED4_ADD_W -c 0x0 0x0 0 0xf 1 -u 
saft-io-ctl $device_name -n LED4_ADD_W -c 0x0 0x0 250000000 0xf 0 -u 

saft-io-ctl $device_name -n LED1_BASE_R -c 0x0 0x0 0 0xf 1 -u 
saft-io-ctl $device_name -n LED1_BASE_R -c 0x0 0x0 31250000 0xf 0 -u 

saft-io-ctl $device_name -n LED2_BASE_B -c 0x0 0x0 0 0xf 1 -u 
saft-io-ctl $device_name -n LED2_BASE_B -c 0x0 0x0 62500000 0xf 0 -u 

saft-io-ctl $device_name -n LED3_BASE_G -c 0x0 0x0 0 0xf 1 -u 
saft-io-ctl $device_name -n LED3_BASE_G -c 0x0 0x0 125000000 0xf 0 -u 

saft-io-ctl $device_name -n LED4_BASE_W -c 0x0 0x0 0 0xf 1 -u 
saft-io-ctl $device_name -n LED4_BASE_W -c 0x0 0x0 250000000 0xf 0 -u 

