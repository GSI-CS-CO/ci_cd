#!/bin/bash

#This script is used to reset the Timing receivers by using the
#Energenie LAN controlled power socket. This power socket can be
#powered on and off remotely by using the IP address configured for it

GLOBAL_VAR1=1
GLOBAL_VAR2=1
export GLOBAL_VAR1
export GLOBAL_VAR2
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
DEVICE=http://tsl002.acc.gsi.de/config_files
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
			. ./reset.sh -f $FACILITY
			sleep 5
			sudo eb-info udp/${devArray[2]}
			if [ $? != 0 ]; then
				GLOBAL_VAR2=0
			else
				GLOBAL_VAR2=1
			fi
                fi
       done
done < $temp
}

echo -e "\e[96mEnter the keyword of device name to check the status"
echo -e "\e[33mAccepted keyword is exp,pex,vet,scu,dm,all"

read keyword
export keyword

if [ "$keyword" == "exp" ] || [ "$keyword" == "all" ]; then
	grep -ie "exploder" $list > $temp
        	pinging
fi

if [ "$keyword" == "pex" ] || [ "$keyword" == "all" ]; then
        grep -ie "pexarria" $list > $temp
                pinging
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

GLOBAL_VAR1=0
rm $list $temp
