#!/bin/bash

#Change ttyUSBx number after connecting the device
#Check the switch number connected to the device for auto start

FACILITY="cicd"

HELP="$(basename "$0") [-h] [-f deployment target] -- script to flash Timing Receivers using JTAG


where:
    -h  show this help text
    -f  Timing receivers in which facility you want to reset:
        prod (production)
        testing(testing facility)
        cicd (continous integration- default)\n"

TEMP=`getopt -o hf: --long help,facility: -n 'nightly_build_programmer.sh' -- "$@"`
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

script_path=/home/timing/ci_cd/scripts/nightly
export WEB_SERVER=/var/www/html/releases/nightly/gateware
export G_IMAGE_PATH=/var/www/html/releases/golden_image/gateware

export exp_job_path=/var/lib/jenkins/jobs/nightly_build_exploder5
export pex_job_path=/var/lib/jenkins/jobs/nightly_build_pexarria5
export vet_job_path=/var/lib/jenkins/jobs/nightly_build_vetar2a
export scu3_job_path=/var/lib/jenkins/jobs/nightly_build_scu3
export scu2_job_path=/var/lib/jenkins/jobs/nightly_build_scu2
export dm_job_path=/var/lib/jenkins/jobs/nightly_build_datamaster

DEVICE=http://tsl002.acc.gsi.de/config_files
DEV_LIST=device-list-$FACILITY.txt
wget $DEVICE/$DEV_LIST -O ./$DEV_LIST
list=$script_path/$DEV_LIST
temp=$script_path/temp.txt

jtagchk_output=$script_path/temp1.txt

. ./jtag_check.sh > $jtagchk_output

if (grep -q "Exploder-5a connected" $jtagchk_output); then
	grep -ie "exploder" $list > $temp
	while IFS=$'\t' read -r -a nightlyArray
        do	
		for i in {nightlyArray[2]}
                do
			if (grep -rqn $exp_job_path -e "Finished: FAILURE"); then
				echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                		cd /opt/quartus/quartus/bin
	                	. ~/shell_scripts/quartus16.sh
	        	        ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/exploder5_csco_tr.sof'
        	        	sleep 5
	        	        sudo eb-flash udp/${nightlyArray[2]} $G_IMAGE_PATH/exploder5_csco_tr.rpd
				echo -e "\e[34mExploder flashed with golden image of exploder5_csco_tr.rpd file"
                                echo -e "\e[32m"
			else
				cd /opt/quartus/quartus/bin
				. ~/shell_scripts/quartus16.sh
				./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/exploder5_csco_tr.sof'
				sleep 5
				sudo eb-flash udp/${nightlyArray[2]} $WEB_SERVER/exploder5_csco_tr.rpd
				echo -e "\e[34mExploder flashed with latest exploder5_csco_tr.rpd file"
				echo -e "\e[32m"
			fi
		done
	done < $temp
else
	echo -e "\e[31mExploder-5a not connected"
	echo -e "\e[32m"
fi

if (grep -q "Pexarria-5 connected" $jtagchk_output); then
	grep -ie "pexarria" $list > $temp
        while IFS=$'\t' read -r -a nightlyArray
        do
                for i in {nightlyArray[2]}
                do
			if (grep -rqn $pex_job_path -e "Finished: FAILURE"); then
				echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
		                cd /opt/quartus/quartus/bin
                		. ~/shell_scripts/quartus16.sh
		                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/pci_control.sof'
		                sleep 5
                		sudo eb-flash udp/${nightlyArray[2]} $G_IMAGE_PATH/pci_control.rpd
				echo -e "\e[34mPexarria flashed with golden image of pci_control.rpd file"
                                echo -e "\e[32m"
        		else
		        	cd /opt/quartus/quartus/bin
	        		. ~/shell_scripts/quartus16.sh
		        	./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/pci_control.sof'
	        		sleep 5
		        	sudo eb-flash udp/${nightlyArray[2]} $WEB_SERVER/pci_control.rpd
				echo -e "\e[34mPexarria flashed with latest pci_control.rpd file"
				echo -e "\e[32m"
			fi
                done
        done < $temp
else
        echo -e "\e[31mPexarria-5 not connected"
	echo -e "\e[32m"
fi

