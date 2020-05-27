#!/bin/bash
# Local settings
log_folger=log
log_extension=log

# Load test settings
source $(find . -name "test_configuration.sh")

# clean up
rm -f *.$log_extension
pids=()
test_failed=0
cnt=0

# start processes
for i in "${devices[@]}"
do
   ping -c ${count[${cnt}]} -i ${interval[${cnt}]} "$i" | tee -a $i.$log_extension &
   pids+=("$!")
   cnt=$cnt+1
done

# wait until every command was executed
for pid in "${pids[@]}"
do
  echo "Waiting for PID $pid..."
  wait $pid
done

# analyze log files
echo "*******************************************************************************"
echo "*********************************** Results ***********************************"
echo "*******************************************************************************"
echo ""

for i in "${devices[@]}"
do
  echo "$i statistics:"
  cat $i.$log_extension | grep "0% packet loss"
  retVal=$?
  if [ $retVal -ne 0 ]; then
    echo "Error"
    test_failed=1
  fi
done

# store log files in case of failure
if [ $test_failed -ne 0 ]; then
  folder=$(date +%Y%m%d_%H%M%S)
  mkdir $log_folger/$folder
  cp *.$log_extension $log_folger/$folder
fi

# finish and return test status
exit $test_failed
