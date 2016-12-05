#!/bin/bash

# Settings
IO_WR="IO1"
IO_ECA="IO2"
DEV_NAME="exp" # Must match with saft daemon (i.e. sudo saftd exp:dev/wbm0)

# Clean up helper
function clean_up
{
  killall saft-io-ctl
  killall saft-pps-gen
  saft-io-ctl $DEV_NAME -n $IO_WR -p 0
}

# Clean up
clean_up

# Enable output
saft-io-ctl $DEV_NAME -o 1 -n $IO_WR
saft-io-ctl $DEV_NAME -o 1 -n $IO_ECA

# Disable termination
saft-io-ctl $DEV_NAME -t 1 -n $IO_WR
saft-io-ctl $DEV_NAME -t 1 -n $IO_ECA

# Configure PPS gate
saft-io-ctl $DEV_NAME -n $IO_WR -p 1

# Configure ECA 
saft-io-ctl $DEV_NAME -n $IO_ECA -c 0xffff000000000000 0xffff000000000000 0 0xf 1 &
saft-io-ctl $DEV_NAME -n $IO_ECA -c 0xffff000000000000 0xffff000000000000 500000 0xf 0 &

# Trigger PPS
saft-pps-gen $DEV_NAME -i

# Clean up
clean_up
