#!/bin/bash

#Script to compile gateware and drivers for bel_projects balloon branch
#This script compiles the gateware and drivers and copies the files on the
#web server under the releases/balloon directory according to the date it 
#was built
#The files are stored in the web server for 7 days, after which the oldest
#files will be replaced with the newest one

WEB_SRVR_PATH=/var/www/html/releases/balloon
GATEWARE_SEVEN_DAYS="$WEB_SRVR_PATH/gateware/*.$(date --date="7 days ago" +%Y-%m-%d)*"
EB_SEVEN_DAYS="$WEB_SRVR_PATH/etherbone/*.$(date --date="7 days ago" +%Y-%m-%d)*"
WRPC_SEVEN_DAYS="$WEB_SRVR_PATH/wrpc-sw/*.$(date --date="7 days ago" +%Y-%m-%d)*"
SAFTLIB_SEVEN_DAYS="$WEB_SRVR_PATH/saftlib/*.$(date --date="7 days ago" +%Y-%m-%d)*"
FTMBIN_SEVEN_DAYS="$WEB_SRVR_PATH/ftm_firmware/*.$(date --date="7 days ago" +%Y-%m-%d)*"

PWD=$(pwd)

jenkins_home=/home/timing/jenkins_jobs

exp_path=$jenkins_home/balloon_build_exploder5
pex_path=$jenkins_home/balloon_build_pexarria5
vet_path=$jenkins_home/balloon_build_vetar2a
scu3_path=$jenkins_home/balloon_build_scu3
scu2_path=$jenkins_home/balloon_build_scu2
dm_path=$jenkins_home/balloon_build_datamaster
wrpc_path=$jenkins_home/balloon_build_wrpc-sw
eb_path=$jenkins_home/balloon_build_etherbone
saftlib_path=$jenkins_home/balloon_build_saftlib
log_makefile=/var/www/html/releases/log/balloon_makefile_log

