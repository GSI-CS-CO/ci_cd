#!/bin/bash

# Timing closure scanner
#
# Search of the critical timing warnings and the worst-case slack values in
# existing Quartus timing report files. The search is done for the given branch
# of bel_projects and its result is stored in a log file,
# timing_closure_scanner.log.

# ==============================================================================
# Important for Jenkins
#
# In order to avoid Jenkins to mark build as failure on non-zero return of any
# command in this script, use either shabang explicitly or set +e.
#
# Configurations
# General:
# - Restrict where this project can be run
# --> Label Expression = quartus
# Build Environment
# - Delete workspace before build starts (checked)
# Build
# - Execute shell
# --> Command = this script (copy & paste)
# Post-build Actions
# - Archive the artifacts
# --> Files to archive = timing_closure_scanner.log
# - Editable Email Notification
# --> Project Recipient List = your email address
# --> Attachments = timing_closure_scanner.log
# --> Advanced Settings... -> Triggers = Always (Send To = Recipient List)

# ==============================================================================
# Job Settings (User Settings)
export CFG_QUARTUS_VERSION=16 # 16 or 18
export CFG_BRANCH=doomsday # doomsday, master, ...
export CFG_TARGET=scu3 # scu2, scu3, vetar2a, vetar2a-ee-butis, exploder5, pexarria5, microtca, pmc

# ==============================================================================
# Environmental Settings (Don't Edit This Area!)
export QUARTUS_ROOTDIR=/opt/quartus/$CFG_QUARTUS_VERSION/quartus
export QUARTUS=$QUARTUS_ROOTDIR
export QUARTUS_64BIT=1
export PATH=$PATH:$QUARTUS
export CHECKOUT_NAME=bel_projects

