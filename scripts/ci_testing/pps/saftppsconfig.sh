#!/bin/bash
set -e
#This is the configuration file used by PPS generation scripts

#Temporary log file
dev1_log1=./dev1_log1.log

#Log file created after PPS signals are read on the exploder from other devices
dev1_log=./dev1_log.log

#Log file created during PPS signal generation on Pexarria
dev2_log1=./dev2_log1.log

#Intermediate files that will be deleted
dev1temp1=./dev1temp1.log1
dev1temp2=./dev1temp2.log2

#Email address to send error information
#Add addresses by giving a space between each email address
mail="a.suresh@gsi.de"

#Maximum acceptable difference in time
maxdiff=200

#Waiting time for the pps signal generation
sleep_time=60

#Number of lines from the output of pps signal generation to be considered for time difference calculation
line_num=403

#Case statement to check if any configuration is passed as an argument
if [ "$1" != "" ]; then
	case "$1" in
#Configuration when exploder is considered as the reference device in the argument passed
		exp_config)
#Reference port for time difference calculation
			ref1=IO1
#Available ports for exploder as the reference device
			ref=( IO1 IO2 IO3 IO4 IO5 IO6 IO7 IO8 )
#Devices connected to exploder in the same order as the ports
			dev=( NW_SW PEX SCU3 No_Dev No_Dev No_Dev No_Dev No_Dev )
		;;

#Configuration when pexarria is considered as the reference device in the argument passed
		pex_config)
#Reference port for time difference calculation
			ref1=IO1
#Available ports for pexarria as the reference device
                        ref=( IO1 IO2 IO3 )
#Devices connected to pexarria in the same order as the ports
                        dev=( NW_SW EXP SCU3 )
		;;

		*) echo -e "\e[31mInternal error! Check argument" ; exit 1 ;;
	esac
else
	echo -e "\e[31mNo configuration was passed as argument. Pass an argument before running the script"
	echo -e "\e[31mAccepted arguments are exp_config pex_config"
	exit 1
fi
