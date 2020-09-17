#!/bin/bash

#
# Build the gateware and firmware images of the given bel_project branch
#

# ==============================================================================
# Important for Jenkins
#
# In order to disallow Jenkins to terminate build as failure if just one
# command fails, use either shabang explicitly or add "set +e" line.
# Otherwise, Jenkins build terminates with message:
#   Build step 'Execute shell' marked build as failure

# Jenkins configurations
#
# General:
# - Description
#    Build the target image of the specified bel_projects branch
#
#    Requires following user defined-axis:
#    - target       target timing receivers
#
# - Configuration Matrix
# --> User-defined Axis (Name = target, Default Values = scu3, exploder5, pexarria5)
# - Execute concurrent builds if necessary (checked)
# - Restrict where this project can be run
# --> Label Expression = quartus
#
# Build Environment:
# - Run Xvnc during build
# --> Create a dedicated Xauthority file per build?
#
# Build:
# - Execute shell
# --> Command = this script (copy & paste)
#
# Post-build Actions:
# - Archive the artifacts
# --> Files to archive = bel_projects/modules/burst_generator/burstgen.???, bel_projects/syn/**/*.rpd, bel_projects/syn/**/*.sof, bel_projects/syn/**/*.jic, bel_projects/syn/**/*.rpt, build.log

# ==============================================================================
# Job Settings (User Settings)
export CFG_QUARTUS_VERSION=18            # 18
export CFG_BRANCH=enigma_burst_generator # enigma_burst_generator, enigma, ...
export CFG_SAFT_BRANCH=burst-ctl         # burst-ctl, master, ...

export CFG_TARGET=$target                # user-defined axis in jenkins job

# ==============================================================================
# Environmental Settings (Don't Edit This Area!)
export QUARTUS_ROOTDIR=/opt/quartus/$CFG_QUARTUS_VERSION/quartus
export QUARTUS=$QUARTUS_ROOTDIR
export QUARTUS_64BIT=1
export PATH=$PATH:$QUARTUS
export CHECKOUT_NAME=bel_projects

