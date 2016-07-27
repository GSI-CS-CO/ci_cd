#!/bin/bash

device=$(head /tmp/saftlib_dev -n 1)

timeout 30m ./test.py $device 25 10
timeout 30m ./test.py $device 250 10
timeout 30m ./test.py $device 2500 10
