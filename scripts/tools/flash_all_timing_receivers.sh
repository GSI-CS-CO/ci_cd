#!/bin/sh

# This script is (should be) smart enough to flash all connected 
# timing receivers connected to a host with the correct gateware, 
# based on eb-info output. The location of the gateware .rpd file 
# can be specified. If not specified the nightly build of balloon 
# release is used.

# some colors (use with "echo -e "no color ${GREEN}green words${NC} no color")
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# set default options
server=http://tsl002.acc.gsi.de
release_directory=/releases/balloon/gateware

# print help if calles without arguments
if [ $# -eq 0 ] ; then
	echo " This script detects attached timing receivers (using eb-info),"
	echo " downloads the correct gateware from a server, and flashes the"
	echo " devices."
	echo " "
	echo "usage: $0 [-s server] [-r release_directory] devices "
	echo "    defaults:"
	echo "       server            :  http://tsl002.acc.gsi.de"
	echo "       release_directory :  /releases/balloon/gateware"
	echo " " 
	echo "    examples (note the leading slash '/' on the device file):"
	echo "       flash all timing receivers attached to host with USB:"
	echo "       ./flash_all_timing_receivers.sh -r /releases/cherry/gateware /dev/ttyUSB*"
	echo "       flash all timing on the host:"
	echo "       ./flash_all_timing_receivers.sh -r /releases/cherry/gateware /dev/ttyUSB* /dev/wbm*"
	exit 1
fi
# overwrite optional parameters
num_opt=0
while getopts ":r:s:" option
do
	case "${option}" in
		s) server=${OPTARG};            num_opt=$(($num_opt+2)) ;;
		r) release_directory=${OPTARG}; num_opt=$(($num_opt+2))  ;;
		\?) echo "invalid option: -$OPTARG" ;;
	esac
done
while [ $num_opt -ne 0 ]
do 
	num_opt=$(($num_opt-1))
	shift
done;
if [ $# == 0 ]
	then
		echo -e "${RED}no devices specified${NC}"
fi
# loop over all devices (remaining arguments)
for device in "${@}" 
do
	# find the formfactor name from eb-info
	# 1) get the eb-info output 
	# 2) get the second line (starting with string "Platform")
	# 3) get the first field after the colon ":"
	eb-info ${device#/} > /tmp/eb_info.out
	if [ $? -ne 0 ]; then
		echo -e "${RED}invalid device ${device#/}${NC}"
		rm /tmp/eb_info.out
		exit 1;
	fi
	echo "device: ${device#/}"
	rm /tmp/eb_info.out
	platform=`eb-info ${device#/} | head -n 2 | tail -n 1 | cut -d":" -f 2 | cut -d"+" -f 1 | sed 's/ //g'`
	# download the file list from server (by default use )
	if [ -f index.html ] 
	then
		rm index.html
	fi
	if ! wget -q ${server}/${release_directory#/}/ ; then
		echo -e "${RED}invalid server or release directory (URL: ${server}/${release_directory#/}/)${NC}"
		exit 1
	fi
	# Deal with the fact that there can be different gateware filenames on the server depending on the release
	# this relies on the assumption that all .rpd files for
	#    * pexarria start with 'p'   ("pexarria..." or "pexaria..." or "pci_control...")
	#    * vetar    start with 'v'   ("vetar2a..." or "vetar2a_<date>...")
	#    * scu3     start with 'scu3'
	#    * scu2     start with 'scu2'
	#    * exploder start with 'e'  
	eb_flash_args=" "
	case ${platform} in
		vetar2a) 	key='v'; eb_flash_args=" -w 3 ";;
		pexaria5)	key='p';;
		scu2)		key="scu.*2";;
		scu3)		key="scu.*3";;
		exploder5)	key="e";;
	esac
	# Now extract the most recent gateware .rpd file sitting between <a href="..."> and </a> xml tags
	gateware_rpd=`sed -e 's:.*<a href=".*">\(.*\)</a>.*:\1:p' index.html | grep "^${key}.*rpd" | tail -n 1`
	host=`hostname`
	echo -e "${NC}flashing device ${GREEN}${host}:${device#/}${NC} (platform ${GREEN}${platform}${NC}) with gateware ${GREEN}${server}/${release_directory#/}/${gateware_rpd}${NC}"
	# remove .rpd file if already present ...
	if [ -f ${gateware_rpd} ] 
	then
		rm ${gateware_rpd}
	fi
	# ... and get the latest 
	if wget -q ${server}/${release_directory#/}/${gateware_rpd}
	then 
		# try 10 times to flash
		n=0
		while [ $n -ne 10 ] 
		do
			n=$((n + 1))
			if eb-flash ${eb_flash_args} ${device#/} ${gateware_rpd} 
			then 
				# flashing was successful
				echo -e "${GREEN}done${NC}"
				break
			else
				# flashing was not successful
				echo -e "${RED}error while flashing${NC}"
			fi
		done
	else
		echo -e "${RED}could not download gateware ${gateware_rpd}${NC}"
	fi

	## do a reset
	# echo "reset the node"
	# RESET_ADR=`eb-ls ${device#/} | grep FPGA_RESET | sed 's/ \+/ /g' | cut -d" " -f 3`
	# eb-write ${device#/} 0x${RESET_ADR}/4 0xdeadbeef
done
exit 0
