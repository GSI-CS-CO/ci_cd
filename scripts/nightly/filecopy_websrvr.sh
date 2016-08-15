#!/bin/bash

export WEB_SRVR_PATH=/var/www/html/releases/nightly

PWD=$(pwd)

export exp_path=/home/timing/jenkins_jobs/nightly_build_exploder5
export pex_path=/home/timing/jenkins_jobs/nightly_build_pexarria5
export vet_path=/home/timing/jenkins_jobs/nightly_build_vetar2a
export scu3_path=/home/timing/jenkins_jobs/nightly_build_scu3
export scu2_path=/home/timing/jenkins_jobs/nightly_build_scu2
export dm_path=/home/timing/jenkins_jobs/nightly_build_datamaster
export wrpc_path=/home/timing/jenkins_jobs/nightly_build_wrpc-sw
export eb_path=/home/timing/jenkins_jobs/nightly_build_etherbone
export saftlib_path=/home/timing/jenkins_jobs/nightly_build_saftlib

case $PWD in

	$exp_path)
				
		make exploder5-clean
                export PATH=$PATH:$exp_path/toolchain/bin
		make exploder5
				
		cd syn/gsi_exploder5/exploder5_csco_tr
		cp exploder5_csco_tr.jic exploder5_csco_tr.rpd exploder5_csco_tr.sof $WEB_SRVR_PATH/gateware

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$pex_path)

		make pexarria5-clean
                export PATH=$PATH:$pex_path/toolchain/bin
		make pexarria5

		cd syn/gsi_pexarria5/control
		cp  pci_control.jic pci_control.sof pci_control.rpd $WEB_SRVR_PATH/gateware

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$vet_path)

		make vetar2a-clean
                export PATH=$PATH:$vet_path/toolchain/bin
		make vetar2a

		cd syn/gsi_vetar2a/wr_core_demo
		cp vetar2a.jic vetar2a.rpd vetar2a.sof $WEB_SRVR_PATH/gateware

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

	$scu3_path)

		make scu3-clean
                export PATH=$PATH:$scu3_path/toolchain/bin
		make scu3

		cd syn/gsi_scu/control3
		cp scu_control.rpd $WEB_SRVR_PATH/gateware/scu_control3.rpd
		cp scu_control.sof $WEB_SRVR_PATH/gateware/scu_control3.sof
		cp scu_control.jic $WEB_SRVR_PATH/gateware/scu_control3.jic

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$scu2_path)

                make scu2-clean
		export PATH=$PATH:$scu2_path/toolchain/bin
                make scu2

                cd syn/gsi_scu/control2
                cp scu_control.rpd $WEB_SRVR_PATH/gateware/scu_control2.rpd
                cp scu_control.sof $WEB_SRVR_PATH/gateware/scu_control2.sof
                cp scu_control.jic $WEB_SRVR_PATH/gateware/scu_control2.jic

                cd $WEB_SRVR_PATH/gateware
                md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

        $dm_path)

                make firmware
		cd syn/gsi_pexarria5/ftm
                export PATH=$PATH:$dm_path/toolchain/bin
		make
		
		cp ftm.jic ftm.rpd ftm.sof $WEB_SRVR_PATH/gateware
                
                cd $WEB_SRVR_PATH/gateware
                md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

        $wrpc_path)

                make 
                cd ip_cores/wrpc-sw        
                export PATH=$PATH:$wrpc_path/toolchain/bin
                make
		
		cp wrc.bin wrc.elf wrc.mif $WEB_SRVR_PATH/wrpc-sw
        ;;

	$eb_path)

                make etherbone
                export PATH=$PATH:$eb_path/toolchain/bin
                make etherbone-install STAGING=/tmp/etherbone
                cd /tmp
		
		tar -cf - etherbone | xz -9 -c - > etherbone.tar.xz
		cp etherbone.tar.xz $WEB_SRVR_PATH/etherbone
		rm -rf etherbone etherbone.tar.xz
        ;;

        $saftlib_path)

                make saftlib
                export PATH=$PATH:$saftlib_path/toolchain/bin
                make saftlib-install STAGING=/tmp/saftlib
		cd /tmp

                tar -cf - saftlib | xz -9 -c - > saftlib.tar.xz
                cp saftlib.tar.xz $WEB_SRVR_PATH/saftlib
                rm -rf saftlib saftlib.tar.xz
        ;;


esac

