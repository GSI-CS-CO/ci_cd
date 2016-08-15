#!/bin/bash

device=$(head /tmp/saftlib_dev -n 1)

timeout 30m ./test.py $device 10 1000
timeout 30m ./test.py $device 100 100
timeout 30m ./test.py $device 1000 10
timeout 30m ./test.py $device 10000 1
