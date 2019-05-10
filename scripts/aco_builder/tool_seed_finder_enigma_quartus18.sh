#!/bin/bash

#
# Seed finder for bel_projects
#
# Do seed sweeping for the given repo branch/tag and target(s) of bel_projects.
# For each given target a certain number of syntheses are done (in parallel).
# On successful completion of each synthesis, its timing report file is scanned
# for the critical timing warnings and the worst-case slack values.
# The scan result is stored in in log file, seed_finder.log, and is sent per
# email to the given users.
#
# Seed sweep with more than 10 seed values is generally not required according
# to AN 584 [Timing Closure Methodology].
#

# ==============================================================================
# Important for Jenkins
#
# In order to disallow Jenkins to terminate build as failure if just one
# command fails, use either shabang explicitly or add "set +e" line.
# Otherwise, Jenkins build terminates with message:
#   Build step 'Execute shell' marked build as failure
#
# Configurations
# General:
# - Discard old builds
# --> Strategy = Log Rotation (Max # of builds to keep = 7)
# - Restrict where this project can be run
# --> Label Expression = quartus
# Build Environment
# - Run Xvnc during build
# --> Create a dedicated Xauthority file per build? (checked)
# Build
# - Execute shell
# --> Command = this script (copy & paste)
# Post-build Actions
# - Archive the artifacts
# --> Files to archive = seed_finder.log
# - Editable Email Notification
# --> Project Recipient List = your email address
# --> Attachments = seed_finder.log
# --> Advanced Settings... -> Triggers = Success (Send To = Recipient List)

# ==============================================================================
# Job Settings (User Settings)
export CFG_QUARTUS_VERSION=18 # 16 or 18
export CFG_BRANCH=enigma_quartus18 # doomsday, master, ...
export CFG_TARGET=scu3 # scu2, scu3, vetar2a, vetar2a-ee-butis, exploder5, pexarria5, microtca, pmc
export CFG_ALL_TARGETS=(scu2 scu3 vetar2a vetar2a-ee-butis exploder5 pexarria5 microtca pmc)
export CFG_MAIL_RECIEPENTS="developer@gsi.de"

# ==============================================================================
# Environmental Settings (Don't Edit This Area!)
export QUARTUS_ROOTDIR=/opt/quartus/$CFG_QUARTUS_VERSION/quartus
export QUARTUS=$QUARTUS_ROOTDIR
export QUARTUS_64BIT=1
export PATH=$PATH:$QUARTUS
export CHECKOUT_NAME=bel_projects

