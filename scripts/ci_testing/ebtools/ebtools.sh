#!/bin/bash

#This script is used to reset the Timing receivers by using the
#Energenie LAN controlled power socket. This power socket can be
#powered on and off remotely by using the IP address configured for it

CONNECTION="nw"
FACILITY="testing"

HELP="$(basename "$0") [-h] [-c connection device] [-f facility] [-u user] [-p pcname] [-t ttynumber] [-w wbmnumber] [-d device]-- script to check eb-tools


where:
    -h  show this help text
    -c  Timing receivers connected via which protocol for communication:
        nw (default: network)
        usb (USB connected to TR)
        pcie (PCI express connected to TR)
	vme (VME used for mode of communication)
    -f  where you want to perform eb tools check:
        prod (production)
        testing(default)
        cicd (continous integration)
    -u	which user is running on IPC (timing/gsi/root)
	(Used only when -c option is usb or pcie)
    -p	name of the IPC where test is being performed
	(Used only when -c option is usb or pcie)
    -t	ttyUSB number
	(Used only when -c option is usb)
    -w	wishbone number when device is powered via PCIe
	(Used only when -c option is pcie)
    -d  which device you want to check
        Use exp/pex/vet/scu/dm/all as options\n"

TEMP=`getopt -o hc:f:u:p:t:w:d:  --long help,connection:,facility:,user:,pcname:,ttynumber:,wbmnumber:,device: -n 'ebtools.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help) printf "$HELP"; shift; exit 1;;

        -c|--connection)
            case "$2" in
                "") shift 2 ;;
                *) CONNECTION=$2; shift 2 ;;
            esac ;;

       -f|--facility)
            case "$2" in
                "") shift 2 ;;
                *) FACILITY=$2; shift 2 ;;
            esac ;;

       -u|--user)
            case "$2" in
                "") shift 2 ;;
                *) username=$2; shift 2 ;;
            esac ;;

       -p|--pcname)
            case "$2" in
                "") shift 2 ;;
                *) pcname=$2; shift 2 ;;
            esac ;;

       -t|--ttynumber)
            case "$2" in
                "") shift 2 ;;
                *) ttynum=$2; shift 2 ;;
            esac ;;

       -w|--wbmnumber)
            case "$2" in
                "") shift 2 ;;
                *) wbmnum=$2; shift 2 ;;
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

EBTEST_DEVICE=http://tsl002.acc.gsi.de/config_files
EBTEST_DEV_LIST=device-list-$FACILITY.txt

wget $EBTEST_DEVICE/$EBTEST_DEV_LIST -O ./$EBTEST_DEV_LIST
ebtest_list=./$EBTEST_DEV_LIST
ebtest_temp=./ebtest_temp.txt

gsi_vendor_id=0x0000000000000651
lmram_device_id=0x54111351

putfile=./put_file
getfile=./get_file


function network(){
while IFS=$'\t' read -r -a ebtestArray 
do
	for i in {ebtestArray[2]}
	do
#eb-read and eb-write tools check
		lm32_ram_user=($(sudo eb-find udp/${ebtestArray[2]} $gsi_vendor_id $lmram_device_id))
		if [ $? != 0 ]; then
			echo -e "\e[31mError occurred"
			echo "Device ${ebtestArray[0]} with IP ${ebtestArray[2]} test failed. Error is" > ./check.txt
			sudo eb-find udp/${ebtestArray[2]} $gsi_vendor_id $lmram_device_id &>> ./check.txt
			mail -s “eb-tools test error” a.suresh@gsi.de < ./check.txt
			exit 1
		fi
		echo -e "\e[33mReading value at ${lm32_ram_user[0]} of ${ebtestArray[0]}"
		echo -e "\e[34m$(sudo eb-read udp/${ebtestArray[2]} ${lm32_ram_user[0]}/4)"
		echo -e "\e[33mWriting random unsigned value to ${lm32_ram_user[0]} of ${ebtestArray[0]}"
		sudo eb-write udp/${ebtestArray[2]} ${lm32_ram_user[0]}/4 $RANDOM 
		echo -e "\e[34m$(sudo eb-read udp/${ebtestArray[2]} ${lm32_ram_user[0]}/4)"
#eb-get and eb-put tools check
		dd if=/dev/urandom of=$putfile bs=4432 count=1
		sudo eb-put udp/${ebtestArray[2]} $lm32_ram_user $putfile
		echo -e "\e[33mComparing put_file and get_file"
		sudo eb-get udp/${ebtestArray[2]} $lm32_ram_user/4432 $getfile
		cmp -s $putfile $getfile
		if [ $? = 0 ]; then
		        echo -e "\e[92mput_file and get_file and of same size. RAM check successful"
		        rm -rf $putfile $getfile
		else
		        echo -e "\e[31mSize mismatch"
		        cmp $putfile $getfile
			rm -rf $putfile $getfile
		fi
		echo -e "\e[33mReading value after performing eb-put and eb-get"
		echo -e "\e[34m$(sudo eb-read udp/${ebtestArray[2]} ${lm32_ram_user[0]}/4)"
	done
echo
done < $ebtest_temp
rm $ebtest_temp
}

function USB(){

if [ "$username" != ""  ]; then
	user=$username
else
	echo -e "\e[33mEnter the USERNAME for IPC connected to PCIe devices (ex:timing/gsi)"
	read username
	user=$username
fi

if [ "$pcname" != ""  ]; then
        pc=$pcname
else
	echo -e "\e[33mEnter the IPC name (ex:tsl0xx)"
	read pcname
	pc=$pcname
fi

if [ "$ttynum" != ""  ]; then
        tty=$ttynum
else
	echo "Enter the ttyUSB number connected to the device (Ex:0)"
	read ttynum
	tty=$ttynum
fi

#eb-read and eb-write tools check

lm32_ram_user=($(sudo eb-find dev/ttyUSB$tty $gsi_vendor_id $lmram_device_id))
echo -e "\e[33mReading value at ${lm32_ram_user[0]}"
echo -e "\e[34m$(sudo eb-read dev/ttyUSB$tty ${lm32_ram_user[0]}/4)"
echo -e "\e[33mWriting random unsigned value to ${lm32_ram_user[0]}"
sudo eb-write dev/ttyUSB$tty ${lm32_ram_user[0]}/4 $RANDOM
echo -e "\e[34m$(sudo eb-read dev/ttyUSB$tty ${lm32_ram_user[0]}/4)"

#eb-get and eb-put tools check

dd if=/dev/urandom of=$putfile bs=4432 count=1
sudo eb-put dev/ttyUSB$tty $lm32_ram_user $putfile
echo -e "\e[33mComparing put_file and get_file"
sudo eb-get dev/ttyUSB$tty $lm32_ram_user/4432 $getfile
cmp -s $putfile $getfile
if [ $? = 0 ]; then
	echo -e "\e[92mput_file and get_file and of same size. RAM check successful"
        rm -rf $putfile $getfile
else
	echo -e "\e[31mSize mismatch"
        cmp $putfile $getfile
        rm -rf $putfile $getfile
fi
echo -e "\e[33mReading value after performing eb-put and eb-get"
echo -e "\e[34m$(sudo eb-read dev/ttyUSB$tty ${lm32_ram_user[0]}/4)"
echo
}

function PCIE(){
if [ "$username" != ""  ]; then
        user=$username
else
        echo -e "\e[33mEnter the USERNAME for IPC connected to PCIe devices (ex:timing/gsi)"
        read username
        user=$username
fi

if [ "$pcname" != ""  ]; then
        pc=$pcname
else
        echo -e "\e[33mEnter the IPC name (ex:tsl0xx)"
        read pcname
        pc=$pcname
fi

if [ "$wbmnum" != ""  ]; then
        wbm=$wbmnum
else
        echo "Enter the wbm number connected to the device (Ex:0)"
        read wbmnum
        wbm=$wbmnum
fi

ssh $user@$pc.acc.gsi.de '

putfile=./put_file
getfile=./get_file

lm32_ram_user=$(sudo eb-find dev/wbm'$wbm' '$gsi_vendor_id' '$lmram_device_id')
echo -e "\e[33mReading value at ${lm32_ram_user[0]}"
echo -e "\e[34m$(sudo eb-read dev/wbm'$wbm' ${lm32_ram_user[0]}/4)"
echo -e "\e[33mWriting random unsigned value to ${lm32_ram_user[0]}"
sudo eb-write dev/wbm'$wbm' ${lm32_ram_user[0]}/4 $RANDOM
echo -e "\e[34m$(sudo eb-read dev/wbm'$wbm' ${lm32_ram_user[0]}/4)"

dd if=/dev/urandom of=$putfile bs=4432 count=1
sudo eb-put dev/wbm'$wbm' $lm32_ram_user $putfile
echo -e "\e[33mComparing put_file and get_file"
sudo eb-get dev/wbm'$wbm' $lm32_ram_user/4432 $getfile
cmp -s $putfile $getfile
if [ $? = 0 ]; then
        echo -e "\e[92mput_file and get_file and of same size. RAM check successful"
        rm -rf $putfile $getfile
else
        echo -e "\e[31mSize mismatch"
        cmp $putfile $getfile
        rm -rf $putfile $getfile
fi
echo -e "\e[33mReading value after performing eb-put and eb-get"
echo -e "\e[34m$(sudo eb-read dev/wbm'$wbm' ${lm32_ram_user[0]}/4)"
echo
'
}


if [ "$CONNECTION" == "nw" ]; then
	if [ "$device_name" != ""  ]; then
        	keyword=$device_name
	else
		echo -e "\e[96mEnter the keyword of devices to perform eb-test"
		echo -e "\e[33mAccepted keyword is exp,pex,vet,scu2,scu3,all"
		read keyword
	fi

	for i in {0..10}
	do

	if [ "$keyword" == "exp" ] || [ "$keyword" == "all" ]; then
	        grep -ie "EXP" $ebtest_list > $ebtest_temp
		network
	fi

	if [ "$keyword" == "pex" ] || [ "$keyword" == "all" ]; then
                grep -ie "PEX" $ebtest_list > $ebtest_temp
                network
	fi

	if [ "$keyword" == "vet" ] || [ "$keyword" == "all" ]; then
                grep -ie "VET" $ebtest_list > $ebtest_temp
                network
	fi

	if [ "$keyword" == "scu2" ] || [ "$keyword" == "all" ]; then
                grep -ie "scu2" $ebtest_list > $ebtest_temp
                network
	fi

	if [ "$keyword" == "scu3" ] || [ "$keyword" == "all" ]; then
                grep -ie "scu3" $ebtest_list > $ebtest_temp
                network
        fi

	done

elif [ "$CONNECTION" == "usb" ]; then
	for i in {0..10}
        do
        	USB
	done

elif [ "$CONNECTION" == "pcie" ]; then
	for i in {0..10}
        do
		PCIE
	done
fi
rm $ebtest_list
