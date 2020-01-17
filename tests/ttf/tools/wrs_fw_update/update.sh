#!/bin/bash

# Script: update.sh
# Author: Enkhbold Ochirsuren, GSI Helmholtz Centre for Heavy Ion Research GmbH
# Date:   Jan 17, 2020

# Description: This script is used to update a firmware of the White Rabbit switches
# remotely via a proxy host (ie., timing management host)

# User must provide the firmware image binary and login to proxy host.
# A list of the target WR switches is derived from an external JSON file, which
# contains additional access information.

# Usage: ./update.sh <path_to_local_image> <user@proxy>
# Example: ./update.sh test_image.tar someone@tsl

# Command options used in multihop/nested ssh access
# ssh -n                          -- prevents from reading stdin and redirects from /dev/null, use it if ssh is called within a while loop
# ssh -o StrictHostKeyChecking=no -- disable strict host key checking, avoids 'Host key verification failed' error

# Command options used in multihop scp action
# scp -o ProxyCommand="ssh $proxy_host nc $target 22" $file $target:$dest_path -- copies <file> to <target:dest_path> via <proxy_host>
# scp -o ProxyCommand="ssh user@tslDDD.acc nc nwtDDDmDD.timing 22" test.image root@$nwtDDDmDD.timing:/update/test.image

# Defaults
PATH_TO_REMOTE_FW_IMG='/update/wrs-firmware.tar'   # path to remote fw image
SWITCHES_DOT_JSON='../../switches.json'     # file with WR switch access info
SWITCHES_DOT_CONF='switches.conf'           # file with WR switch names only
N_USER_ARGUMENTS=2                          # number of user arguments

# Function to evaluate command exit status
function eval_cmd_status {
  # $1 - command return value
  # $2 - output text in case of command failure

  if [ $1 -ne 0 ]; then
    echo $2
    exit $1
  fi
}

# Check if a file with WR switch names exists, otherwise create it from a default json file
if [ ! -e $SWITCHES_DOT_CONF ]; then
  echo "Required '$SWITCHES_DOT_CONF' file is not available!"
  echo "Create it by parsing '$SWITCHES_DOT_JSON' ..."
  python parse_json_file.py $SWITCHES_DOT_JSON
  eval_cmd_status $? "Failed: cannot parse '$SWITCHES_DOT_JSON'"
fi

# Check command line arguments
if [ $# -ne $N_USER_ARGUMENTS ]; then
  echo "Usage: $0 path_to_local_image user@proxy"
  echo "where:"
  echo "  path_to_local_image  - tarball firmware image"
  echo "  user                 - user of the timing group"
  echo "  proxy                - proxy host, ie., timing management host"
  exit 1
fi

# Parse user arguments
PATH_TO_LOCAL_FW_IMG=$1
FW_IMG_FILE=${PATH_TO_LOCAL_FW_IMG##*/}
PROXY_LOGIN=$2

# Print provided arguments
#echo "INFO: PATH_TO_LOCAL_FW_IMG=$PATH_TO_LOCAL_FW_IMG"
#echo "INFO: FW_IMG_FILE=$FW_IMG_FILE"
#echo "INFO: PROXY_LOGIN=$PROXY_LOGIN"

# Print a list of target WR switches and ask user intention
echo "INFO: WR switches to be updated:"
while IFS= read -r line; do

  REMOTE_WRS=$line
  echo $REMOTE_WRS

done < "$SWITCHES_DOT_CONF"

# Ask if user is sure to update them
echo "ARE YOU SURE TO UPDATE ABOVE SWITCH(ES)? (y/n)"
read -r answer

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
  echo "User disagreed. Exit!"
  exit 3
fi

# Prompt passwords for proxy and remote users
read -r -s -p "Password for $PROXY_LOGIN: " proxy_user_passwd
echo
read -r -s -p "Password for root (WRS): " wrs_root_passwd
echo

# Command prototypes
SSH_TO_PROXY="sshpass -p $proxy_user_passwd ssh -n $PROXY_LOGIN"
PROXY_CMD="sshpass -p \"$wrs_root_passwd\" ssh root@$REMOTE_WRS \"${REMOTE_CMD}\""

# Check if the given firmware exits
if [ ! -e $PATH_TO_LOCAL_FW_IMG ]; then
  echo "Error: $PATH_TO_LOCAL_FW_IMG is not found"
  exit 2
fi

# Copy the local firmware image file to the proxy server
sshpass -p "$proxy_user_passwd" scp "$PATH_TO_LOCAL_FW_IMG" "$PROXY_LOGIN:."
eval_cmd_status $? "Error: failed to copy $FW_IMG_FILE to $PROXY_LOGIN"
echo "PASS: copied $PATH_TO_LOCAL_FW_IMG to $PROXY_LOGIN"

# Update all WR switches specified in SWITCHES_DOT_CONF file
while IFS= read -r line; do

  # Get name of a target WR switch from the provided conf file
  REMOTE_WRS=$line

  # Copy the firmware image file from the proxy server to the target WR switch
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" scp -o StrictHostKeyChecking=no $FW_IMG_FILE root@${REMOTE_WRS}:${PATH_TO_REMOTE_FW_IMG}"
  $SSH_TO_PROXY "$REMOTE_CMD"
  eval_cmd_status $? "FAIL: failed to copy $FW_IMG_FILE to $REMOTE_WRS"
  echo "PASS: copied $FW_IMG_FILE firmware image to $REMOTE_WRS"

  # Reboot the target WR switch after copying the firmware image
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" ssh -o StrictHostKeyChecking=no root@$REMOTE_WRS \"/sbin/reboot\""
  $SSH_TO_PROXY "$REMOTE_CMD"
  eval_cmd_status $? "FAIL: failed to invoke user commands in $REMOTE_WRS"
  echo "PASS: $REMOTE_WRS is going to reboot for installing the firmware!"

  # Remove old host key
  REMOTE_CMD="ssh-keygen -R $REMOTE_WRS"
  $SSH_TO_PROXY "$REMOTE_CMD"
  eval_cmd_status $? "FAIL: failed to remove old host key for $REMOTE_WRS"
  echo "PASS: removed old host key for $REMOTE_WRS"

done < "$SWITCHES_DOT_CONF"
