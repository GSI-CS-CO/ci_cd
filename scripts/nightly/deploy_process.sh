#!/bin/bash

. ./dev_status.sh -f cicd
if [ "$GLOBAL_VAR2" == "1" ]; then
	for i in 1 2 
	do
		. ./flash.sh -f cicd -d $keyword 
	done
else
	. ./nightly_build_programmer.sh
fi

. ./reset.sh -f cicd -u timing -p tsl004 -d $keyword

. ./dev_status.sh -f cicd 

centos_nfs_path=/common/usr/nfs/centos7
debian_nfs_path=/common/usr/nfs/debian_316
scu_nfs_path=/common/usr/nfs/scu
etherbone_path=/home/timing/jenkins_jobs/nightly_build_etherbone
saftlib_path=/home/timing/jenkins_jobs/nightly_build_saftlib

cd $etherbone_path
sudo make etherbone-install STAGING=$centos_nfs_path
sudo make etherbone-install STAGING=$debian_nfs_path
sudo make etherbone-install STAGING=$scu_nfs_path

cd $saftlib_path
sudo make saftlib-install STAGING=$centos_nfs_path
sudo make saftlib-install STAGING=$debian_nfs_path
sudo make saftlib-install STAGING=$scu_nfs_path

