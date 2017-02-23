#!/bin/bash
#This script gives the status information about gateware that was built by Jenkins.
#It informs if the current jenkins job was built successfully or not. It also gives the build date and time of binary files (.jic, .rpd, .sof)

#Variables
WEB_SRVR_PATH=/var/www/html/releases/nightly
exp_job_path=/var/lib/jenkins/jobs/nightly_build_exploder5
pex_job_path=/var/lib/jenkins/jobs/nightly_build_pexarria5
vet_job_path=/var/lib/jenkins/jobs/nightly_build_vetar2a
scu3_job_path=/var/lib/jenkins/jobs/nightly_build_scu3
scu2_job_path=/var/lib/jenkins/jobs/nightly_build_scu2
dm_job_path=/var/lib/jenkins/jobs/nightly_build_datamaster
wrpc_job_path=/var/lib/jenkins/jobs/nightly_build_wrpc-sw
eb_job_path=/var/lib/jenkins/jobs/nightly_build_etherbone
saftlib_job_path=/var/lib/jenkins/jobs/nightly_build_etherbone
vet_eebutis_job_path=/var/lib/jenkins/jobs/nightly_build_vetar2a_ee_butis
LOG_FILE_PATH=/var/www/html/releases/log

#Check if wrpc-sw was built successfully
if (grep -rnq $wrpc_job_path -e "Finished: SUCCESS"); then
        echo "WRPC-SW project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/wrpc-sw
        stat -c %n%y wrc* >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "WRPC-SW project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if etherbone was built successfully
if (grep -rnq $eb_job_path -e "Finished: SUCCESS"); then
        echo "Etherbone project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
	cd $WEB_SRVR_PATH/etherbone
	stat -c %n%y etherbone* >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "Etherbone project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if saftlib was built successfully
if (grep -rnq $saftlib_job_path -e "Finished: SUCCESS"); then
        echo "Saftlib project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/saftlib
        stat -c %n%y saftlib* >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "Saftlib project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if gateware for exploder5a form factor was built successfully
if (grep -rnq $exp_job_path -e "Finished: SUCCESS"); then
	echo "EXP5a project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
	cd $WEB_SRVR_PATH/gateware
	stat -c %n%y exploder5_csco_tr* >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
else
	echo "EXP5a project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if gateware for pexarria5 form factor was built successfully
if (grep -rnq $pex_job_path -e "Finished: SUCCESS"); then
        echo "PEX5 project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/gateware
        stat -c %n%y pci_control* >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "PEX5 project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if gateware for vetar2a (VME) form factor was built successfully
if (grep -rnq $vet_job_path -e "Finished: SUCCESS"); then
        echo "VET2A project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/gateware
        stat -c %n%y vetar2a.* >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "VET2A project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if gateware for SCU3 form factor was built successfully
if (grep -rnq $scu3_job_path -e "Finished: SUCCESS"); then
        echo "SCU3 project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/gateware
        stat -c %n%y scu_control3* >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "SCU3 project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if gateware for SCU2 form factor was built successfully
if (grep -rnq $scu2_job_path -e "Finished: SUCCESS"); then
        echo "SCU2 project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/gateware
        stat -c %n%y scu_control2* >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "SCU2 project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
	echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if gateware for datamaster was built successfully
if (grep -rnq $dm_job_path -e "Finished: SUCCESS"); then
        echo "Datamaster project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/gateware
        stat -c %n%y ftm* >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "Datamaster project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
fi

#Check if gateware for vetar2a_eebutis form factor was built successfully
if (grep -rnq $vet_eebutis_job_path -e "Finished: SUCCESS"); then
        echo "VET2A_EE_BUTIS project build status OK" >> $WEB_SRVR_PATH/nightly_build.log
        cd $WEB_SRVR_PATH/gateware
        stat -c %n%y vetar2a_eebutis* >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
else
        echo "VET2A_EE_BUTIS project build status not OK" >> $WEB_SRVR_PATH/nightly_build.log
        echo >> $WEB_SRVR_PATH/nightly_build.log
fi

mv $WEB_SRVR_PATH/nightly_build.log $LOG_FILE_PATH
