#!/bin/bash

#This script is used to reset the Timing receivers by using the
#Energenie LAN controlled power socket. This power socket can be
#powered on and off remotely by using the IP address configured for it

FACILITY="testing"

HELP="$(basename "$0") [-h] [-f deployment target] -- script to reset Timing Receivers


where:
    -h  show this help text
    -f  Timing receivers in which facility you want to reset:
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

function pchalt(){

echo -e "\e[33mEnter the USERNAME for IPC connected to PCIe devices (ex:timing/gsi)"
read username
user=$username
echo -e "\e[33mEnter the IPC name (ex:tsl0xx)"
read pcname
pc=$pcname
echo -e "\e[91mPCIe cards are connected to IPC. $pc going to HALT"
ssh -t -t $user@$pc.acc.gsi.de 'sudo halt'
sleep 30
}


#Get the power socket list from the web server
RST_DEVICE=http://tsl002.acc.gsi.de/config_files
RST_DEV_LIST=egctl-power-socket-list-$FACILITY.txt
script_path=../../scripts/nightly
egctl_path=../../tools/egctl/

cd $egctl_path
sudo cp egtab /etc
make

wget $RST_DEVICE/$RST_DEV_LIST -O ./$RST_DEV_LIST

#Temporary files that will be deleted after the reset operation
rst_list=./$RST_DEV_LIST
rst_temp=./rst_temp.txt

function pwr_cycle(){
while IFS=$'\t' read -r -a pwrArray 
do
	for i in {pwrArray[0]}
        do
        	echo -e "\e[91mPowering OFF all $keyword connected to ${pwrArray[0]} on Socket ${pwrArray[1]}"
		case ${pwrArray[1]} in
		
		1)
                	./egctl ${pwrArray[0]} off left left left
		;;

		2)
                        ./egctl ${pwrArray[0]} left off left left
                ;;

		3)
                        ./egctl ${pwrArray[0]} left left off left
                ;;

		4)
                        ./egctl ${pwrArray[0]} left left left off
                ;;
		esac

                echo
                sleep 3
                echo -e "\e[92mPowering ON all $keyword connected to ${pwrArray[0]} on Socket ${pwrArray[1]}"

		case ${pwrArray[1]} in

                1)
                        ./egctl ${pwrArray[0]} on left left left
                ;;

                2)
                        ./egctl ${pwrArray[0]} left on left left
                ;;

                3)
                       ./egctl ${pwrArray[0]} left left on left
                ;;

                4)
                        ./egctl ${pwrArray[0]} left left left on
                ;;
		
		esac
                echo
        done
done < $rst_temp

}

if [ "$GLOBAL_VAR" == "1" ]; then
	keyword=$keyword
else
	echo -e "\e[96mEnter the keyword of devices to reset"
	echo -e "\e[33mAccepted keyword is exp,pex,vet,scu,sw,all"
	read keyword
#keyword will be used by fpga_reset.sh script. Therefore, exporting the parameter keyword
	export keyword
fi
#Power cycle all the exploders connected to the power socket

if [ "$keyword" == "exp" ]; then
	grep -ie "EXP" $rst_list > $rst_temp
	pwr_cycle
fi

#Power cycle the VME Crate connected to the power socket
if [ "$keyword" == "vet" ]; then
        grep -ie "VME" $rst_list > $rst_temp
	pwr_cycle
fi

#PCIe is connected to the IPC tsl011. Therefore, the PC will be put to HALT
#using ssh command first and then the power socket will be turned off and on
if [ "$keyword" == "pex" ]; then
	cd $script_path
	pchalt
	cd $egctl_path
	grep -ie "PCI" $rst_list > $rst_temp
	pwr_cycle
fi

#Power cycle all the network switches connected to the power socket
if [ "$keyword" == "sw" ]; then
	grep -ie "NW" $rst_list > $rst_temp
	pwr_cycle
fi

#Power cycle all the SCU connected to the power socket
if [ "$keyword" == "scu" ]; then
	cd $script_path
	. ./fpga_reset.sh
	cd $egctl_path

	grep -ie "SCU" $rst_list > $rst_temp
	pwr_cycle
fi

#Power cycle all the devices at once
if [ "$keyword" == "all" ]; then
	cd $script_path
	. ./fpga_reset.sh
	pchalt
	cd $egctl_path

	awk '{ print $1 }' $rst_list > interm.txt
	sort interm.txt | uniq -d > $rst_temp
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
	done < $rst_temp
fi
rm $rst_list $rst_temp
cd $script_path
