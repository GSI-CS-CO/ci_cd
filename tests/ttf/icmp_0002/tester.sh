#!/bin/bash

# Local settings
log_folder=icmp_test_log
log_extension=log
wait_for_each_pid=1
verbose=0

# Load test settings
source $(find . -name "test_configuration.sh")

# clean up
rm -f $(pwd)/$log_folder/*.$log_extension
mkdir $(pwd)/$log_folder

pids=()
pid_status=()
test_failed=0
cnt=0
sub_id=0
sub_id_text="0"
all_pids_finished=0

# start processes
for i in "${devices[@]}"
do
   ping -c ${count[${cnt}]} -i ${interval[${cnt}]} -s ${size[${cnt}]} "$i" | tee -a "$(pwd)/"$log_folder/$i"_$sub_id_text.$log_extension" &
   pids+=("$!")
   pid_status+=0
   cnt=$cnt+1
   sub_id=$sub_id+1
   sub_id_text="$((sub_id))"
done

# wait until every command was executed
echo "Found $sub_id_text subprocess..."
if [ $wait_for_each_pid -eq 0 ]; then
  for pid in "${pids[@]}"
  do
    echo "Waiting for PID $pid..."
    wait $pid
  done
else
  wait
fi

# analyze log files
echo ""
echo "*******************************************************************************"
echo "*********************************** Results ***********************************"
echo "*******************************************************************************"
echo ""

sub_id=0
sub_id_text="0"
for i in "${devices[@]}"
do
  echo "$i statistics:"
  cat "$(pwd)/"$log_folder/$i"_$sub_id_text.$log_extension" | grep " 0% packet loss"
  retVal=$?
  if [ $retVal -ne 0 ]; then
    echo "Error: Device $i failed!"
    cat "$(pwd)/"$log_folder/$i"_$sub_id_text.$log_extension" | grep "packet loss"
    test_failed=1
  fi
  sub_id=$sub_id+1
  sub_id_text="$((sub_id))"
done

# store log files in case of failure
if [ $test_failed -ne 0 ]; then
  echo "Error: Test failed for one or more device(s)!"
  folder=$(date +%Y%m%d_%H%M%S)
  cd $(pwd)/$log_folder
  mkdir $(pwd)/$folder
  cd ..
  cp $(pwd)/$log_folder/*.$log_extension $(pwd)/$log_folder/$folder
else
  echo ""
  echo "Info: Test succeeded for all devices!"
fi

# finish and return test status
exit $test_failed
