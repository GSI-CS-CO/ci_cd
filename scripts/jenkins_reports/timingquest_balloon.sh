#!/bin/bash
#This script is used to check if the timing analysis was carried out during the nightly build of gateware for different form factors
#Checked in the log file generated during the build process of gateware

#Variables
WEB_SRVR_PATH=/var/www/html/releases/
exp_log=balloon_build_exploder5.$(date +%Y-%m-%d).log
pex_log=balloon_build_pexarria5.$(date +%Y-%m-%d).log
vet_log=balloon_build_vetar2a.$(date +%Y-%m-%d).log
scu3_log=balloon_build_scu3.$(date +%Y-%m-%d).log
scu2_log=balloon_build_scu2.$(date +%Y-%m-%d).log
dm_log=balloon_build_ftm.$(date +%Y-%m-%d).log

cd $WEB_SRVR_PATH/log/balloon_makefile_log

#Check if time quest analysis for exploder5a was successful
if (grep -rqn $exp_log -e "Running Quartus Prime TimeQuest Timing Analyzer"); then
  if (grep -rqn $exp_log -e "Quartus Prime TimeQuest Timing Analyzer was successful"); then
    echo "Exploder5 TimeQuest Timing Analyzer was successful"
  else
    echo "Exploder5 TimeQuest Timing Analyzer was not successful"
  fi
else
  echo "Exploder5 TimeQuest Timing Analyzer not started or log file not found"
fi

#Check if time quest analysis for pexarria5 was successful
if (grep -rqn $pex_log -e "Running Quartus Prime TimeQuest Timing Analyzer"); then
  if (grep -rqn $pex_log -e "Quartus Prime TimeQuest Timing Analyzer was successful"); then
    echo "Pexarria5 TimeQuest Timing Analyzer was successful"
  else
    echo "Pexarria5 TimeQuest Timing Analyzer was not successful"
  fi
else
  echo "Pexarria5 TimeQuest Timing Analyzer not started or log file not found"
fi

#Check if time quest analysis for vetar2a was successful
if (grep -rqn $vet_log -e "Running Quartus Prime TimeQuest Timing Analyzer"); then
  if (grep -rqn $vet_log -e "Quartus Prime TimeQuest Timing Analyzer was successful"); then
    echo "Vetar2a TimeQuest Timing Analyzer was successful"
  else
    echo "Vetar2a TimeQuest Timing Analyzer was not successful"
  fi
else
  echo "Vetar2a TimeQuest Timing Analyzer not started or log file not found"
fi

#Check if time quest analysis for SCU3 was successful
if (grep -rqn $scu3_log -e "Running Quartus Prime TimeQuest Timing Analyzer"); then
  if (grep -rqn $scu3_log -e "Quartus Prime TimeQuest Timing Analyzer was successful"); then
    echo "SCU3 TimeQuest Timing Analyzer was successful"
  else
    echo "SCU3 TimeQuest Timing Analyzer was not successful"
  fi
else
  echo "SCU3 TimeQuest Timing Analyzer not started or log file not found"
fi

#Check if time quest analysis for SCU2 was successful
if (grep -rqn $scu2_log -e "Running Quartus Prime TimeQuest Timing Analyzer"); then
  if (grep -rqn $scu2_log -e "Quartus Prime TimeQuest Timing Analyzer was successful"); then
    echo "SCU2 TimeQuest Timing Analyzer was successful"
  else
    echo "SCU2 TimeQuest Timing Analyzer was not successful"
  fi
else
  echo "SCU2 TimeQuest Timing Analyzer not started or log file not found"
fi

#Check if time quest analysis for datamaster was successful
if (grep -rqn $dm_log -e "Running Quartus Prime TimeQuest Timing Analyzer"); then
  if (grep -rqn $dm_log -e "Quartus Prime TimeQuest Timing Analyzer was successful"); then
    echo "Datamaster TimeQuest Timing Analyzer was successful"
  else
    echo "Datamaster TimeQuest Timing Analyzer was not successful"
  fi
else
  echo "Datamaster TimeQuest Timing Analyzer not started or log file not found"
fi
