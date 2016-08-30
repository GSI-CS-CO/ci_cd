#!/bin/bash

#Change ttyUSBx number after connecting the device
#Check the switch number connected to the device for auto start

export WEB_SERVER=/var/www/html/releases/nightly/gateware
export G_IMAGE_PATH=/var/www/html/releases/golden_image/gateware

export exp_job_path=/var/lib/jenkins/jobs/nightly_build_exploder5
export pex_job_path=/var/lib/jenkins/jobs/nightly_build_pexarria5
export vet_job_path=/var/lib/jenkins/jobs/nightly_build_vetar2a
export scu3_job_path=/var/lib/jenkins/jobs/nightly_build_scu3
export scu2_job_path=/var/lib/jenkins/jobs/nightly_build_scu2
export dm_job_path=/var/lib/jenkins/jobs/nightly_build_datamaster

jtagchk_output=~/shell_scripts/temp.txt

. ~/shell_scripts/jtag_check.sh > $jtagchk_output

cd ~/shell_scripts

if (grep -q "Exploder-5a connected" $jtagchk_output); then

	if (grep -rqn $exp_job_path -e "Finished: FAILURE"); then
		echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/exploder5_csco_tr.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $G_IMAGE_PATH/exploder5_csco_tr.rpd
	else
		cd /opt/quartus/quartus/bin
		. ~/shell_scripts/quartus16.sh
		./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/exploder5_csco_tr.sof'
		sleep 5
		sudo eb-flash dev/ttyUSB0 $WEB_SERVER/exploder5_csco_tr.rpd
		echo -e "\e[34mExploder flashed with latest exploder5_csco_tr.rpd file"
		echo
	fi
else
	echo -e "\e[31mExploder-5a not connected"
	echo
fi

if (grep -q "Pexarria-5 connected" $jtagchk_output); then

	if (grep -rqn $pex_job_path -e "Finished: FAILURE"); then
		echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/pci_control.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $G_IMAGE_PATH/pci_control.rpd
        else
        	cd /opt/quartus/quartus/bin
	        . ~/shell_scripts/quartus16.sh
        	./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/pci_control.sof'
	        sleep 5
        	sudo eb-flash dev/ttyUSB0 $WEB_SERVER/pci_control.rpd
		echo -e "\e[34mPexarria flashed with latest pci_control.rpd file"
	fi
else
        echo -e "\e[31mPexarria-5 not connected"
	echo
fi

if (grep -q "Vetar2a connected" $jtagchk_output); then

	if (grep -rqn $vet_job_path -e "Finished: FAILURE"); then
		echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/vetar2a.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $G_IMAGE_PATH/vetar2a.rpd
	else
	        cd /opt/quartus/quartus/bin
        	. ~/shell_scripts/quartus16.sh
	        ./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/vetar2a.sof'
        	sleep 5
	        sudo eb-flash dev/ttyUSB0 $WEB_SERVER/vetar2a.rpd
		echo -e "\e[34mVetar2a flashed with latest vetar2a.rpd file"
       	fi
else
        echo -e "\e[31mVetar2a not connected"
	echo
fi

if (grep -q "SCU3 connected" $jtagchk_output); then

	if (grep -rqn $scu3_job_path -e "Finished: FAILURE"); then
		echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/scu3_control.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $G_IMAGE_PATH/scu3_control.rpd
       else
	        cd /opt/quartus/quartus/bin
        	. ~/shell_scripts/quartus16.sh
	        ./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/scu_control3.sof'
        	sleep 5
	        sudo eb-flash dev/ttyUSB0 $WEB_SERVER/scu_control3.rpd
		echo -e "\e[34mSCU3 flashed with latest scu_control3.rpd file"
       fi
else
        echo -e "\e[31mSCU3 not connected"
	echo
fi

if (grep -q "SCU2 connected" $jtagchk_output); then

        if (grep -rqn $scu2_job_path -e "Finished: FAILURE"); then
		echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/scu2_control.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $G_IMAGE_PATH/scu2_control.rpd
       else
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/scu_control2.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $WEB_SERVER/scu_control2.rpd
		echo -e "\e[34mSCU2 flashed with latest scu_control2.rpd file"
       fi
else
        echo -e "\e[31mSCU2 not connected"
        echo
fi

if (grep -q "Datamaster connected" $jtagchk_output); then

        if (grep -rqn $dm_job_path -e "Finished: FAILURE"); then
		echo -e "\e[33mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$G_IMAGE_PATH/ftm.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $G_IMAGE_PATH/ftm.rpd
       else
                cd /opt/quartus/quartus/bin
                . ~/shell_scripts/quartus16.sh
                ./quartus_pgm -c 1 -m jtag -o 'p;$WEB_SERVER/ftm.sof'
                sleep 5
                sudo eb-flash dev/ttyUSB0 $WEB_SERVER/ftm.rpd
		echo -e "\e[34mDatamaster flashed with latest ftm.rpd file"
       fi
else
        echo -e "\e[31mDatamaster not connected"
        echo
fi

rm $jtagchk_output
