#!/bin/bash
#This script creates a log report of the gateware and firmware built from jenkins job
#It creates a tar file of all the *.rpt files and log file for each form factor and places it in the web server.

#Variables
WEB_SRVR_PATH=/var/www/html/releases/
log_makefile=http://tsl002.acc.gsi.de/releases/log/nightly_makefile_log/

jenkins_home=/home/timing/jenkins_jobs
exp_path=$jenkins_home/nightly_build_exploder5/syn/gsi_exploder5/exploder5_csco_tr
pex_path=$jenkins_home/nightly_build_pexarria5/syn/gsi_pexarria5/control
vet_path=$jenkins_home/nightly_build_vetar2a/syn/gsi_vetar2a/wr_core_demo
scu3_path=$jenkins_home/nightly_build_scu3/syn/gsi_scu/control3
scu2_path=$jenkins_home/nightly_build_scu2/syn/gsi_scu/control2
dm_path=$jenkins_home/nightly_build_datamaster/syn/gsi_pexarria5/ftm
vet_eebutis_path=$jenkins_home/nightly_build_vetar2a_ee_butis/syn/gsi_vetar2a/ee_butis

jenkins_job_home=/var/lib/jenkins/jobs

exp_job_path=$jenkins_job_home/nightly_build_exploder5
pex_job_path=$jenkins_job_home/nightly_build_pexarria5
vet_job_path=$jenkins_job_home/nightly_build_vetar2a
scu3_job_path=$jenkins_job_home/nightly_build_scu3
scu2_job_path=$jenkins_job_home/nightly_build_scu2
dm_job_path=$jenkins_job_home/nightly_build_datamaster
vet_eebutis_job_path=$jenkins_job_home/nightly_build_vetar2a_ee_butis

#Create a tar file of log and report for exploder5a
if (grep -rnq $exp_job_path -e "Finished: SUCCESS"); then
	cd $exp_path
	mkdir /tmp/exploder5_$(date +%Y-%m-%d)
	cp *.rpt /tmp/exploder5_$(date +%Y-%m-%d)
	wget $log_makefile/nightly_build_exploder5.$(date +%Y-%m-%d).log -O /tmp/exploder5_$(date +%Y-%m-%d)/nightly_build_exploder5.$(date +%Y-%m-%d).log
	cd /tmp
	tar -cf - exploder5_$(date +%Y-%m-%d) | xz -9 -c - > exploder5_$(date +%Y-%m-%d).tar.xz
	cp exploder5_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
	rm -rf exploder5_$(date +%Y-%m-%d) exploder5_$(date +%Y-%m-%d).tar.xz
	cd $WEB_SRVR_PATH/log/nightly_makefile_log
	rm nightly_build_exploder5.$(date +%Y-%m-%d).log
fi

#Create a tar file of log and report for pexarria5
if (grep -rnq $pex_job_path -e "Finished: SUCCESS"); then
        cd $pex_path
        mkdir /tmp/pexarria5_$(date +%Y-%m-%d)
        cp *.rpt /tmp/pexarria5_$(date +%Y-%m-%d)
        wget $log_makefile/nightly_build_pexarria5.$(date +%Y-%m-%d).log -O /tmp/pexarria5_$(date +%Y-%m-%d)/nightly_build_pexarria5.$(date +%Y-%m-%d).log
        cd /tmp
        tar -cf - pexarria5_$(date +%Y-%m-%d) | xz -9 -c - > pexarria5_$(date +%Y-%m-%d).tar.xz
        cp pexarria5_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
        rm -rf pexarria5_$(date +%Y-%m-%d) pexarria5_$(date +%Y-%m-%d).tar.xz
        cd $WEB_SRVR_PATH/log/nightly_makefile_log
        rm nightly_build_pexarria5.$(date +%Y-%m-%d).log
fi

#Create a tar file of log and report for vetar2a
if (grep -rnq $vet_job_path -e "Finished: SUCCESS"); then
        cd $vet_path
        mkdir /tmp/vetar2a_$(date +%Y-%m-%d)
        cp *.rpt /tmp/vetar2a_$(date +%Y-%m-%d)
        wget $log_makefile/nightly_build_vetar2a.$(date +%Y-%m-%d).log -O /tmp/vetar2a_$(date +%Y-%m-%d)/nightly_build_vetar2a.$(date +%Y-%m-%d).log
        cd /tmp
        tar -cf - vetar2a_$(date +%Y-%m-%d) | xz -9 -c - > vetar2a_$(date +%Y-%m-%d).tar.xz
        cp vetar2a_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
        rm -rf vetar2a_$(date +%Y-%m-%d) vetar2a_$(date +%Y-%m-%d).tar.xz
        cd $WEB_SRVR_PATH/log/nightly_makefile_log
        rm nightly_build_vetar2a.$(date +%Y-%m-%d).log
