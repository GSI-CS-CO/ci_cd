#!/bin/bash

##This script resets the SCU by writing DEADBEEF to the FPGA_Reset address

FACILITY="testing"

HELP="$(basename "$0") [-h] [-f deployment target] -- script to reset SCU


where:
    -h  show this help text
    -f  where you want to perform reset operation:
        prod (production)
        testing(default)
        cicd (continous integration)
Note: Pass SCU name and IP address as arguments to reset individual SCUs\n"

TEMP=`getopt -o hf: --long help,facility: -n 'scu_reset.sh' -- "$@"`
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

if [ $# == 2 ]; then
        reset_add=$(eb-find udp/$2 0x0000000000000651 0x3a362063)
        echo "RESET address= $reset_add for $1 having IP $2"
        sudo eb-write dev/$2 $reset_add/4 0xDEADBEEF
        echo -e "\e[34mReset complete"

elif [ $# == 0 ]; then

SCU_DEV=http://tsl002.acc.gsi.de/releases
SCU_LIST=device-list-$FACILITY.txt
wget $SCU_DEV/$SCU_LIST -O ./$SCU_LIST

scu_list=./$SCU_LIST
scu_temp=./scu_temp.txt

	grep -ie "scu" $scu_list > $scu_temp

	while IFS=$'\t' read -r -a scuArray
        	do
                	for i in {scuArray[2]}
                	do
				reset_add=$(eb-find udp/${scuArray[2]} 0x0000000000000651 0x3a362063)
				echo -e "\e[92mRESET address= $reset_add for ${scuArray[0]} having IP ${scuArray[2]}"
				sudo eb-write udp/${scuArray[2]} $reset_add/4 0xDEADBEEF
			        echo -e "\e[34mReset complete"
	                done
        	done < $scu_temp
else
	echo -e "\e[31mPass argument on command line as scu_name scu_IP or do not pass any argument"
fi
