#!/bin/bash

# Get all ttf devices
source ../probe_0001/devices.sh

# Data master settings
schedule="pps.xml"
schedule_ts="pps_ts.xml"
dm_schedule_keyword="___STARTTIME___"
dm_start_offset=0x00000000050000000
dm_start_time=0x0
period=1000000000

# Start or stop data master
function control_data_master()
{
  if [ $1 -ne 0 ]; then
    echo "Starting data master..."
    # Copy old schedule
    cp "$schedule" "log/$schedule"
    cp "log/$schedule" "log/$schedule_ts"
    # Get time from ECA
    dm_time=`ftm-ctl $ttf_data_master -t | grep "ECA TIME" | cut -c 32-49`
    dm_time="$(($dm_time+0))" # To dec
    dm_start_time="$(($dm_time+$dm_start_offset))" # Add offset
    dm_start_time="$(((dm_start_time+period+period-1)/period*period))" # Round up to the next second
    echo $dm_start_time > log/start_time.txt
    # Get right start time in the schedule
    sed -i "s/$dm_schedule_keyword/$dm_start_time/g" "log/$schedule_ts"
    ftm-ctl $ttf_data_master -c $ttf_data_master_pps_core_id stop
    ftm-ctl $ttf_data_master -c $ttf_data_master_pps_core_id preptime 500000
    ftm-ctl $ttf_data_master -c $ttf_data_master_pps_core_id put log/$schedule_ts
    ftm-ctl $ttf_data_master -c $ttf_data_master_pps_core_id swap
    ftm-ctl $ttf_data_master -c $ttf_data_master_pps_core_id run
  else
    echo "Stopping date master..."
    ftm-ctl $ttf_data_master -c $ttf_data_master_pps_core_id idle
    ftm-ctl $ttf_data_master -c $ttf_data_master_pps_core_id stop
  fi
  echo "Done!"
}

# Start or saft-pps-gen
function configure_pps()
{
  pex_id=0
  for i in ${ttf_pexaria_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saft-pps-gen... ($i@${ttf_pexaria_hosts[$pex_id]})"
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pex_id]}.$tff_postfix "killall saft-pps-gen" > /dev/null 2>&1
    else
      echo "Starting saft-pps-gen... ($i@${ttf_pexaria_hosts[$pex_id]})"
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pex_id]}.$tff_postfix "nohup saft-pps-gen $i -s -e -v" > /dev/null &
    fi
    pex_id=$((pex_id+1))
  done
  # SCUs
  scu_id=0
  for i in ${ttf_scu_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saft-pps-gen... ($i@${ttf_scu_hosts[$scu_id]})"
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "killall saft-pps-gen" > /dev/null 2>&1
    else
      echo "Starting saft-pps-gen... ($i@${ttf_scu_hosts[$scu_id]})"
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "nohup saft-pps-gen $ttf_default_saft_dev -s -e -v" > /dev/null &
    fi
    scu_id=$((scu_id+1))
  done
  # Vetars
  vetar_id=0
  for i in ${ttf_vetar_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saft-pps-gen... ($i@${ttf_vetar_hosts[$vetar_id]})"
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "killall saft-pps-gen" > /dev/null 2>&1
    else
      echo "Starting saft-pps-gen... ($i@${ttf_vetar_hosts[$vetar_id]})"
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "nohup saft-pps-gen $ttf_default_saft_dev -s -e -v" > /dev/null &
    fi
    vetar_id=$((vetar_id+1))
  done
  # Exploders
  exploder_id=0
  for i in ${ttf_exploder_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saft-pps-gen... ($i@${ttf_exploder_hosts[$exploder_id]})"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "killall saft-pps-gen" > /dev/null 2>&1
    else
      echo "Starting saft-pps-gen... ($i@${ttf_exploder_hosts[$exploder_id]})"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "nohup saft-pps-gen $ttf_default_saft_dev -s -e -v" > /dev/null &
    fi
    exploder_id=$((exploder_id+1))
  done
}

# Perform setup or control data master
case "$1" in
  "start")
    control_data_master 1
    ;;
  "stop")
    control_data_master 0
    ;;
  "init")
    configure_pps 1
    ;;
  "deinit")
    configure_pps 0
    ;;
  *)
    echo "You have failed to specify what to do correctly!"
    echo "Possible arguments are: stop/start/init/deinit"
    echo "  start:  start data master"
    echo "  stop:   stop date master"
    echo "  init:   initialize all devices and start saft-pps-gen in external mode"
    echo "  deinit: deinitialize all devices and stop saft-pps-gen"
    exit 1
    ;;
esac
