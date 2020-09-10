#!/bin/bash

# Script: deploy_firmware.sh
# Author: Enkhbold Ochirsuren, GSI Helmholtz Centre for Heavy Ion Research GmbH
# Date:   September 4, 2020

# Description: This script is used to install a firmware to the WR switches.

# Usage: ./deploy_firmware.sh firmware registry pattern reboot_option
# Real world example: ./deploy_firmware.sh wr-switch-sw-v6.0-20200612_binaries.tar allTimingDevices.txt production:access reboot
# Info: A registry file with switches must follow the format of allTimingDevices.txt

# Command options used in multihop/nested ssh access
# ssh -n                          -- prevents from reading stdin and redirects from /dev/null, use it if ssh is called within a while loop
# ssh -o StrictHostKeyChecking=no -- disable strict host key checking, avoids 'Host key verification failed' error

# Command options used in multihop scp action
# scp -o ProxyCommand="ssh $proxy_host nc $target 22" $file $target:$dest_path -- copies <file> to <target:dest_path> via <proxy_host>
# scp -o ProxyCommand="ssh user@tslDDD.acc nc nwtDDDmDD.timing 22" test.image root@$nwtDDDmDD.timing:/update/test.image

source helpers.sh

# Defaults
ACC_DOMAIN='.acc.gsi.de'                           # ACC domain
TIMING_DOMAIN='.timing'                            # Timing domain

PATH_TO_REMOTE_FW_IMG='/update/wrs-firmware.tar'   # path to remote fw image
PATH_TO_TX_PHASE_CAL_CONF='/update/tx_phase_cal.conf'    # path to tx_phase_cal.conf
LOG_FILE='deploy_firmware.log'

WRS_RECORD_PATH='/tmp/switches.txt'      # path for the temporary file with WRS devices to be configured (WRS device; WR network; WRS role)
PATT_WRS_NAME='(nwt[0-9]+m66)'           # name pattern used for the GSI WRSs
N_USER_ARGUMENTS=4                       # number of user arguments

SSH_OPTIONS="-n -o StrictHostKeyChecking=no" # disable SSH host key checking
SCP_OPTIONS="-o StrictHostKeyChecking=no" # disable SSH host key checking

usage() {
  echo "Usage: $0 firmware registry pattern reboot_option"
  echo "where:"
  echo "  firmware       - path to firmware"
  echo "  registry       - user file with the WR switches (eg ATD)"
  echo "  pattern        - match pattern for target (network:role:device)"
  echo "  reboot_option  - option to reboot target (reboot | no)"
  echo
  echo "Example: $0 wr-switch-sw-v6.0-20200612_binaries.tar allTimingDevices.txt timing:access reboot"
  echo "  flash all 'Access' WR switches in the 'Timing' network with wr-switch-sw-v6.0-20200612_binaries.tar"
  echo
}

register_networks_n_roles() {

# Register WR networks and WRS roles from input arguments.
# Registration is commited to WR_NETWORKS and WRS_ROLES arrays.

  WR_NETWORKS+=(${MATCH_PATTERN[0]})
  WRS_ROLES+=(${MATCH_PATTERN[1]})

  #echo -e "networks: ${WR_NETWORKS[@]} \nroles: ${WRS_ROLES[@]}"
}