# ==============================================================================
# Globals, functions
export bel_prj_url=https://github.com/GSI-CS-CO/bel_projects.git
export bel_prj_git_dir=${bel_prj_url##*/}
export bel_prj_dir=${bel_prj_git_dir%%.*}
export saft_prj_dir=ip_cores/saftlib
export qrts_timing_rpt_file_ext="*.sta.rpt"    # Quartus timing report file
export qrts_settings_file_ext="*.qsf"          # Quartus project settings file
export pattern_critical_warning="^Critical\sWarning.*Timing\srequirements\snot\smet"
export pattern_worst_slack="^Info.*Worst-case.*slack\sis\s"
export pattern_seed_assignment="set_global_assignment\s-name\sSEED\s"
export seed_string_assignment="set_global_assignment -name SEED"
export my_log_file="${WORKSPACE}/build.log"                 # job log file
export firmware_dir="modules/burst_generator"         # firmware directory

function appendLog {
  tee -a $my_log_file
}

# ==============================================================================
# Print parameters

echo "Build start: $(date)" > $my_log_file
echo "Parameters:" | appendLog
echo "- BEL branch     : $CFG_BRANCH" | appendLog
echo "- Saftlib branch : $CFG_SAFT_BRANCH" | appendLog
echo "- Targets        : $CFG_TARGET" | appendLog
echo "- Log file       : $my_log_file" | appendLog

# ==============================================================================
# Download project

# remove existing project directory
echo Check if $bel_prj_dir or $bel_prj_git_dir exists
[[ -d $bel_prj_dir ]] && rm -rf $bel_prj_dir

# fresh checkout of the project repo
echo "Downloading project $bel_prj_url" | appendLog

git clone $bel_prj_url

cd $bel_prj_dir

export bel_prj_path=$(pwd)

echo "Changed to the project location: $bel_prj_path" | appendLog

# ==============================================================================
# Check out desired branch and submodules

# check out the desired branch
git checkout $CFG_BRANCH
git pull

# check out submobules, install hdlmake 3.0
./autogen.sh

# get git hash of the project
bel_git_hash=$(git log --oneline | head -1 | cut -d" " -f1)
[[ "$bel_git_hash" = "" ]] &&
  echo Something went wrong. Cannot continue! | appendLog && exit 1

cd $saft_prj_dir
git checkout $CFG_SAFT_BRANCH
git pull

saft_git_hash=$(git log --oneline | head -1 | cut -d" " -f1)
[[ "$saft_git_hash" = "" ]] &&
  echo Something went wrong. Cannot continue! | appendLog && exit 1

# ==============================================================================
# Log info of project, tool and synthesis

echo "Quartus version : $CFG_QUARTUS_VERSION" | appendLog
echo "Bel repo branch : $CFG_BRANCH" | appendLog
echo "Bel repo hash   : $bel_git_hash" | appendLog
echo "Saft repo branch: $CFG_SAFT_BRANCH" | appendLog
echo "Saft repo hash  : $saft_git_hash" | appendLog

# back to the bel_projects directory
cd $WORKSPACE && cd $bel_prj_dir

# locate the synthesis artifacts directory
syn_dir=$(sed -n "/^${CFG_TARGET}:/,/^$/p" Makefile | sed -n '/MAKE/p' | cut -d" " -f3)
[[ $syn_dir = "" ]] &&
echo "$CFG_TARGET is not found in Makefile. Exit!" | appendLog && exit 1

export syn_path=$bel_prj_path/$syn_dir

echo "Synthesis location for $CFG_TARGET:  $syn_path" | appendLog

# ==============================================================================
# Prepare fitter seed sweeping

# look for Quartus configuration file with seed setting
qrts_settings_file_path=$(ls $syn_path/$qrts_settings_file_ext)

[[ ! -f $qrts_settings_file_path ]] &&
echo "Quartus settings file is not found. Exit!" | appendLog && exit 1

# ============================================================================
# Build target image

make $CFG_TARGET-clean
make $CFG_TARGET

if [ $? -eq 0 ]; then

  # ==========================================================================
  # Analyse timing closure and log results

  actual_seed=$(grep -s -e "$pattern_seed_assignment" $qrts_settings_file_path | sed "s/$pattern_seed_assignment//g")

  echo | appendLog
  echo -e "Fitter seed = $actual_seed\n" | appendLog

  # locate Quartus timing report file
  qrts_timing_rpt_file_path=$(ls $syn_path/$qrts_timing_rpt_file_ext)

  if [ -f $qrts_timing_rpt_file_path ]; then

    # re-name and back up the report file
    cp $qrts_timing_rpt_file_path $qrts_timing_rpt_file_path.$actual_seed

    echo "-- Analysing: $qrts_timing_rpt_file_path" | appendLog

    # scan critical timing messages in report file
    critical_warnings=$(grep -s -e "$pattern_critical_warning" $qrts_timing_rpt_file_path)

    if [ -n "$critical_warnings" ]; then
      echo "$critical_warnings" | appendLog  # echo critical_warnings cannot preserve new lines
      negative_slacks=$(grep -s -e "$pattern_worst_slack-" $qrts_timing_rpt_file_path)
      echo "$negative_slacks" | appendLog
      echo "Timing requirements cannot met!" | appendLog

    else
      positive_slacks=$(grep -s -e "$pattern_worst_slack" $qrts_timing_rpt_file_path)
      echo "$positive_slacks" | appendLog
      worst_slack_values=$(echo "$positive_slacks" | sed "s/$pattern_worst_slack//g")

      #sum=$(sumSlacks "$worst_slack_values")
      #echo "Slack sum = $sum (seed = $actual_seed)" | appendLog
      echo "Timing requirements were met. No critical path." | appendLog
    fi
  else

    echo "Quartus timing report file is not found in $syn_path. Ignore!" | appendLog
  fi

  echo | appendLog

else
  echo "Make $CFG_TARGET failed" | appendLog
fi

# export lm32-gcc path
source export-lm32-bin.sh

# build firmware
[[ -d $firmware_dir ]] && cd $firmware_dir && make

if [ $? -eq 0 ]; then
  echo "Succeeded to build a firmware image" | appendLog
else
  echo "Failed to build a firmware image" | appendLog
fi
