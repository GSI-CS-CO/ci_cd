#!/bin/bash

#This script is used to reset the Timing receivers by using the
#Energenie LAN controlled power socket. This power socket can be
#powered on and off remotely by using the IP address configured for it

FACILITY="testing"

HELP="$(basename "$0") [-h] [-f deployment target] -- script to reset Timing Receivers


where:
    -h  show this help text
    -f  where you want to deploy the bitstreams:
        prod (production)
        testing(default)
        cicd (continous integration)\n"

TEMP=`getopt -o hf: --long help,facility: -n 'reset.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help) printf "$HELP"; shift; exit 1;;

        -f|--facility)
            case "$2" in
                "") shift 2 ;;
                *) FACILITY=$2; shift 2 ;;
            esac ;;
       --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

#Get the power socket list from the web server
DEVICE=http://tsl002.acc.gsi.de/releases
DEV_LIST=egctl-power-socket-list-$FACILITY.txt
script_path=../../scripts/nightly
egctl_path=../../tools/egctl/

cd $egctl_path
sudo cp egtab /etc
make

wget $DEVICE/$DEV_LIST -O ./$DEV_LIST

#Temporary files that will be deleted after the reset operation
list=./$DEV_LIST
temp=./temp.txt

echo -e "\e[96mEnter the keyword of devices to reset"
echo -e "\e[33mAccepted keyword is exp,pex,vet,scu,sw,all"

read keyword

#Power cycle all the exploders connected to the power socket
if [ "$keyword" == "exp" ]; then
	grep -ie "EXP" $list > $temp
	while IFS=$'\t' read -r -a pwrArray 
        do
                for i in {pwrArray[0]}
                do
			echo -e "\e[91mPowering OFF all exploder connected to ${pwrArray[0]} on ${pwrArray[1]}"
			./egctl ${pwrArray[0]} left off left left
			echo
			sleep 3
			echo -e "\e[92mPowering ON all exploder connected to ${pwrArray[0]} on ${pwrArray[1]}"
			./egctl ${pwrArray[0]} left on left left
			echo
                done
        done < $temp
fi

#Power cycle the VME Crate connected to the power socket
if [ "$keyword" == "vet" ]; then
        grep -ie "VME" $list > $temp
        while IFS=$'\t' read -r -a pwrArray 
        do
                for i in {pwrArray[0]}
                do
			echo -e "\e[91mPowering OFF VME Crate connected to ${pwrArray[0]} on ${pwrArray[1]}"
                        ./egctl ${pwrArray[0]} left left off left
			echo
                        sleep 3
			echo -e "\e[92mPowering ON VME Crate connected to ${pwrArray[0]} on ${pwrArray[1]}"
                        ./egctl ${pwrArray[0]} left left on left
                        echo
                done
        done < $temp
fi

#PCIe is connected to the IPC tsl011. Therefore, the PC will be put to HALT
#using ssh command first and then the power socket will be turned off and on
if [ "$keyword" == "pex" ]; then

echo -e "\e[96mEnter the user and IPC name to halt the IPC, before performing power cycle"
echo -e "\e[33mEnter the username"
read username
user=$username

echo -e "\e[33mEnter the PC name"
read pcname
pc=$pcname

	echo -e "\e[91mPCIe cards are connected to IPC. $pc going to HALT"
	ssh -t -t $user@$pc.acc.gsi.de 'sudo halt'
	if [ $? != 0 ]; then
		echo -e "\e[91mInvalid username. Check the format."
		exit 1
	else
		sleep 30
		grep -ie "PCI" $list > $temp
		while IFS=$'\t' read -r -a pwrArray 
	        do
        	        for i in {pwrArray[0]}
                	do                        
				echo -e "\e[91mPowering OFF PCIe cards connected to ${pwrArray[0]} on ${pwrArray[1]}"
	                        ./egctl ${pwrArray[0]} left off left left
        	                echo
                	        sleep 3
				echo -e "\e[92mPowering ON $username with PCIe cards connected to ${pwrArray[0]} on ${pwrArray[1]}"
	                        ./egctl ${pwrArray[0]} left on left left
        	                echo
                	done
	        done < $temp
	fi
fi

#Power cycle all the network switches connected to the power socket
if [ "$keyword" == "sw" ]; then
	grep -ie "NW" $list > $temp
        while IFS=$'\t' read -r -a pwrArray 
        do
                for i in {pwrArray[0]}
                do
			echo -e "\e[91mPowering OFF network switches connected to ${pwrArray[0]} on ${pwrArray[1]}"
                        ./egctl ${pwrArray[0]} off left left left
                        echo
                        sleep 3
			echo -e "\e[92mPowering ON network switches connected to ${pwrArray[0]} on ${pwrArray[1]}"
                        ./egctl ${pwrArray[0]} on left left left
                        echo
               done
        done < $temp
fi

#Power cycle all the SCU connected to the power socket
if [ "$keyword" == "scu" ]; then
	cd $script_path
	. ./scu_reset.sh
	cd $egctl_path

	grep -ie "SCU" $list > $temp
        while IFS=$'\t' read -r -a pwrArray 
        do
                for i in {pwrArray[0]}
                do
                        echo -e "\e[91mPowering OFF all the SCU connected to ${pwrArray[0]} on ${pwrArray[1]}"
                        ./egctl ${pwrArray[0]} off left left left
                        echo
                        sleep 3
                        echo -e "\e[92mPowering ON all the SCU connected to ${pwrArray[0]} on ${pwrArray[1]}"
                        ./egctl ${pwrArray[0]} on left left left
                        echo
                done
        done < $temp
fi

#Power cycle all the devices at once
if [ "$keyword" == "all" ]; then

echo -e "\e[96mEnter the user and IPC name to halt before performing power cycle"
echo -e "\e[33mEnter the username"
read username
user=$username

echo -e "\e[33mEnter the PC name"
read pcname
pc=$pcname

	echo -e "\e[91mIPC $pc going to HALT"
	ssh -t -t $user@$pc.acc.gsi.de 'sudo halt'
	if [ $? != 0 ]; then
                echo -e "\e[91mUsername or PC name incorrect. Please check and try again."
                exit 1
        else
		sleep 30
		echo -e "\e[91mAll SCUs will be reset"
		cd $script_path
		. ./scu_reset.sh
		cd $egctl_path
	
		awk '{ print $1 }' $list > interm.txt
		sort interm.txt | uniq -d > $temp
		rm interm.txt

		while IFS=$'\t' read -r -a pwrArray
		do
        	        for i in {pwrArray[0]}
                	do
				echo -e "\e[91mPowering OFF all devices in test facility connected to ${pwrArray[0]}"
				./egctl ${pwrArray[0]} off off off off
        	                echo
                	        sleep 3
                        	echo -e "\e[92mPowering ON all devices in test facility connected to ${pwrArray[0]}"
	                        ./egctl ${pwrArray[0]} on on on on
        	                echo
			done
		done < $temp
	fi
fi
rm $list $temp
