#!/bin/bash
#This script is to display the temperature reading of Altera-V FPGA device family (exploder5a and pexarria5)
#It converts the hexadecimal temperature reading from the temperature sensor on the device to corresponding temperature value in degC

FACILITY="testing"

HELP="$(basename "$0") [-h] [-f deployment target] [-d device] -- script to reset timing devices

where:
    -h  show this help text
    -f  where you want to perform reset operation:
        prod (production)
        testing(default)
        cicd (continous integration)
    -d  which device you want to flash
        Use exp/pex/all as options\n"

TEMP=`getopt -o hf:d: --long help,facility:,device: -n 'temp_val.sh' -- "$@"`
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
       -d|--device)
            case "$2" in
                "") shift 2 ;;
                *) device_name=$2; shift 2 ;;
            esac ;;
       --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

DEV=http://tsl002.acc.gsi.de/config_files
LIST=device-list-$FACILITY.txt
wget $DEV/$LIST -O ./$LIST

temp_val_list=./$LIST
temp_val_temp=./temp_val_temp.txt

#This function converts the hexadecimal temperature value to degC value
function tempval(){
while IFS=$'\t' read -r -a devArray
do
        for i in {devArray[2]}
        do
                temp_add=$(sudo eb-find udp/${devArray[2]} 0x0000000000000651 0x7E3D5E25)
                echo -e "\e[92mTEMP_SENS address= $temp_add for ${devArray[0]} having IP ${devArray[2]}"
                value=`sudo eb-read udp/${devArray[2]} $temp_add/4`
#Suppress 0 from the value
	        hex_val=`echo $value|sed 's/0*//'`
#Convert hexadecimal value to decimal value
	        dec_val=$((16#$hex_val))
	        declare -i const_val
        	const_val=128
#Based on the data sheet provided by Altera temperature sensor, decimal value must be
#subtracted by a constant value 128 to get the corresponding temperature value
	        temp_val=`expr $dec_val - $const_val`
	        if [ $hex_val != "deadc0de" ]; then
	                echo "$temp_val degC"
	        else
	                echo $hex_val
	        fi
      done
done < $temp_val_temp
}

#Keyword check
if [ "$device_name" != ""  ]; then
        keyword=$device_name
else
        echo -e "\e[96mEnter the keyword of devices to get the temperature reading"
        echo -e "\e[33mAccepted keyword is exp,pex,all"
        read keyword
fi

#Read temperature value of the exploders from the device list
if [ "$keyword" == "exp" ] || [ "$keyword" == "all" ]; then
        grep -ie "EXP" $temp_val_list > $temp_val_temp
	tempval
fi

#Read temperature value of the pexarria from the device list
if [ "$keyword" == "pex" ] || [ "$keyword" == "all" ]; then
        grep -ie "PEX" $temp_val_list > $temp_val_temp
        tempval
fi

#Remove temporary files
rm $temp_val_list $temp_val_temp

exit 0