case $PWD in

	$exp_path)
				
		make exploder5-clean
                export PATH=$PATH:$exp_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make exploder5 2>&1 > $log_makefile/balloon_build_exploder5.$(date +%Y-%m-%d).log
				
		cd syn/gsi_exploder5/exploder5_csco_tr
		cp exploder5_csco_tr.jic $WEB_SRVR_PATH/gateware/exploder5_csco_tr.$(date +%Y-%m-%d).jic
		cp exploder5_csco_tr.rpd $WEB_SRVR_PATH/gateware/exploder5_csco_tr.$(date +%Y-%m-%d).rpd
		cp exploder5_csco_tr.sof $WEB_SRVR_PATH/gateware/exploder5_csco_tr.$(date +%Y-%m-%d).sof

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$pex_path)

		make pexarria5-clean
                export PATH=$PATH:$pex_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make pexarria5 2>&1 > $log_makefile/balloon_build_pexarria5.$(date +%Y-%m-%d).log

		cd syn/gsi_pexarria5/control
		cp pci_control.jic $WEB_SRVR_PATH/gateware/pci_control.$(date +%Y-%m-%d).jic
		cp pci_control.sof $WEB_SRVR_PATH/gateware/pci_control.$(date +%Y-%m-%d).sof
		cp pci_control.rpd $WEB_SRVR_PATH/gateware/pci_control.$(date +%Y-%m-%d).rpd

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$vet_path)

		make vetar2a-clean
                export PATH=$PATH:$vet_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make vetar2a 2>&1 > $log_makefile/balloon_build_vetar2a.$(date +%Y-%m-%d).log

		cd syn/gsi_vetar2a/wr_core_demo
		cp vetar2a.jic $WEB_SRVR_PATH/gateware/vetar2a.$(date +%Y-%m-%d).jic
		cp vetar2a.rpd $WEB_SRVR_PATH/gateware/vetar2a.$(date +%Y-%m-%d).rpd
		cp vetar2a.sof $WEB_SRVR_PATH/gateware/vetar2a.$(date +%Y-%m-%d).sof

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

	$scu3_path)

		make scu3-clean
                export PATH=$PATH:$scu3_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make scu3 2>&1 > $log_makefile/balloon_build_scu3.$(date +%Y-%m-%d).log

		cd syn/gsi_scu/control3
		cp scu_control.rpd $WEB_SRVR_PATH/gateware/scu_control3.$(date +%Y-%m-%d).rpd
		cp scu_control.sof $WEB_SRVR_PATH/gateware/scu_control3.$(date +%Y-%m-%d).sof
		cp scu_control.jic $WEB_SRVR_PATH/gateware/scu_control3.$(date +%Y-%m-%d).jic

		cd $WEB_SRVR_PATH/gateware
		md5sum *.jic *.rpd *.sof | tee MD5SUMS
	;;

	$scu2_path)

                make scu2-clean
		export PATH=$PATH:$scu2_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
                make scu2 2>&1 > $log_makefile/balloon_build_scu2.$(date +%Y-%m-%d).log

                cd syn/gsi_scu/control2
                cp scu_control.rpd $WEB_SRVR_PATH/gateware/scu_control2.$(date +%Y-%m-%d).rpd
                cp scu_control.sof $WEB_SRVR_PATH/gateware/scu_control2.$(date +%Y-%m-%d).sof
                cp scu_control.jic $WEB_SRVR_PATH/gateware/scu_control2.$(date +%Y-%m-%d).jic

                cd $WEB_SRVR_PATH/gateware
                md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

        $dm_path)

                make firmware
		cd syn/gsi_pexarria5/ftm
                make clean
		export PATH=$PATH:$dm_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
		make 2>&1 > $log_makefile/balloon_build_ftm.$(date +%Y-%m-%d).log
		
		cp ftm.jic $WEB_SRVR_PATH/gateware/ftm.$(date +%Y-%m-%d).jic
		cp ftm.rpd $WEB_SRVR_PATH/gateware/ftm.$(date +%Y-%m-%d).rpd
		cp ftm.sof $WEB_SRVR_PATH/gateware/ftm.$(date +%Y-%m-%d).sof
		cp ftm.bin $WEB_SRVR_PATH/ftm_firmware/ftm.$(date +%Y-%m-%d).bin
 
                cd $WEB_SRVR_PATH/gateware
                md5sum *.jic *.rpd *.sof | tee MD5SUMS
        ;;

        $wrpc_path)

                make 
                cd ip_cores/wrpc-sw        
                export PATH=$PATH:$wrpc_path/toolchain/bin
		export GSI_BUILD_TYPE=Balloon_release
                make 2>&1 > $log_makefile/balloon_build_wrpc-sw.$(date +%Y-%m-%d).log
		
		cp wrc.bin $WEB_SRVR_PATH/wrpc-sw/wrc.$(date +%Y-%m-%d).bin
		cp wrc.elf $WEB_SRVR_PATH/wrpc-sw/wrc.$(date +%Y-%m-%d).elf
		cp wrc.mif $WEB_SRVR_PATH/wrpc-sw/wrc.$(date +%Y-%m-%d).mif
        ;;

	$eb_path)

		export GSI_BUILD_TYPE=Balloon_release
                make etherbone 2>&1 > $log_makefile/balloon_build_etherbone.$(date +%Y-%m-%d).log
                export PATH=$PATH:$eb_path/toolchain/bin
                make etherbone-install STAGING=/tmp/etherbone
                cd /tmp
		
		tar -cf - etherbone | xz -9 -c - > etherbone.tar.xz
		cp etherbone.tar.xz $WEB_SRVR_PATH/etherbone/etherbone.$(date +%Y-%m-%d).tar.xz
		rm -rf etherbone etherbone.tar.xz
        ;;

        $saftlib_path)

		export GSI_BUILD_TYPE=Balloon_release
                make saftlib 2>&1 > $log_makefile/balloon_build_saftlib.$(date +%Y-%m-%d).log
                export PATH=$PATH:$saftlib_path/toolchain/bin
                make saftlib-install STAGING=/tmp/saftlib
		cd /tmp

                tar -cf - saftlib | xz -9 -c - > saftlib.tar.xz
                cp saftlib.tar.xz $WEB_SRVR_PATH/saftlib/saftlib.$(date +%Y-%m-%d).tar.xz
                rm -rf saftlib saftlib.tar.xz
        ;;


esac

#Below lines remove the 7 days old files by checking the date they were compiled
for bitstream in $GATEWARE_SEVEN_DAYS
do
	if [ -f $bitstream ]; then
		echo Removing old files $bitstream
		rm $bitstream
	else
		echo "No gateware older than 7 days"
	fi
done

for ebone in $EB_SEVEN_DAYS
do
	if [ -f $ebone ]; then
		echo Removing old files $ebone
		rm $ebone
	else
		echo "No etherbone driver older than 7 days"
	fi
done

for wrpc in $WRPC_SEVEN_DAYS
do
	if [ -f $wrpc ]; then
		echo Removing old files $wrpc
		rm $wrpc
	else
        	echo "No wrpc-sw older than 7 days"
	fi
done

for saftl in $SAFTLIB_SEVEN_DAYS
do
	if [ -f $saftl ]; then
		echo Removing old files $saftl
		rm $saftl
	else
        	echo "No saflib driver older than 7 days"
	fi
done

for ftmbin in $FTMBIN_SEVEN_DAYS
do
        if [ -f $ftmbin ]; then
                echo Removing old files $ftmbin
                rm $ftmbin
        else
                echo "No ftm binary file older than 7 days"
        fi
done

