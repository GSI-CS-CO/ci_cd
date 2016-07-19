#!/bin/bash

export WEB_SRVR_PATH=/var/www/html/releases/nightly/gateware

PWD=$(pwd)

export exp_path=/home/timing/jenkins_jobs/nightly_build_exploder5
export pex_path=/home/timing/jenkins_jobs/nightly_build_pexarria5
export vet_path=/home/timing/jenkins_jobs/nightly_build_vetar2a
export scu3_path=/home/timing/jenkins_jobs/nightly_build_scu3
export scu2_path=/home/timing/jenkins_jobs/nightly_build_scu2


case $PWD in

	$exp_path)
				
		make exploder5-clean
		make exploder5
		
		export PATH=$PATH:$exp_path/toolchain/bin
		
		cd syn/gsi_exploder5/exploder5_csco_tr
		cp exploder5_csco_tr.jic exploder5_csco_tr.rpd exploder5_csco_tr.sof $WEB_SRVR_PATH

		cd $WEB_SRVR_PATH
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$pex_path)

		make pexarria5-clean
		make pexarria5

		export PATH=$PATH:$pex_path/toolchain/bin

		cd syn/gsi_pexarria5/control
		cp  pci_control.jic pci_control.sof pci_control.rpd $WEB_SRVR_PATH

		cd $WEB_SRVR_PATH
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$vet_path)

		make vetar2a-clean
		make vetar2a

		export PATH=$PATH:$vet_path/toolchain/bin

		cd syn/gsi_vetar2a/wr_core_demo
		cp vetar2a.jic vetar2a.rpd vetar2a.sof $WEB_SRVR_PATH

		cd $WEB_SRVR_PATH
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

	$scu3_path)

		make scu3-clean
		make scu3

		export PATH=$PATH:$scu3_path/toolchain/bin

		cd syn/gsi_scu/control3
		cp scu_control.rpd $WEB_SRVR_PATH/scu_control3.rpd
		cp scu_control.sof $WEB_SRVR_PATH/scu_control3.sof
		cp scu_control.jic $WEB_SRVR_PATH/scu_control3.jic

		cd $WEB_SRVR_PATH
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$scu2_path)

                make scu2-clean
                make scu2

		export PATH=$PATH:$scu2_path/toolchain/bin

                cd syn/gsi_scu/control2
                cp scu_control.rpd $WEB_SRVR_PATH/scu_control2.rpd
                cp scu_control.sof $WEB_SRVR_PATH/scu_control2.sof
                cp scu_control.jic $WEB_SRVR_PATH/scu_control2.jic

                cd $WEB_SRVR_PATH
                md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;
esac

