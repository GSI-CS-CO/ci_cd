#!/bin/bash

# Predefined test cases
function fixed_test()
{
  # Pattern <frequeny Hz> <newline> <high phase ns> <low phase ns>
  timeout 2m ./run.sh 125
  timeout 2m ./run.sh 4000000 4000000
  timeout 2m ./run.sh 6000000 2000000
  timeout 2m ./run.sh 250
  timeout 2m ./run.sh 2000000 2000000
  timeout 2m ./run.sh 1000000 3000000
  timeout 2m ./run.sh 500
  timeout 2m ./run.sh 1000000 1000000
  timeout 2m ./run.sh 100 1999900
  timeout 2m ./run.sh 1000
  timeout 2m ./run.sh 500000 500000
  timeout 2m ./run.sh 999900 100
}

function short_test()
{
  echo "To be defined <random test>"
}

function long_test()
{
  echo "To be defined <random test>"
}

# Select test case
case "$1" in
  "fixed")
    fixed_test
    ;;
  "short")
    short_test
    ;;
  "long")
    long_test
    ;;
  *)
    echo "Please specify a test mode"
    echo "Available test modes are:"
    echo "  - fixed"
    echo "  - short"
    echo "  - long"
    exit 1
    ;;
esac
