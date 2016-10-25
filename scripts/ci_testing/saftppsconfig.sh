#!/bin/bash

#This is the configuration file used by PPS generation scripts

#Temporary log file
exp_IO1_log1=./exp_IO1_log1.log

#Log file created after PPS signals are read on the exploder from other devices
exp_IO1_log=./exp_IO1_log.log

#Log file created during PPS signal generation on Pexarria
pex_IO1_log1=./pex_IO1_log1.log

#Intermediate files that will be deleted
expIOtemp1=./exp_IO1_log.log1
expIOtemp2=./exp_IO1_log.log2

#Network switch PPS signal port connected to IO1 of Exploder
#Difference in time is calculated with this signal as reference.
ref1="IO1"

#Available ports in Exploder5a_19t
ref=( IO1 IO2 IO3 IO4 IO5 IO6 IO7 IO8 )

#Devices that are connected to the IO ports of Exploder5a_19t
#in the order from port 1 to 8
dev=( Nw_switch pexaria5_40t scuxl0097t no_device no_device no_device no_device no_device )

#Email address to send error information
#Add addresses by giving a space between each email address
mail="a.suresh@gsi.de"
