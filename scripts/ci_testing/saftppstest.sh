#!/bin/bash

#This script is used to generate PPS signal on Pexarria and SCU3.
#The signals from Network switch, Pexarria and SCU3 are read on exploder 
#to calculate the time difference between network switch and the devices.

#Sourcing the configuration file available in the current working directory
source ./saftppsconfig.sh

#Wiping all the existing configuration on exploder and pexarria
saft-io-ctl exp -w
saft-io-ctl pex -w

#Making ports IO1, IO2 and IO3 as inputs by passing the parameter for 
#output terminal as 0 and input termination as 1
saft-io-ctl exp -n IO1 -o 0 -t 1
saft-io-ctl exp -n IO2 -o 0 -t 1
saft-io-ctl exp -n IO3 -o 0 -t 1

#Generating PPS signal on pexarria and writing the data to log file
saft-pps-gen pex -s > $pex_IO1_log1 &

#Reading the PPS data on all configured ports of exploder and writing the data to temporary log file
saft-io-ctl exp -s > $exp_IO1_log1 &

#Wiping all the existing configuration on.
#Generating PPS signal on SCU3 and killing the process after a delay
ssh root@scuxl0097.acc.gsi.de '
saft-io-ctl baseboard -w
saft-pps-gen baseboard -s &
sleep 60

echo $!
kill $!
exit'

#Finding the process ID for saft-io-ctl process and killing all the 
#processes bearing this name
for pid in `ps -ef | grep [s]aft-io-ctl | awk '{print $2}'` ; do 
echo $pid ;
kill $pid ; 
done

#Finding the process ID for saft-pps-gen process and killing all the 
#processes bearing this name
for pid in `ps -ef | grep [s]aft-pps-gen | awk '{print $2}'` ; do
echo $pid ;
kill $pid ;
done

#Counting the number of lines in temporary log file
exp_IO1_count=$(wc -l < $exp_IO1_log1)

#If a minimum of 60 lines are available in the temporary log file, then data acquired
#is sufficient to calculate the time difference. To reduce the size of the file, all 
#the lines after 403 are deleted. This is an arbitrary number.
if [ "$exp_IO1_count" -ge "60" ]; then
        echo "Count reached required limit";
	sed '403,$d' $exp_IO1_log1 > $exp_IO1_log
#Deleting the temporary file after storing the required data in exploder log file
	rm $exp_IO1_log1
fi

#Deleting intermediate log file used for pexarria data storage 
rm $pex_IO1_log1
