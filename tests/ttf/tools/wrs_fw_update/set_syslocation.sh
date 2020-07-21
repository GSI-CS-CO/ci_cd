#!/bin/bash

# Script: set_syslocation.sh
# Author: Enkhbold Ochirsuren, GSI Helmholtz Centre for Heavy Ion Research GmbH
# Date:   March 9, 2020

# Description: This script is used to set 'sysLocation' OID of a WR switch.

# Usage: ./set_syslocation.sh location file_with_switch_names user@proxy

source helpers.sh

OID_KEY='.1.3.6.1.2.1.1.6.0'
OID_VAL='TTF BG2.009'  # default sysLocation
N_USER_ARGUMENTS=3     # number of expected user arguments

# Check command line arguments
usage() {
  echo "Usage: $0 location file_with_switch_names user@proxy"
  echo "where:"
  echo "  location                 - text description"
  echo "  file_with_switch_names   - file with a list of switches"
  echo "  user                     - user of the timing group"
  echo "  proxy                    - proxy host, ie., timing management host"
  echo
  echo "example: $0 'loc A' switches.conf user@server.acc"
  echo
}

# Check command line arguments
if [ $# -ne $N_USER_ARGUMENTS ]; then
  usage
  exit 1
fi

# Parse user arguments
OID_VAL=$1
SWITCHES_DOT_CONF=$2
PROXY_LOGIN=$3

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

# Command prototypes
SSH_TO_PROXY="sshpass -p $proxy_user_passwd ssh -n $PROXY_LOGIN"

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
  REMOTE_CMD="snmpset -c private -v 2c $REMOTE_WRS $OID_KEY s '$OID_VAL'"
  $SSH_TO_PROXY $REMOTE_CMD
  exit_if_failed $? " FAIL: failed to invoke $REMOTE_CMD"
  echo " PASS: configured $REMOTE_WRS"

  echo

done < "$SWITCHES_DOT_CONF"
