#!/bin/bash

# Usage for run.sh
# <loops> <mode> <schedule>
# <loops> <mode> to generate a random schedule

# Select test case
case "$1" in
  "cryring")
    ./run.sh 1 1 "test_cases/cryring_injector.xml"
    ;;
  "unipz")
    ./run.sh 1 1 "test_cases/unipz.xml"
    ;;
  "random")
    ./run.sh 1 1
    ;;
  "all")
    ./run.sh 1 1 "test_cases/cryring_injector.xml"
    ./run.sh 1 1 "test_cases/cryring_timing_test_ring.xml"
    ./run.sh 1 1 "test_cases/heartbeat.xml"
    ./run.sh 1 1 "test_cases/pLinacRF.xml"
    ./run.sh 1 1 "test_cases/ring.xml"
    ./run.sh 1 1 "test_cases/sourceLinac.xml"
    ./run.sh 1 1
    ;;
  "endless_all")
    ./run.sh 0 0 "test_cases/cryring_injector.xml"
    ./run.sh 0 0 "test_cases/cryring_timing_test_ring.xml"
    ./run.sh 0 0 "test_cases/heartbeat.xml"
    ./run.sh 0 0 "test_cases/pLinacRF.xml"
    ./run.sh 0 0 "test_cases/ring.xml"
    ./run.sh 0 0 "test_cases/sourceLinac.xml"
    ./run.sh 0 0
    ;;
  "endless_cryring")
    ./run.sh 0 0 "test_cases/cryring_injector.xml"
    ;;
  "endless_unipz")
    ./run.sh 0 0 "test_cases/unipz.xml"
    ;;
  "endless_random")
    ./run.sh 0 0
    ;;
  "ping")
    ./run.sh 1 1 "test_cases/ping.xml"
    ;;
  "endless_ping")
    ./run.sh 0 0 "test_cases/ping.xml"
    ;;
  *)
    echo "You have failed to specify what to do correctly!"
    echo "Available test cases are:"
    echo "  - cryring"
    echo "  - endless_cryring"
    echo "  - all"
    echo "  - endless_all"
    echo "  - random"
    echo "  - endless_random"
    echo "  - ping"
    echo "  - endless_ping"
    exit 1
    ;;
esac
