#!/bin/bash

# Script: set_sysobjectid.sh
# Author: Enkhbold Ochirsuren, GSI Helmholtz Centre for Heavy Ion Research GmbH
# Date:   March 9, 2020

# Description: This script sets 'sysObjectID' for WR switches.

# Usage: ./set_sysobjectid.sh file_with_switch_names user@proxy

source helpers.sh

OID_KEY='sysObjectID'                         # SNMP OID key
OID_VAL='.1.3.6.1.4.1.96.100.1000.1'          # SNMP OID value
PATH_TO_SNMP_CONF_IN='/wr/etc/snmpd.conf.in'  # path to snmpd.conf.in file
N_USER_ARGUMENTS=2                            # number of expected user arguments

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

  # Check if sysObjectID is already specified in snmpd.conf.in file
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" \
    ssh $SSH_OPTIONS root@$REMOTE_WRS \
    \"grep -q '$OID_KEY' $PATH_TO_SNMP_CONF_IN || echo \"$OID_KEY $OID_VAL\" >> $PATH_TO_SNMP_CONF_IN\""
  $SSH_TO_PROXY $REMOTE_CMD
  exit_if_failed $? " FAIL: failed to invoke $REMOTE_CMD"
  echo " PASS: configured $PATH_TO_SNMP_CONF_IN in $REMOTE_WRS"

  # Show file content
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" \
    ssh $SSH_OPTIONS root@$REMOTE_WRS \"grep '$OID_KEY' $PATH_TO_SNMP_CONF_IN\""
  $SSH_TO_PROXY $REMOTE_CMD

  # Reboot the target WR switch after copying the firmware image
  REMOTE_CMD="sshpass -p \"$wrs_root_passwd\" \
    ssh $SSH_OPTIONS root@$REMOTE_WRS \"/sbin/reboot\""
  $SSH_TO_PROXY $REMOTE_CMD
  exit_if_failed $? " FAIL: failed to invoke $REMOTE_CMD"
  echo " PASS: $REMOTE_WRS is going to reboot!"

  echo

done < "$SWITCHES_DOT_CONF"
