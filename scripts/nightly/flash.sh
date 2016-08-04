#!/bin/bash

OPT="web"

HELP="$(basename "$0") [-h] [-w directory] [-l directory] [-f deployment target] -- script to flash Timing Receivers


where:
    -h  show this help text
    -l  if you want to flash the TR from a local bitstreams
    -w  if you want to flash the TR from remote files in the Nightly Web Server
    -f  where you want to deploy the bitstreams:
	pro (production)
	test(default)
	coci (continous integration)"

while getopts 'hl:w:f:' option; do
  case "$option" in
    h) echo "$HELP"
       exit 1
       ;;
    l) DIR="$OPTARG"
       OPT="local"
       ;;    
    w) DIR="$OPTARG"
       OPT="web"
       ;;
    \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$HELP" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))


if [ -z "$DIR" ]; then
        NIGHTLY=./nightly_files
        mkdir $NIGHTLY
	echo -e "\e[33mDefault directory $NIGHTLY"
else
        NIGHTLY="$DIR"
        mkdir $NIGHTLY
	echo -e "\e[33mUser defined directory $NIGHTLY"
fi

WEB_SERVER=http://tsl002.acc.gsi.de/releases/nightly/gateware
DEV_LIST=device-list-$FACILITY.txt

if [ "$OPT" = "web" ]; then
    	wget $WEB_SERVER/$DEV_LIST -O $NIGHTLY/$DEV_LIST
    	wget $WEB_SERVER/exploder5_csco_tr.rpd -O $NIGHTLY/exploder5_csco_tr.rpd
    	wget $WEB_SERVER/pci_control.rpd -O $NIGHTLY/pci_control.rpd
    	wget $WEB_SERVER/vetar2a.rpd -O $NIGHTLY/vetar2a.rpd
    	wget $WEB_SERVER/scu_control3.rpd -O $NIGHTLY/scu_control3.rpd
    	wget $WEB_SERVER/scu_control2.rpd -O $NIGHTLY/scu_control2.rpd
    	wget $WEB_SERVER/ftm.rpd -O $NIGHTLY/ftm.rpd
else 
    	wget $WEB_SERVER/$DEV_LIST  -O $NIGHTLY/$DEV_LIST
	echo "download"
fi

list=$NIGHTLY/$DEV_LIST
temp=$NIGHTLY/tmp.txt

echo -e "\e[96mEnter the keyword of device name to flash"
echo -e "\e[33mAccepted keyword is exp,pex,vet,scu2,scu3,dm,all"

read input 

if [ "$input" == "exp" ] || [ "$input" == "all" ]; then
	#Search for keyword exploder in the device list and store the value to a text file
	grep -ie "exploder" $list > $temp

	#Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
		for i in {nightlyArray[2]}
		do
#			sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/exploder5_csco_tr.rpd
			echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest exploder5_csco_tr.rpd gateware"
			echo
		done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing exploder" 
fi
	
if [ "$input" == "pex" ] || [ "$input" == "all" ]; then
	#Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "pexarria" $list > $temp

	##Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
	       	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/pci_control.rpd
                	echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest pci_control.rpd gateware"
	                echo
        	done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing pexarria" 
fi

if [ "$input" == "vet" ] || [ "$input" == "all" ]; then
	#Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "vetar" $list > $temp

	##Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
#	    	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/vetar2a.rpd
                	echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest vetar2a.rpd gateware"
	                echo
        	done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing vetar" 
fi

if [ "$input" == "scu3" ] || [ "$input" == "all" ]; then
	##Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "scu3" $list > $temp

	##Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
 	  	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/scu_control3.rpd
                	echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest scu_control3.rpd gateware"
	                echo
	     	. ./scu_reset.sh ${nightlyArray[0]} ${nightlyArray[2]}
		done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing scu3" 
fi

if [ "$input" == "scu2" ] || [ "$input" == "all" ]; then
	##Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "scu2" $list > $temp

	##Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
	       	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/scu_control2.rpd
                	echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest scu_control2.rpd gateware"
	                echo
#		. ./scu_reset.sh ${nightlyArray[0]} ${nightlyArray[2]}
        	done
	done < $temp
else
        echo -e "\e[33mKeyword used is $input, not flashing scu2" 
fi

if [ "$input" == "dm" ] || [ "$input" == "all" ]; then
	##Search for keyword pexarria in the device list and store the value to a text file
	grep -ie "datamaster" $list > $temp

	##Create an array with the values from the text file created in previous step
	while IFS=$'\t' read -r -a nightlyArray
	do
        	for i in {nightlyArray[2]}
	        do
#	       	        sudo eb-flash udp/${nightlyArray[2]} $NIGHTLY/ftm.rpd
	                echo -e "\e[34m${nightlyArray[0]} with IP ${nightlyArray[2]} flashed with latest ftm.rpd gateware"
        	        echo
	        done

	done < $temp
else
	echo -e "\e[33mKeyword used is $input, not flashing datamaster" 
fi

if [ "$input" != "exp" ] && [ "$input" != "pex" ] && [ "$input" != "vet" ] && [ "$input" != "scu3" ] && [ "$input" != "scu2" ] && [ "$input" != "dm" ] && [ "$input" != "all" ]; then
	echo -e "\e[31mIncorrect keyword. Please try again"
fi

#rm $temp
#rm -rf $NIGHTLY