get_net_role_dev() {

# Return an array with WR network, WRS role, WRS device name if a given string has them.
# Otherwise, return an empty string

# $1 - line with the names of device, network, role and other additional info
# eg, nwt0024m66 #NW Production;Access;WRS V3.3; BG.2.009 R56; CID 55 0035 0008

  local line=$(echo "$1" | tr '[:upper:]' '[:lower:]') # make string lower case
  local comment wrs_device wr_network wrs_role
  
  if [[ "$line" =~ $PATT_WRS_NAME ]]; then # device name match using regex

    # get the WRS device name
    wrs_device="${BASH_REMATCH[0]}"
    # pre-process the comment part to get the clean WR network and WR role values
    comment=${line#*\#nw} # remove substring (ending with '#NW') from the beginning of a line and
    comment=${comment/ /} # leading whitespace

    # get WR network and WRS role
    IFS=';' read -r -a name_array <<< "$comment" # split fields separated by ';', insert to 'name_array'

    if [ ${#name_array[@]} -gt 1 ]; then
      wr_network=${name_array[0]/ /} # WR network name
      wrs_role=${name_array[1]/ /} # WRS role
    fi
  fi

  # return WR network, WRS role, WRS device
  echo "$wr_network $wrs_role $wrs_device"
}

store_net_role_dev() {

# Store the chosen target WR network, WRS role and WRS device to a temporary file

# $1 - parsed target WR network, WRS role and WRS device

  local parsed_target=("$@")

  local parsed_wr_network=${parsed_target[0]}
  local parsed_wrs_role=${parsed_target[1]}
  local parsed_wrs_device=${parsed_target[2]}

  if [[ "${WR_NETWORKS[@]}" =~ $parsed_wr_network ]]; then
    if [[ "${WRS_ROLES[@]}" =~ $parsed_wrs_role ]]; then
      echo "$parsed_wrs_device;$parsed_wr_network;$parsed_wrs_role" >> $WRS_RECORD_PATH
    fi
  fi
}

record_wrs_devices () {

# Record the name of WRS devices along with assigned WR network and WRS role to
# a temporary file specified in WRS_RECORD_PATH.

# $1 - user file with WR switches, assigned WR network and WRS role (eg, allTimingDevices.txt)

  while IFS=',' read mac_addr id_name ip_addr device_n_comment; do

    if [[ "$mac_addr" =~ '^#' ]]; then
      continue    # lines started with '#' are ignored
    fi

    # get target WR network, WRS role and WRS device
    local parsed_target=($(get_net_role_dev "$device_n_comment"))

    # choose a target according to the given match pattern
    local matches=0
    if [ ${#parsed_target[@]} -ge 3 ]; then
      for idx in "${!MATCH_PATTERN[@]}"; do
        if [ "${parsed_target[idx]}" == "${MATCH_PATTERN[idx]}" ]; then
          matches=$((matches+1))
        fi
      done

      # store the matched target
      if [ $matches -eq ${#MATCH_PATTERN[@]} ]; then
        store_net_role_dev "${parsed_target[@]}"
      fi
    fi
  done < "$1"
}

echo_and_log() {
  echo "$1" | tee -a $LOG_FILE
}

### main stuff ###

# Check command line arguments
if [ $# -ne $N_USER_ARGUMENTS ]; then
  usage
  exit 1
fi

# Parse user arguments
PATH_TO_LOCAL_FW_IMG=$1
USER_SWITCHES_FILE=$2
FW_IMG_FILE=${PATH_TO_LOCAL_FW_IMG##*/}
# make input parameters lower case
# split the match pattern by ':', insert to array
IFS=':' read -r -a MATCH_PATTERN <<< $(echo "$3" | tr '[:upper:]' '[:lower:]')
IS_REBOOT_NEEDED=$(echo "$4" | tr '[:upper:]' '[:lower:]')

# Print provided arguments
#echo "INFO: USER_SWITCHES_FILE=$USER_SWITCHES_FILE"
#echo "INFO: PATH_TO_LOCAL_FW_IMG=$PATH_TO_LOCAL_FW_IMG"
#echo "INFO: MATCH_PATTERN=${MATCH_PATTERN[@]}"
#echo "INFO: IS_REBOOT_NEEDED=$IS_REBOOT_NEEDED"

# Check if an user file with WR switch names exists
[[ ! -e "$USER_SWITCHES_FILE" ]] && \
  echo "- FAIL: '$USER_SWITCHES_FILE' is not found. Exit!" && exit 2

# Check if the given firmware exits
if [ ! -e $PATH_TO_LOCAL_FW_IMG ]; then
  echo "Error: $PATH_TO_LOCAL_FW_IMG is not found"
  exit 2
fi

# Remove old record if it exists
[[ -e "$WRS_RECORD_PATH" ]] && rm -rf $WRS_RECORD_PATH

# Register WR networks and WRS roles from existing configurations
declare -a WR_NETWORKS=()   # array with WR networks (eg, 'prod' 'int')
declare -a WRS_ROLES=()     # array of WRS roles (eg, 'grand_master' 'service')

register_networks_n_roles

# Record the target WR switch from an user file with switches (eg, allTimingDevices.txt)
# according to given match pattern
record_wrs_devices "$USER_SWITCHES_FILE"

# Check if record file with switches exists
[[ ! -e "$WRS_RECORD_PATH" ]] && \
  echo "- FAIL: Target WRS not found. Exit!" && exit 2

# Print a list of target WR switches and ask user intention
echo "INFO: WR switches to be flashed:"

total_devices=0
while IFS= read -r line; do

  total_devices=$((total_devices+1))
  echo "$total_devices: $line"

done < "$WRS_RECORD_PATH"

# Make sure if user really flash them
echo "ARE YOU SURE TO FLASH ABOVE SWITCH(ES)? (y/n)"
read -r answer

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
  echo "User disagreed. Exit!"
  rm $WRS_RECORD_PATH
  exit 3
fi

# Prompt password for the root user
read -r -s -p "Password for root (WRS): " wrs_root_passwd
echo

# Update all WR switches
declare -a accessed_devices=()     # array with WRS names that is configured
declare -a not_accessed_devices=() # array with WRS names that could not be configured

# Log the deployment datetime
echo_and_log "$(date)"

while IFS=';' read -r WRS_NAME WR_NETWORK WRS_ROLE; do

  WRS_FULL_NAME=$WRS_NAME$TIMING_DOMAIN$ACC_DOMAIN # append domain

  # Try with the root passwd
  export SSHPASS=$wrs_root_passwd

  # Show uptime and actual SW version
  echo "Uptime and actual firmware version:"
  sshpass -e ssh $SSH_OPTIONS root@$WRS_FULL_NAME 'uptime && /wr/bin/wrs_version'
  if [ $? -ne 0 ]; then
    if [ "$wrs_root_passwd" == '' ]; then
      echo_and_log "- FAIL: could not access to $WRS_NAME"
      not_accessed_devices+=($WRS_NAME)
      continue
    else
      export SSHPASS='' # try again without root password
      sshpass -e ssh $SSH_OPTIONS root@$WRS_FULL_NAME 'uptime && /wr/bin/wrs_version'
      if [ $? -ne 0 ]; then
        echo_and_log "- FAIL: could not access to $WRS_NAME"
        not_accessed_devices+=($WRS_NAME)
        continue
      fi
    fi
  fi

  # Info before flashing WRSs
  echo_and_log "? flashing $WRS_NAME ($WR_NETWORK:$WRS_ROLE) with $FW_IMG_FILE"

  # Remove tx_phase_cal.conf file
  sshpass -e ssh $SSH_OPTIONS root@$WRS_FULL_NAME "ls -l $PATH_TO_TX_PHASE_CAL_CONF" &>/dev/null
  if [ $? -eq 0 ]; then
    sshpass -e ssh $SSH_OPTIONS root@$WRS_FULL_NAME "rm $PATH_TO_TX_PHASE_CAL_CONF"
    exit_if_failed $? " FAIL: failed to delete $PATH_TO_TX_PHASE_CAL_CONF"
  fi

  # Deploy the firmware image file to the target WR switch
  sshpass -e scp $SCP_OPTIONS $PATH_TO_LOCAL_FW_IMG root@${WRS_FULL_NAME}:${PATH_TO_REMOTE_FW_IMG}
  exit_if_failed $? " FAIL: failed to copy $FW_IMG_FILE to $WRS_NAME"
  echo_and_log " PASS: copied $FW_IMG_FILE image to $WRS_FULL_NAME"

  # Reboot the target WR switch after copying the firmware image
  if [ $IS_REBOOT_NEEDED == 'reboot' ]; then
    #echo "sshpass -e ssh $SSH_OPTIONS root@$WRS_FULL_NAME '/sbin/reboot'"
    sshpass -e ssh $SSH_OPTIONS root@$WRS_FULL_NAME '/sbin/reboot'
    exit_if_failed $? "- FAIL: failed to invoke user commands in $WRS_NAME"
    echo_and_log " PASS: rebooting $WRS_NAME!"
  fi

  # Remove old host key
  ssh-keygen -R $WRS_FULL_NAME &>/dev/null # full domain name
  result=$?
  ssh-keygen -R $WRS_NAME &>/dev/null      # host name only
  ((result&=$?))
  ssh-keygen -R ${WRS_FULL_NAME%$ACC_DOMAIN} &>/dev/null  # host name with the timing domain
  ((result&=$?))

  if [ $result -ne 0 ]; then
    echo_and_log "- FAIL: failed to remove old host key for $WRS_NAME"
  else
    echo_and_log " PASS: removed old host key for $WRS_NAME"
  fi

  # Record the name of WRS
  accessed_devices+=($WRS_NAME)

  echo

done < "$WRS_RECORD_PATH"

# Report the deployment result
if [ ${#not_accessed_devices[@]} -ne 0 ]; then
  echo_and_log "- RESULT: could not access ${#not_accessed_devices[@]} of $total_devices devices:"
  for device in ${not_accessed_devices[@]}; do
    echo_and_log $device
  done
fi

if [ ${#accessed_devices[@]} -ne 0 ]; then
  echo_and_log "+ RESULT: succeeded to access ${#accessed_devices[@]} of $total_devices devices:"
  for device in ${accessed_devices[@]}; do
    echo_and_log $device
  done
fi

# Remove existing record file
[[ -e "$WRS_RECORD_PATH" ]] && rm -rf $WRS_RECORD_PATH
