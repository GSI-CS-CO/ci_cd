#!/bin/bash

# Usage
# <loops> <mode> <schedule>
# <loops> <mode> to generate a random schedule

./run.sh 1 0 "test_cases/cryring_injector.xml"
./run.sh 1 0 "test_cases/cryring_timing_test_ring.xml"
./run.sh 1 0 "test_cases/heartbeat.xml"
./run.sh 1 0 "test_cases/pLinacRF.xml"
./run.sh 1 0 "test_cases/ring.xml"
./run.sh 1 0 "test_cases/sourceLinac.xml"
./run.sh 0 1
