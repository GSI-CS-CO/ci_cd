#!/bin/bash

WEB_SRVR_PATH=/var/www/html/releases/nightly

PWD=$(pwd)

exp_path=/home/timing/jenkins_jobs/nightly_build_exploder5
pex_path=/home/timing/jenkins_jobs/nightly_build_pexarria5
vet_path=/home/timing/jenkins_jobs/nightly_build_vetar2a
scu3_path=/home/timing/jenkins_jobs/nightly_build_scu3
scu2_path=/home/timing/jenkins_jobs/nightly_build_scu2
dm_path=/home/timing/jenkins_jobs/nightly_build_datamaster
wrpc_path=/home/timing/jenkins_jobs/nightly_build_wrpc-sw
eb_path=/home/timing/jenkins_jobs/nightly_build_etherbone
saftlib_path=/home/timing/jenkins_jobs/nightly_build_saftlib
log_makefile=/var/www/html/releases/log/nightly_makefile_log

case $PWD in

	$exp_path)
				
		make exploder5-clean
                export PATH=$PATH:$exp_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make exploder5 2>&1 > $log_makefile/nightly_build_exploder5.$(date +%Y-%m-%d).log
				
		cd syn/gsi_exploder5/exploder5_csco_tr
		cp exploder5_csco_tr.jic exploder5_csco_tr.rpd exploder5_csco_tr.sof $WEB_SRVR_PATH/gateware

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$pex_path)

		make pexarria5-clean
                export PATH=$PATH:$pex_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make pexarria5 2>&1 > $log_makefile/nightly_build_pexarria5.$(date +%Y-%m-%d).log

		cd syn/gsi_pexarria5/control
		cp  pci_control.jic pci_control.sof pci_control.rpd $WEB_SRVR_PATH/gateware

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$vet_path)

		make vetar2a-clean
                export PATH=$PATH:$vet_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make vetar2a 2>&1 > $log_makefile/nightly_build_vetar2a.$(date +%Y-%m-%d).log

		cd syn/gsi_vetar2a/wr_core_demo
		cp vetar2a.jic vetar2a.rpd vetar2a.sof $WEB_SRVR_PATH/gateware

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

	$scu3_path)

		make scu3-clean
                export PATH=$PATH:$scu3_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make scu3 2>&1 > $log_makefile/nightly_build_scu3.$(date +%Y-%m-%d).log

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
		export GSI_BUILD_TYPE=Balloon_release
                make scu2 2>&1 > $log_makefile/nightly_build_scu2.$(date +%Y-%m-%d).log

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
		make clean
                export PATH=$PATH:$dm_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make 2>&1 > $log_makefile/nightly_build_ftm.$(date +%Y-%m-%d).log
		
		cp ftm.jic ftm.rpd ftm.sof $WEB_SRVR_PATH/gateware
                cp ftm.bin $WEB_SRVR_PATH/ftm_firmware
 
                cd $WEB_SRVR_PATH/gateware
                md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

        $wrpc_path)

                make 
                cd ip_cores/wrpc-sw        
                export PATH=$PATH:$wrpc_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
                make 2>&1 > $log_makefile/nightly_build_wrpc-sw.$(date +%Y-%m-%d).log
		
		cp wrc.bin wrc.elf wrc.mif $WEB_SRVR_PATH/wrpc-sw
        ;;

	$eb_path)

		export GSI_BUILD_TYPE=Balloon_release
                make etherbone 2>&1 > $log_makefile/nightly_build_etherbone.$(date +%Y-%m-%d).log
                export PATH=$PATH:$eb_path/toolchain/bin
                make etherbone-install STAGING=/tmp/etherbone
                cd /tmp
		
		tar -cf - etherbone | xz -9 -c - > etherbone.tar.xz
		cp etherbone.tar.xz $WEB_SRVR_PATH/etherbone
		rm -rf etherbone etherbone.tar.xz
        ;;

        $saftlib_path)

		export GSI_BUILD_TYPE=Balloon_release
                make saftlib 2>&1 > $log_makefile/nightly_build_saftlib.$(date +%Y-%m-%d).log
                export PATH=$PATH:$saftlib_path/toolchain/bin
                make saftlib-install STAGING=/tmp/saftlib
		cd /tmp

                tar -cf - saftlib | xz -9 -c - > saftlib.tar.xz
                cp saftlib.tar.xz $WEB_SRVR_PATH/saftlib
                rm -rf saftlib saftlib.tar.xz
        ;;


esac

