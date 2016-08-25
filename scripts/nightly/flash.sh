#!/bin/bash

OPT="web"
FACILITY="testing"
RELEASE="nightly"

HELP="$(basename "$0") [-h] [-w directory] [-l directory] [-f deployment target] [-r release] [-d device] -- script to flash Timing Receivers


where:
    -h  show this help text
    -l  if you want to flash the TR from a local bitstreams
    -w  if you want to flash the TR from remote files in the Nightly Web Server
    -f  where you want to deploy the bitstreams:
	prod (production)
	testing(default)
	cicd (continous integration)
    -r  which release bitstream you want to use
        balloon
	golden_image
	nightly(default)
    -d  which device you want to flash
	Use exp/pex/vet/scu2/scu3/dm/all as options\n"

TEMP=`getopt -o hl:w:f:r:d: --long help,local:,web:,facility:,release:,device: -n 'flash.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help) printf "$HELP"; shift; exit 1;;

        -l|--local)
            case "$2" in
                "") shift 2 ;;
                *) DIR=$2; OPT="local"; shift 2 ;;
            esac ;;
        -w|--web)
            case "$2" in
                "") shift 2 ;;
                *) DIR=$2; OPT="web"; shift 2 ;;
            esac ;;
        -f|--facility)
            case "$2" in
                "") shift 2 ;;
                *) FACILITY=$2; shift 2 ;;
            esac ;;
        -r|--release)
            case "$2" in
                "") shift 2 ;;
                *) RELEASE=$2; shift 2 ;;
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

if [ -z "$DIR" ]; then
        NIGHTLY=./nightly_files
	rm -rf $NIGHTLY
        mkdir $NIGHTLY
	echo -e "\e[33mDefault directory $NIGHTLY"
else
	if [ -d "$DIR" ]; then
        	NIGHTLY="$DIR"
		echo -e "\e[33mUser defined directory $NIGHTLY"
	else
		echo -e "\e[31mDirectory $DIR does not exist"
		exit 1
	fi
fi

WEB_SERVER=http://tsl002.acc.gsi.de/releases/$RELEASE/gateware
DEVICE=http://tsl002.acc.gsi.de/config_files
DEV_LIST=device-list-$FACILITY.txt
FLASH_LOG=/var/www/html/releases/devices_flashed.log
temp_log=./flash.log
log_seven_days=$(date --date="7 days ago" +%F)

if [ "$OPT" = "web" ]; then
    	wget $DEVICE/$DEV_LIST -O $NIGHTLY/$DEV_LIST
	if [ "$RELEASE" = "nightly" ] || [ "$RELEASE" = "golden_image" ];then
    		wget $WEB_SERVER/exploder5_csco_tr.rpd -O $NIGHTLY/exploder5_csco_tr.rpd
	    	wget $WEB_SERVER/pci_control.rpd -O $NIGHTLY/pci_control.rpd
    		wget $WEB_SERVER/vetar2a.rpd -O $NIGHTLY/vetar2a.rpd
	    	wget $WEB_SERVER/scu_control3.rpd -O $NIGHTLY/scu_control3.rpd
    		wget $WEB_SERVER/scu_control2.rpd -O $NIGHTLY/scu_control2.rpd
	    	wget $WEB_SERVER/ftm.rpd -O $NIGHTLY/ftm.rpd
	elif [ "$RELEASE" = "balloon" ];then
        	wget $WEB_SERVER/exploder5_csco_tr.$(date +%Y-%m-%d).rpd -O $NIGHTLY/exploder5_csco_tr.$(date +%Y-%m-%d).rpd
	        wget $WEB_SERVER/pci_control.$(date +%Y-%m-%d).rpd -O $NIGHTLY/pci_control.$(date +%Y-%m-%d).rpd
        	wget $WEB_SERVER/vetar2a.$(date +%Y-%m-%d).rpd -O $NIGHTLY/vetar2a.$(date +%Y-%m-%d).rpd
	        wget $WEB_SERVER/scu_control3.$(date +%Y-%m-%d).rpd -O $NIGHTLY/scu_control3.$(date +%Y-%m-%d).rpd
        	wget $WEB_SERVER/scu_control2.$(date +%Y-%m-%d).rpd -O $NIGHTLY/scu_control2.$(date +%Y-%m-%d).rpd
	        wget $WEB_SERVER/ftm.$(date +%Y-%m-%d).rpd -O $NIGHTLY/ftm.$(date +%Y-%m-%d).rpd
        fi

else 
    	wget $DEVICE/$DEV_LIST -O $NIGHTLY/$DEV_LIST
fi

#Function to create a log file of the devices flashed
function log_copy(){
inter_log=`cat $temp_log`
if [ "$(hostname)" == "tsl002" ]; then
	cat $temp_log >> $FLASH_LOG
else
	echo "$inter_log" | ssh timing@tsl002.acc.gsi.de "cat >> $FLASH_LOG"
fi
}

list=$NIGHTLY/$DEV_LIST
temp=$NIGHTLY/tmp.txt

if [ "$device_name" != ""  ]; then

input=$device_name

else

echo -e "\e[96mEnter the keyword of device name to flash"
echo -e "\e[33mAccepted keyword is exp,pex,vet,scu2,scu3,dm,all"

read input 

fi

if [ "$input" == "exp" ] || [ "$input" == "all" ]; then
	#Search for keyword exploder in the device list and store the value to a text file
	grep -ie "exploder" $list > $temp

	#Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
		for i in {nightlyArray[2]}
		do
			sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/exploder5_csco_tr.rpd
			if [ $? != 0 ]; then
				echo -e "\e[34mFlashing ${nightlyArray[0]} with IP ${nightlyArray[2]} was interrupted"
			else
				echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest exploder5_csco_tr.rpd gateware"
				echo
				echo "Device ${nightlyArray[0]} flashed using $RELEASE release on $(date +%F) at $(date +%T)" > $temp_log
				log_copy
			fi
		done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing exploder" 
fi
	
if [ "$input" == "pex" ] || [ "$input" == "all" ]; then
	#Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "pexarria" $list > $temp

	#Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
	       	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/pci_control.rpd
                	if [ $? != 0 ]; then
                                echo -e "\e[34mFlashing ${nightlyArray[0]} with IP ${nightlyArray[2]} was interrupted"
                        else
                                echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest pci_control.rpd gateware"
                                echo
				echo "Device ${nightlyArray[0]} flashed using $RELEASE release on $(date +%F) at $(date +%T)" > $temp_log
                                log_copy
                    fi
        	done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing pexarria" 
fi

if [ "$input" == "vet" ] || [ "$input" == "all" ]; then
	#Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "vetar" $list > $temp

	#Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
	    	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/vetar2a.rpd
			if [ $? != 0 ]; then
                                echo -e "\e[34mFlashing ${nightlyArray[0]} with IP ${nightlyArray[2]} was interrupted"
                        else
                                echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest vetar2a.rpd gateware"
                                echo
                                echo "Device ${nightlyArray[0]} flashed using $RELEASE release on $(date +%F) at $(date +%T)" > $temp_log
				log_copy
                     fi
        	done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing vetar" 
fi

if [ "$input" == "scu3" ] || [ "$input" == "all" ]; then
	#Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "scu3" $list > $temp

	#Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
 	  	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/scu_control3.rpd
			if [ $? != 0 ]; then
                                echo -e "\e[34mFlashing ${nightlyArray[0]} with IP ${nightlyArray[2]} was interrupted"
                        else
                                echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest scu_control3.rpd gateware"
                                echo
                                echo "Device ${nightlyArray[0]} flashed using $RELEASE release on $(date +%F) at $(date +%T)" > $temp_log
                                log_copy
                     fi
		done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing scu3" 
fi

if [ "$input" == "scu2" ] || [ "$input" == "all" ]; then
	#Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "scu2" $list > $temp

	#Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
	       	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/scu_control2.rpd
			if [ $? != 0 ]; then
                                echo -e "\e[34mFlashing ${nightlyArray[0]} with IP ${nightlyArray[2]} was interrupted"
                        else
                                echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest scu_control2.rpd gateware"
                                echo
                                echo "Device ${nightlyArray[0]} flashed using $RELEASE release on $(date +%F) at $(date +%T)" > $temp_log
                                log_copy
                     fi
        	done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing scu2" 
fi

if [ "$input" == "dm" ] || [ "$input" == "all" ]; then
	#Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "datamaster" $list > $temp

	#Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
	       	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/ftm.rpd
			if [ $? != 0 ]; then
                                echo -e "\e[34mFlashing ${nightlyArray[0]} with IP ${nightlyArray[2]} was interrupted"
                        else
                                echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest ftm.rpd gateware"
                                echo
                                echo "Device ${nightlyArray[0]} flashed using $RELEASE release on $(date +%F) at $(date +%T)" > $temp_log
                                log_copy
                     fi
	        done
	done < $temp
else
	echo -e "\e[33mKeyword used is $input, not flashing datamaster" 
fi

if [ "$input" != "exp" ] && [ "$input" != "pex" ] && [ "$input" != "vet" ] && [ "$input" != "scu3" ] && [ "$input" != "scu2" ] && [ "$input" != "dm" ] && [ "$input" != "all" ]; then
	echo -e "\e[31mIncorrect keyword. Please try again"
fi

#Below lines are to limit the log data for 7 days.
#Devices flashed within 7 days will be logged. Data greater than this will be erased

LOG=http://tsl002.acc.gsi.de/releases/devices_flashed.log
LOG1=./flash1.log
wget $LOG -O $NIGHTLY/flash.log
grep -v "$log_seven_days" $NIGHTLY/flash.log > $LOG1
inter_log=`cat $LOG1`
if [ "$(hostname)" == "tsl002" ]; then
        cat $LOG1 > $FLASH_LOG
else
        echo "$inter_log" | ssh timing@tsl002.acc.gsi.de "cat > $FLASH_LOG"
fi

rm $temp_log $LOG1

if [ -z "$DIR" ]; then
        rm -rf $NIGHTLY
fi
