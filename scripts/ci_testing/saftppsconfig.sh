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

#Devices that are connected to the IO ports of Exploder5a_19t
#Network switch PPS signal port connected to IO1 of Exploder
#Difference in time is calculated with this signal as reference.
ref1="IO1"
device1="Network switch"

#Timing receiver connected to IO2 of Exploder
ref2="IO2"
device2="pexaria5_40t"

#Timing receiver connected to IO3 of Exploder
ref3="IO3"
device3="scuxl0097t"