# ==============================================================================
# Application specific variables and functions
export BEL_PRJ_URL=https://github.com/GSI-CS-CO/bel_projects.git
export BEL_PRJ_GIT_DIR=${BEL_PRJ_URL##*/}
export BEL_PRJ_DIR=${BEL_PRJ_GIT_DIR%%.*}
export QRTS_TIMING_RPT_FILE_EXT="*.sta.rpt"    # Quartus timing report file extention
export QRTS_SETTINGS_FILE_EXT="*.qsf"          # Quartus project settings file extension
export PATTRN_CRITICAL_WARNING="^Critical\sWarning.*Timing\srequirements\snot\smet"
export PATTRN_WORST_SLACK="^Info.*Worst-case.*slack\sis\s"
export PATTRN_SEED_ASSIGNMENT="set_global_assignment\s-name\sSEED\s"
export CURR_DIR=$(pwd)
export MY_LOG_FILE="${CURR_DIR}/timing_closure_scanner.log" # job log file

function appendLog {
  tee -a $MY_LOG_FILE
}

function sumSlacks { # $1 variable with slacks, $2 sum of slacks
  local slacks=$1
  local result=$2
  local sum=0

  while IFS= read -r line
  do
    slack=$(echo $line | grep -oe "[[:digit:]]\+\.[[:digit:]]\+")
    [[ ! -z $slack ]] && sum=$(echo $sum + $slack | bc)
  done <<< "$slacks"

  if [[ "$result" ]]; then
    eval $result="'$sum'"
  else
    echo "$sum"
  fi
}

# ==============================================================================
# Main
echo "Timing closure scanner for a branch/tag: $CFG_BRANCH" > $MY_LOG_FILE
echo -e "Timing closure scanner started: $(date)\n" | appendLog

cd $WORKSPACE && cd ..
TOP_WS_DIR=$(pwd)

# get the list of timing report files
RPT_FILES=$(find . -name $QRTS_TIMING_RPT_FILE_EXT)

# Iterate over Quartus timing report files
while IFS= read -r file
do
  if [ ! -z $file ]; then

    # get directory path of an absolute filepath
    SYN_DIR=$(dirname ${file##./})

    if [ -d $SYN_DIR ]; then

      # get directory path including bel project directory
      PRJ_DIR=$(echo $SYN_DIR | grep -oe "^.*$BEL_PRJ_DIR")

      # catch next entry if directory does not exist
      [[ ! -d $PRJ_DIR ]] && continue

      # get the actual branch name
      cd $PRJ_DIR
      GIT_BRANCH=$(git symbolic-ref --short HEAD)
      [[ -z "$GIT_BRANCH" ]] && echo "Sorry, something went wrong in $PRJ_DIR. Cancel!" | appendLog && continue

      # get git hash of the project
      GIT_HASH=$(git log --oneline | head -1 | cut -d" " -f1)
      [[ -z "$GIT_HASH" ]] && echo "Sorry, cannot get git hash in $PRJ_DIR. Cancel!" | appendLog && continue

      cd -

      # scan directories only with the selected repo branch
      if [ "$GIT_BRANCH" = "$CFG_BRANCH" ]; then

	SYN_PATH=$TOP_WS_DIR/$SYN_DIR

	# locate Quartus timing report file
	if [ -f $SYN_PATH/$QRTS_TIMING_RPT_FILE_EXT ]; then
	  QRTS_TIMING_RPT_FILEPATH=$(ls $SYN_PATH/$QRTS_TIMING_RPT_FILE_EXT)
	else
	  echo "Quartus timing report file is not found in $SYN_PATH. Cancel!" | appendLog && continue
	fi

	echo | appendLog
	echo "Analysing: $QRTS_TIMING_RPT_FILEPATH" | appendLog
	echo "Repo hash:  $GIT_HASH" | appendLog
	echo "Repo branch: $CFG_BRANCH" | appendLog

	# look for Quartus configuration file with seed setting
	if [ -f $SYN_PATH/$QRTS_SETTINGS_FILE_EXT ]; then

	  QRTS_SETTINGS_FILE_PATH=$(ls $SYN_PATH/$QRTS_SETTINGS_FILE_EXT)

	  # get the current seed value
	  ACT_SEED_VAL=$(grep -s -e "$PATTRN_SEED_ASSIGNMENT" $QRTS_SETTINGS_FILE_PATH | sed "s/$PATTRN_SEED_ASSIGNMENT//g")
	  echo "Seed: $ACT_SEED_VAL" | appendLog
	else
	  echo "Quartus settings file is not found in $SYN_PATH. Cancel!" | appendLog && continue
	fi

	# scan critical timing messages in report file
	WORST_SLACKS=$(grep -s -e "$PATTRN_WORST_SLACK" $QRTS_TIMING_RPT_FILEPATH)
	echo "$WORST_SLACKS" | appendLog
	echo | appendLog

	CRITICAL_WARNINGS=$(grep -Em1 "$PATTRN_CRITICAL_WARNING" $QRTS_TIMING_RPT_FILEPATH)

	if [ "$CRITICAL_WARNINGS" != "" ]; then

	  echo "-- Seed \"$ACT_SEED_VAL\" -- $CRITICAL_WARNINGS" | appendLog  # echo CRITICAL_WARNINGS cannot preserve new lines
	  NEGATIVE_SLACKS=$(grep -s -e "$PATTRN_WORST_SLACK-" $QRTS_TIMING_RPT_FILEPATH)
	  echo "$NEGATIVE_SLACKS" | appendLog
	else

	  SLACK_VALUES=$(echo "$WORST_SLACKS" | sed "s/$PATTRN_WORST_SLACK//g")
	  sum=$(sumSlacks "$SLACK_VALUES")
	  echo "++ Seed \"$ACT_SEED_VAL\" (slack sum = $sum)" | appendLog
	fi

	echo | appendLog

      fi
    fi
  fi

done <<< "$RPT_FILES"

echo -e "Timing closure scanner completed: $(date)\n" | appendLog