# ==============================================================================
# Globals, functions
export BEL_PRJ_URL=https://github.com/GSI-CS-CO/bel_projects.git
export BEL_PRJ_GIT_DIR=${BEL_PRJ_URL##*/}
export BEL_PRJ_DIR=${BEL_PRJ_GIT_DIR%%.*}
export QRTS_TIMING_RPT_FILE_EXT="*.sta.rpt"    # Quartus timing report file
export QRTS_SETTINGS_FILE_EXT="*.qsf"          # Quartus project settings file
export PATTRN_CRITICAL_WARNING="^Critical\sWarning.*Timing\srequirements\snot\smet"
export PATTRN_WORST_SLACK="^Info.*Worst-case.*slack\sis\s"
export PATTRN_SEED_ASSIGNMENT="set_global_assignment\s-name\sSEED\s"
export STR_SEED_ASSIGNMENT="set_global_assignment -name SEED"
export MAX_COUNT=5                             # total number of seed values
export SEED_RANGE=256                          # seed value range (0 < value <= range)
export CURR_DIR=$(pwd)
export MY_LOG_FILE="${CURR_DIR}/seed_finder.log"  # log file

function appendLog {
  tee -a $MY_LOG_FILE
}

# calculate sum of slacks, $1 - list of slack values, $2 - sum of slacks
function sumSlacks {
  local slacks=$1
  local result=$2
  local sum=0

  while IFS= read -r line
  do
    slack=$(echo $line | grep -oe "[[:digit:]]\+\.[[:digit:]]\+")
    [[ ! -z $slack ]] && sum=$(echo $sum + $slack | bc)
  done <<< "$slacks"

  if [ -z "$result" ]; then
    echo "$sum"
  else
    eval $result="'$sum'"
  fi
}

# build target with the given seed value
# $1 - build directory, $2 - seed value
function doBuildEvalLog {

  local BUILD_DIR="$1"
  local NEW_SEED_VAL=$2

  [[ ! -d "$BUILD_DIR" ]] && echo "$BUILD_DIR not exists. Ignore!" && return

  cd $BUILD_DIR

  local MY_LOG_FILE="$(pwd)/seed_finder.log"

  [[ ! -d "$BEL_PRJ_DIR" ]] && echo "$BEL_PRJ_DIR not exists. Ignore!" && return

  cd $BEL_PRJ_DIR
  echo > $MY_LOG_FILE

  # locate the synthesis artifacts directory
  local SYN_DIR=$(sed -n "/^${CFG_TARGET}:/,/^$/p" Makefile | sed -n '/MAKE/p' | cut -d" " -f3)

  [[ $SYN_DIR = "" ]] &&
    echo "$CFG_TARGET is not found in Makefile. Ignore!" >> $MY_LOG_FILE && return

  local SYN_PATH="$(pwd)/$SYN_DIR"

  echo "Synthesis location:  $SYN_PATH" >> $MY_LOG_FILE

  if [ -f $SYN_PATH/$QRTS_SETTINGS_FILE_EXT ]; then
    local QRTS_SETTINGS_FILE_PATH=$(ls $SYN_PATH/$QRTS_SETTINGS_FILE_EXT)
  else
    echo "Quartus settings file is not found. Ignore!" >> $MY_LOG_FILE && return
  fi

  # ============================================================================
  # Update fitter seed value

  # get the current seed value
  local SEEDS=$(grep -s -e "$PATTRN_SEED_ASSIGNMENT" $QRTS_SETTINGS_FILE_PATH)
  local ACT_SEED=$(echo $SEEDS | sed "s/$PATTRN_SEED_ASSIGNMENT//g")

  # set new seed value
  local NEW_SEED_ASSIGN="$STR_SEED_ASSIGNMENT $NEW_SEED_VAL"

  echo "Fitter seed: $NEW_SEED_VAL" >> $MY_LOG_FILE

  if [ "$SEEDS" == "" ]; then
    #echo "$STR_SEED_ASSIGNMENT is not set in $QRTS_SETTINGS_FILE_PATH." >> $MY_LOG_FILE

    # back up the existing file (only at first attempt)
    [[ ! -f $QRTS_SETTINGS_FILE_PATH.bak ]] && cp $QRTS_SETTINGS_FILE_PATH $QRTS_SETTINGS_FILE_PATH.bak

    # add seed settings
    echo -e "\n$NEW_SEED_ASSIGN" >> $QRTS_SETTINGS_FILE_PATH
    #echo -e "\"$NEW_SEED_ASSIGN\" is added in $QRTS_SETTINGS_FILE_PATH.\n" >> $MY_LOG_FILE

  else
    #echo "Actual seed value of $CFG_TARGET synthesis:  $ACT_SEED" >> $MY_LOG_FILE

    # back up the existing file (only at first replacement)
    [[ ! -f $QRTS_SETTINGS_FILE_PATH.bak ]] && cp $QRTS_SETTINGS_FILE_PATH $QRTS_SETTINGS_FILE_PATH.bak

    # replace existing seed value with the new value
    sed -i "s/$PATTRN_SEED_ASSIGNMENT.*$/$NEW_SEED_ASSIGN/g" $QRTS_SETTINGS_FILE_PATH
    #echo "New seed value of $CFG_TARGET synthesis: $NEW_SEED_VAL" >> $MY_LOG_FILE
  fi

  # ============================================================================
  # Build target

  make $CFG_TARGET-clean
  make $CFG_TARGET

  if [ $? -eq 0 ]; then

    # ==========================================================================
    # Analyse and log timing report

    ACT_SEED=$(grep -s -e "$PATTRN_SEED_ASSIGNMENT" $QRTS_SETTINGS_FILE_PATH | sed "s/$PATTRN_SEED_ASSIGNMENT//g")

    echo >> $MY_LOG_FILE

    # locate Quartus timing report file
    if [ ! -f $SYN_PATH/$QRTS_TIMING_RPT_FILE_EXT ]; then
      echo "Quartus timing report file is not found in $SYN_PATH." >> $MY_LOG_FILE

    else

      local QRTS_TIMING_RPT_FILEPATH=$(ls $SYN_PATH/$QRTS_TIMING_RPT_FILE_EXT)
      # re-name and back up the report file
      cp $QRTS_TIMING_RPT_FILEPATH $QRTS_TIMING_RPT_FILEPATH.$ACT_SEED

      echo "Analysing: $QRTS_TIMING_RPT_FILEPATH" >> $MY_LOG_FILE

      # scan critical timing messages in report file
      local WORST_SLACKS=$(grep -s -e "$PATTRN_WORST_SLACK" $QRTS_TIMING_RPT_FILEPATH)
      echo "$WORST_SLACKS" >> $MY_LOG_FILE

      local CRITICAL_WARNINGS=$(grep -Em1 "$PATTRN_CRITICAL_WARNING" $QRTS_TIMING_RPT_FILEPATH)

      if [ "$CRITICAL_WARNINGS" != "" ]; then
        echo >> $MY_LOG_FILE
        echo "-- Seed \"$ACT_SEED\" -- $CRITICAL_WARNINGS" >> $MY_LOG_FILE
        local NEGATIVE_SLACKS=$(grep -s -e "$PATTRN_WORST_SLACK-" $QRTS_TIMING_RPT_FILEPATH)
        echo "$NEGATIVE_SLACKS" >> $MY_LOG_FILE

      else
        local SLACK_VALUES=$(echo "$WORST_SLACKS" | sed "s/$PATTRN_WORST_SLACK//g")

        sum=$(sumSlacks "$SLACK_VALUES")
        echo "++ Seed \"$ACT_SEED\" can be used for Quartus Fitter (slack sum = $sum)" >> $MY_LOG_FILE
      fi

    fi

    echo >> $MY_LOG_FILE

  else
    echo "Make $CFG_TARGET failed" >> $MY_LOG_FILE
  fi

  # ============================================================================
  # Restore initial settings file

  [[ -f $QRTS_SETTINGS_FILE_PATH.bak ]] &&
    cp $QRTS_SETTINGS_FILE_PATH.bak $QRTS_SETTINGS_FILE_PATH && rm -f $QRTS_SETTINGS_FILE_PATH.bak

}

# ==============================================================================
# Log

echo "Seed finder: started $(date)" > $MY_LOG_FILE

# ==============================================================================
# Download project

# remove existing project directory
[[ -d $BEL_PRJ_DIR ]] && rm -rf $BEL_PRJ_DIR

# fresh checkout of the project repo
echo "Downloading project $BEL_PRJ_URL" | appendLog

git clone $BEL_PRJ_URL $BEL_PRJ_DIR

cd $BEL_PRJ_DIR

export BEL_PRJ_PATH="$(pwd)"

echo "Project location: $BEL_PRJ_PATH" | appendLog

# ==============================================================================
# Check out desired branch and submodules

# check out the desired branch
git checkout $CFG_BRANCH

# check out submobules, install hdlmake 3.0
./autogen.sh

# get git hash of the project
GIT_HASH=$(git log --oneline | head -1 | cut -d" " -f1)
[[ "$GIT_HASH" = "" ]] &&
  echo Something went wrong. Cannot continue! | appendLog && exit 1

# ==============================================================================
# Log info of project, tool and synthesis

echo "Quartus version: $CFG_QUARTUS_VERSION" | appendLog
echo "$(${QUARTUS_ROOTDIR}/bin/quartus_sh --version)" | appendLog
echo "Repo hash:  $GIT_HASH" | appendLog
echo "Repo branch: $CFG_BRANCH" | appendLog

# ==============================================================================
# Iteration over target list

for CFG_TARGET in ${CFG_ALL_TARGETS[@]}; do

  cd $BEL_PRJ_PATH

  # ============================================================================
  # Check the given target rule in Makefile and Quartus settings file

  # Locate synthesis directory for the given target
  SYN_DIR=$(sed -n "/^${CFG_TARGET}:/,/^$/p" Makefile | sed -n '/MAKE/p' | cut -d" " -f3)
  [[ $SYN_DIR = "" ]] &&
    echo "$CFG_TARGET is not found in Makefile. Ignore!" | appendLog && continue

  # look for Quartus configuration file with seed setting
  if [ ! -f $SYN_DIR/$QRTS_SETTINGS_FILE_EXT ]; then
    echo "Quartus settings file is not found. Ignore!" | appendLog && continue
  fi

  echo "=== Build target: $CFG_TARGET ===" | appendLog

  # ============================================================================
  # Make local copies of repo in build_? directories

  cd $CURR_DIR

  SUBSHELLS=""

  for i in `seq $MAX_COUNT`; do

    [[ -d "build_$i" ]] && rm -rf "build_$i"

    mkdir -p "build"_$i
    cp -r $BEL_PRJ_DIR "build_$i/"
    SEED=$(($RANDOM % $SEED_RANGE + 1))
    SUBSHELLS+="( doBuildEvalLog build_$i $SEED ) & "

  done

  # ============================================================================
  # Build target images and evaluate report logs

  SUBSHELLS+="( echo \"Running $MAX_COUNT builds\" | appendLog )"

  #echo $SUBSHELLS

  eval $SUBSHELLS

  wait

  # ============================================================================
  # Collect logs

  for i in `seq $MAX_COUNT`; do
    if [ -d "build_$i" ]; then
      [[ -f "build_${i}/seed_finder.log" ]] && cat "build_${i}/seed_finder.log" >> $MY_LOG_FILE
    fi
  done

done

echo "Seed finder: completed $(date)" | appendLog

# ==============================================================================
# Notify seed finder result per email
# Issue: Jenkins fails saying "an attempt to send an e-mail to empty list of recipients, ignored."
# Use Jenkins post-build action "Editable Email Notification" with the "Success" trigger option to send email.

# check if mail utility is installed and send email with log file attached
#[[ $(hash mail) ]] &&
  #  mail -s "Seed sweeping result - Quartus $CFG_QUARTUS_VERSION, $CFG_BRANCH" -a $MY_LOG_FILE $CFG_MAIL_RECIEPENTS <<< "Targets: $CFG_ALL_TARGETS"
