#!/bin/bash

# Device
device="dut"

# Select test case
case "$1" in
  "short")
    timeout 30m ./test.py $device 50 5
    ;;
  "log")
    timeout 30m ./test.py $device 10 1000
    timeout 30m ./test.py $device 100 100
    timeout 30m ./test.py $device 1000 10
    timeout 30m ./test.py $device 10000 1
    ;;
  *)
    echo "Please specify a test mode"
    echo "Available test modes are:"
    echo "  - short"
    echo "  - long"
    exit 1
    ;;
esac
