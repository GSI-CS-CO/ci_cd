#!/bin/bash

##This script resets the SCU by writing DEADBEEF to the FPGA_Reset address
if [ $# != 2 ]; then

	echo -e "\e[31mPass argument on command line as scu_name scu_IP"
else
	reset_add=$(eb-find udp/$2 0x0000000000000651 0x3a362063)
	#reset_add=$(eb-find dev/$2 0x0000000000000651 0x3a362063)
        echo "RESET address= $reset_add for $1 having IP $2"
	sudo eb-write dev/$2 $reset_add/4 0xDEADBEEF
	echo -e "\e[34mReset complete"
fi