fi

#Create a tar file of log and report for SCU3
if (grep -rnq $scu3_job_path -e "Finished: SUCCESS"); then
        cd $scu3_path
        mkdir /tmp/scu3_$(date +%Y-%m-%d)
        cp *.rpt /tmp/scu3_$(date +%Y-%m-%d)
        wget $log_makefile/nightly_build_scu3.$(date +%Y-%m-%d).log -O /tmp/scu3_$(date +%Y-%m-%d)/nightly_build_scu3.$(date +%Y-%m-%d).log
        cd /tmp
        tar -cf - scu3_$(date +%Y-%m-%d) | xz -9 -c - > scu3_$(date +%Y-%m-%d).tar.xz
        cp scu3_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
        rm -rf scu3_$(date +%Y-%m-%d) scu3_$(date +%Y-%m-%d).tar.xz
        tar -cf - scu3_$(date +%Y-%m-%d) | xz -9 -c - > scu3_$(date +%Y-%m-%d).tar.xz
        cp scu3_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
        rm -rf scu3_$(date +%Y-%m-%d) scu3_$(date +%Y-%m-%d).tar.xz
        cd $WEB_SRVR_PATH/log/nightly_makefile_log
        rm nightly_build_scu3.$(date +%Y-%m-%d).log
fi

#Create a tar file of log and report for SCU2
if (grep -rnq $scu2_job_path -e "Finished: SUCCESS"); then
        cd $scu2_path
        mkdir /tmp/scu2_$(date +%Y-%m-%d)
        cp *.rpt /tmp/scu2_$(date +%Y-%m-%d)
        wget $log_makefile/nightly_build_scu2.$(date +%Y-%m-%d).log -O /tmp/scu2_$(date +%Y-%m-%d)/nightly_build_scu2.$(date +%Y-%m-%d).log
        cd /tmp
        tar -cf - scu2_$(date +%Y-%m-%d) | xz -9 -c - > scu2_$(date +%Y-%m-%d).tar.xz
        cp scu2_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
        rm -rf scu2_$(date +%Y-%m-%d) scu2_$(date +%Y-%m-%d).tar.xz
        cd $WEB_SRVR_PATH/log/nightly_makefile_log
        rm nightly_build_scu2.$(date +%Y-%m-%d).log
fi

#Create a tar file of log and report for datamaster
if (grep -rnq $dm_job_path -e "Finished: SUCCESS"); then
        cd $dm_path
        mkdir /tmp/dm_$(date +%Y-%m-%d)
        cp *.rpt /tmp/dm_$(date +%Y-%m-%d)
        wget $log_makefile/nightly_build_ftm.$(date +%Y-%m-%d).log -O /tmp/dm_$(date +%Y-%m-%d)/nightly_build_ftm.$(date +%Y-%m-%d).log
        cd /tmp
        tar -cf - dm_$(date +%Y-%m-%d) | xz -9 -c - > dm_$(date +%Y-%m-%d).tar.xz
        cp dm_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
        rm -rf dm_$(date +%Y-%m-%d) dm_$(date +%Y-%m-%d).tar.xz
        cd $WEB_SRVR_PATH/log/nightly_makefile_log
        rm nightly_build_ftm.$(date +%Y-%m-%d).log
fi

#Create a tar file of log and report for vetar2a_eebutis
if (grep -rnq $vet_eebutis_job_path -e "Finished: SUCCESS"); then
        cd $vet_eebutis_path
        mkdir /tmp/vetar2a_eebutis_$(date +%Y-%m-%d)
        cp *.rpt /tmp/vetar2a_eebutis_$(date +%Y-%m-%d)
        wget $log_makefile/nightly_build_vetar2a_eebutis.$(date +%Y-%m-%d).log -O /tmp/vetar2a_eebutis_$(date +%Y-%m-%d)/nightly_build_vetar2a.$(date +%Y-%m-%d).log
        cd /tmp
        tar -cf - vetar2a_eebutis_$(date +%Y-%m-%d) | xz -9 -c - > vetar2a_eebutis_$(date +%Y-%m-%d).tar.xz
        cp vetar2a_eebutis_$(date +%Y-%m-%d).tar.xz $WEB_SRVR_PATH/log/nightly_makefile_log/
        rm -rf vetar2a_eebutis_$(date +%Y-%m-%d) vetar2a_eebutis_$(date +%Y-%m-%d).tar.xz
fi
