#!/bin/bash

# Script: repair.sh
# Author: Enkhbold Ochirsuren, GSI Helmholtz Centre for Heavy Ion Research GmbH
# Date:   March 2, 2020

# Description: This script includes workaround to be done after updating
# the WR switches with firmware v6.0 (v5.0.1-365-geae79292).
# IMPORTANT:
# - this script must be invoked after firmware update and initial reboot
# - workaround does not work for the WR switch type WRS-FL/18

# What are done:
# - provided 'dot-config' file is copied to to the '/wr/etc/' directory in WR switches
# - existing '/update/tx_phase_cal.conf' file is deleted
# - and finally the target switch is rebooted

# Usage: ./repair.sh file_with_switch_names user@proxy

source helpers.sh

DOT_CONFIG='dot-config'         # WRS config file
PATH_TO_CONFIG='/wr/etc'        # path to dot-config
PATH_TO_CAL_CONF='/update/tx_phase_cal.conf'  # path to calibration config
N_USER_ARGUMENTS=2                            # number of expected user arguments

# Check if valid dot-config exits
if [ ! -e $DOT_CONFIG ]; then
  echo "Error: $DOT_CONFIG is not found"
  exit 2
fi

# Check command line arguments
usage() {
  echo "Usage: $0 file_with_switch_names user@proxy"
  echo "where:"
  echo "  file_with_switch_names   - file with a list of switches"
  echo "  user                     - user of the timing group"
  echo "  proxy                    - proxy host, ie., timing management host"
}

# Check command line arguments
if [ $# -ne $N_USER_ARGUMENTS ]; then
  usage
  exit 1
fi

# Parse user arguments
SWITCHES_DOT_CONF=$1
PROXY_LOGIN=$2

# Check if a given file exists
if [ ! -e $SWITCHES_DOT_CONF ]; then
  echo "Required '$SWITCHES_DOT_CONF' file is not available!"
  exit 2
fi

# Print a list of target WR switches and ask user intention
echo "INFO: WR switches to be repaired:"
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

# Copy the local dot-config file to the proxy server
sshpass -p "$proxy_user_passwd" scp "$DOT_CONFIG" "$PROXY_LOGIN:."
exit_if_failed $? " FAIL: failed to copy $DOT_CONFIG to $PROXY_LOGIN"
echo " PASS: copied $DOT_CONFIG to $PROXY_LOGIN"

# Command prototypes
SSH_TO_PROXY="sshpass -p $proxy_user_passwd ssh -n $PROXY_LOGIN"
PROXY_CMD="sshpass -p \"$wrs_root_passwd\" ssh root@$REMOTE_WRS \"${REMOTE_CMD}\""
SSH_OPTIONS="-o StrictHostKeyChecking=no" # disable SSH host key checking

# Update all WR switches specified in SWITCHES_DOT_CONF file
while IFS= read -r line; do

  # Get name of a target WR switch from the provided conf file
  REMOTE_WRS=$line

  # Names started with '#' are ignored
  if [ "${REMOTE_WRS:0:1}" == "#" ]; then
    echo "Ignore ${REMOTE_WRS:1}"
    continue
  fi

  # Copy the dot-config file from the proxy server to the target WR switch
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" \
    scp $SSH_OPTIONS $DOT_CONFIG root@${REMOTE_WRS}:${PATH_TO_CONFIG}/${DOT_CONFIG}"
  $SSH_TO_PROXY $REMOTE_CMD
  exit_if_failed $? " FAIL: failed to invoke $REMOTE_CMD"
  echo " PASS: copied $DOT_CONFIG file to $REMOTE_WRS"

  # Remove a calibration configuration file from a target WR switch
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" \
    ssh $SSH_OPTIONS root@$REMOTE_WRS \"rm -f ${PATH_TO_CAL_CONF}\""
  $SSH_TO_PROXY $REMOTE_CMD
  exit_if_failed $? " FAIL: failed to invoke $REMOTE_CMD"
  echo " PASS: $PATH_TO_CAL_CONF in $REMOTE_WRS has been deleted!"

  # Show directory content
  #REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" ssh $SSH_OPTIONS root@$REMOTE_WRS \"ls /update\""
  #$SSH_TO_PROXY $REMOTE_CMD

  # Reboot the target WR switch after copying the firmware image
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" \
    ssh $SSH_OPTIONS root@$REMOTE_WRS \"/sbin/reboot\""
  $SSH_TO_PROXY $REMOTE_CMD
  exit_if_failed $? " FAIL: failed to invoke $REMOTE_CMD"
  echo " PASS: $REMOTE_WRS is going to reboot!"

  echo

done < "$SWITCHES_DOT_CONF"
