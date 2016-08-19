#!/bin/bash

#This script is used to reset the Timing receivers by using the
#Energenie LAN controlled power socket. This power socket can be
#powered on and off remotely by using the IP address configured for it

FACILITY="testing"

HELP="$(basename "$0") [-h] [-f deployment target] -- script to check device active status

where:
    -h  show this help text
    -f  where you want to deploy the bitstreams:
        prod (production)
        testing(default)
        cicd (continous integration)\n"

TEMP=`getopt -o hf: --long help,facility: -n 'dev_status.sh' -- "$@"`
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
DEV_LIST=device-list-$FACILITY.txt

wget $DEVICE/$DEV_LIST -O ./$DEV_LIST

#Temporary files that will be deleted after the reset operation
list=./$DEV_LIST
temp=./temp.txt

function pinging(){
while IFS=$'\t' read -r -a devArray
do
        for i in {devArray[2]}
        do
		sudo eb-info udp/${devArray[2]}
               	if [ $? == 0 ]; then
                        echo -e "\e[34mDevice ${devArray[0]} Active"
			echo -e "\e[32m"
                else
                        echo -e "\e[31mDevice ${devArray[0]} not available"
			echo -e "\e[31mReset operation will be performed on ${devArray[0]}"
			echo -e "\e[32m"
			. ./fpga_reset.sh ${devArray[0]} ${devArray[2]}
                fi
       done
done < $temp
}

function pcreboot(){

echo -e "\e[96mEnter the user and IPC name to halt the IPC, before performing power cycle"
echo -e "\e[33mEnter the USERNAME for IPC connected to PCIe devices (ex:timing/gsi)"
read username
user=$username
echo -e "\e[33mEnter the IPC name (ex:tsl0xx)"
read pcname
pc=$pcname
echo -e "\e[91mPCIe cards are connected to IPC. $pc going to HALT"
ssh -t -t $user@$pc.acc.gsi.de 'sudo shutdown -r now'

if [ $? != 0 ]; then
        echo -e "\e[91mInvalid username. Check the format."
        exit 1
else
        sleep 30
fi
}

echo -e "\e[96mEnter the keyword of device name to check the status"
echo -e "\e[33mAccepted keyword is exp,pex,vet,scu,dm,all"

read keyword

if [ "$keyword" == "exp" ] || [ "$keyword" == "all" ]; then
	grep -ie "exploder" $list > $temp
        	pinging
fi

if [ "$keyword" == "pex" ] || [ "$keyword" == "all" ]; then
        grep -ie "pexarria" $list > $temp
                pinging
		pcreboot
fi

if [ "$keyword" == "vet" ] || [ "$keyword" == "all" ]; then
        grep -ie "vetar" $list > $temp
                pinging
fi

if [ "$keyword" == "scu" ] || [ "$keyword" == "all" ]; then
        grep -ie "scu" $list > $temp
                pinging
fi

if [ "$keyword" == "dm" ] || [ "$keyword" == "all" ]; then
        grep -ie "datamaster" $list > $temp
                pinging
fi

rm $list $temp