if (grep -q "Vetar2a connected" $jtagchk_output); then
	grep -ie "vetar" $list > $temp
        while IFS=$'\t' read -r -a nightlyArray
        do
                for i in {nightlyArray[2]}
                do
			if (grep -rqn $vet_job_path -e "Finished: FAILURE"); then
				echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                		cd /opt/quartus/quartus/bin
		                . ~/shell_scripts/quartus16.sh
                		./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/vetar2a.sof'
		                sleep 5
                		sudo eb-flash udp/${nightlyArray[2]} $G_IMAGE_PATH/vetar2a.rpd
				echo -e "\e[34mVetar2a flashed with golden image of vetar2a.rpd file"
                                echo -e "\e[32m"
			else
	        		cd /opt/quartus/quartus/bin
		        	. ~/shell_scripts/quartus16.sh
	        		./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/vetar2a.sof'
		        	sleep 5
	        		sudo eb-flash udp/${nightlyArray[2]} $WEB_SERVER/vetar2a.rpd
				echo -e "\e[34mVetar2a flashed with latest vetar2a.rpd file"
				echo -e "\e[32m"
       			fi
                done
        done < $temp
else
        echo -e "\e[31mVetar2a not connected"
	echo -e "\e[32m"
fi

if (grep -q "SCU3 connected" $jtagchk_output); then
        grep -ie "scu3" $list > $temp
        while IFS=$'\t' read -r -a nightlyArray
        do
                for i in {nightlyArray[2]}
                do
			if (grep -rqn $scu3_job_path -e "Finished: FAILURE"); then
				echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
		                cd /opt/quartus/quartus/bin
                		. ~/shell_scripts/quartus16.sh
		                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/scu3_control.sof'
                		sleep 5
		                sudo eb-flash udp/${nightlyArray[2]} $G_IMAGE_PATH/scu3_control.rpd
				echo -e "\e[34mSCU3 flashed with golden image of scu_control3.rpd file"
                                echo -e "\e[32m"
			else
	        		cd /opt/quartus/quartus/bin
		        	. ~/shell_scripts/quartus16.sh
	        		./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/scu_control3.sof'
		        	sleep 5
	        		sudo eb-flash udp/${nightlyArray[2]} $WEB_SERVER/scu_control3.rpd
				echo -e "\e[34mSCU3 flashed with latest scu_control3.rpd file"
				echo -e "\e[32m"
			fi
                done
        done < $temp
else
        echo -e "\e[31mSCU3 not connected"
	echo -e "\e[32m"
fi

if (grep -q "SCU2 connected" $jtagchk_output); then
        grep -ie "scu2" $list > $temp
        while IFS=$'\t' read -r -a nightlyArray
        do
                for i in {nightlyArray[2]}
                do
			if (grep -rqn $scu2_job_path -e "Finished: FAILURE"); then
				echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                		cd /opt/quartus/quartus/bin
		                . ~/shell_scripts/quartus16.sh
                		./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/scu2_control.sof'
		                sleep 5
                		sudo eb-flash udp/${nightlyArray[2]} $G_IMAGE_PATH/scu2_control.rpd
				echo -e "\e[34mSCU2 flashed with golden image of scu_control2.rpd file"
                                echo -e "\e[32m"
		       	else
		                cd /opt/quartus/quartus/bin
                		. ~/shell_scripts/quartus16.sh
		                ./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/scu_control2.sof'
                		sleep 5
		                sudo eb-flash udp/${nightlyArray[2]} $WEB_SERVER/scu_control2.rpd
				echo -e "\e[34mSCU2 flashed with latest scu_control2.rpd file"
				echo -e "\e[32m"
       			fi
		done
        done < $temp
else
        echo -e "\e[31mSCU2 not connected"
        echo -e "\e[32m"
fi

if (grep -q "Datamaster connected" $jtagchk_output); then
        grep -ie "datamaster" $list > $temp
        while IFS=$'\t' read -r -a nightlyArray
        do
                for i in {nightlyArray[2]}
                do
		        if (grep -rqn $dm_job_path -e "Finished: FAILURE"); then
				echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
		                cd /opt/quartus/quartus/bin
                		. ~/shell_scripts/quartus16.sh
		                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/ftm.sof'
                		sleep 5
		                sudo eb-flash udp/${nightlyArray[2]} $G_IMAGE_PATH/ftm.rpd
                                echo -e "\e[34mDatamaster flashed with golden image of ftm.rpd file"
                                echo -e "\e[32m"
			else
                		cd /opt/quartus/quartus/bin
		                . ~/shell_scripts/quartus16.sh
                		./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/ftm.sof'
		                sleep 5
                		sudo eb-flash udp/${nightlyArray[2]} $WEB_SERVER/ftm.rpd
				echo -e "\e[34mDatamaster flashed with latest ftm.rpd file"
				echo -e "\e[32m"
       			fi
                done
        done < $temp
else
        echo -e "\e[31mDatamaster not connected"
        echo -e "\e[32m"
fi

rm $jtagchk_output $list $temp
