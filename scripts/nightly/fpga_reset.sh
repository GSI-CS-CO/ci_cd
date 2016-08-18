#!/bin/bash

##This script resets the SCU by writing DEADBEEF to the FPGA_Reset address

FACILITY="testing"

HELP="$(basename "$0") [-h] [-f deployment target] -- script to reset timing devices

where:
    -h  show this help text
    -f  where you want to perform reset operation:
        prod (production)
        testing(default)
        cicd (continous integration)
Note: Pass device_name and IP address as arguments to reset individual device\n"

TEMP=`getopt -o hf: --long help,facility: -n 'fpga_reset.sh' -- "$@"`
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

DEV=http://tsl002.acc.gsi.de/releases
LIST=device-list-$FACILITY.txt
wget $DEV/$LIST -O ./$LIST

reset_list=./$LIST
reset_temp=./reset_temp.txt

function reset(){
while IFS=$'\t' read -r -a devArray
do
        for i in {devArray[2]}
        do
                reset_add=$(sudo eb-find udp/${devArray[2]} 0x0000000000000651 0x3a362063)
                echo -e "\e[92mRESET address= $reset_add for ${devArray[0]} having IP ${devArray[2]}"
                sudo eb-write udp/${devArray[2]} $reset_add/4 0xDEADBEEF
                if [ $? == 0 ]; then
                        echo -e "\e[34mReset complete"
                else
                        echo -e "\e[31mCould not perform eb-write to Reset device"
                fi
       done
done < $reset_temp
}

if [ $# == 2 ]; then
        reset_add=$(eb-find udp/$2 0x0000000000000651 0x3a362063)
        echo "RESET address= $reset_add for $1 having IP $2"
        sudo eb-write dev/$2 $reset_add/4 0xDEADBEEF
	if [ $? == 0 ]; then
        	echo -e "\e[34mReset complete"
	else
		echo -e "\e[31mCould not perform eb-write to Reset device"
	fi

elif [ $# == 0 ]; then

	if [ "$keyword" == "scu" ] || [ "$keyword" == "all" ]; then
		grep -ie "scu" $reset_list > $reset_temp
		reset
	fi

	if [ "$keyword" == "pex" ] || [ "$keyword" == "all" ]; then
        	grep -ie "pexarria" $reset_list > $reset_temp
        	reset
	fi

	if [ "$keyword" == "exp" ] || [ "$keyword" == "all" ]; then
                grep -ie "exploder" $reset_list > $reset_temp
                reset
        fi

	if [ "$keyword" == "vme" ] || [ "$keyword" == "all" ]; then
                grep -ie "vetar" $reset_list > $reset_temp
                reset
        fi

	if [ "$keyword" == "dm" ] || [ "$keyword" == "all" ]; then
                grep -ie "datamaster" $reset_list > $reset_temp
                reset
        fi
rm $reset_list $reset_temp
else
	echo -e "\e[31mPass argument on command line as device_name device_IP or do not pass any argument"
fi
