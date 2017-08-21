#!/bin/bash

# this script should be launched from tsl011, because there are 
# 10_timing_backdoors for this machine on all nodes in the testing 
# facility
host=`hostname`
node="tsl011"
if [ ${host} != ${node} ]
	then
	echo "please launch this script on machine ${node}"
fi


helper_script_name="flash_all_timing_receivers.sh"
if [ ! -x ${helper_script_name} ]
	then
	echo "scitp with name ${helper_script_name} was not found"
fi


exit 1;

release_dir="/releases/cherry/gateware"

# flash SCUs
scu_nodes[0]="scuxl0007.acc.gsi.de"
scu_nodes[1]="scuxl0085.acc.gsi.de"
scu_nodes[2]="scuxl0088.acc.gsi.de"
scu_nodes[3]="scuxl0133.acc.gsi.de"
scu_nodes[4]="scuxl0001.acc.gsi.de"
scu_nodes[5]="scuxl0099.acc.gsi.de"
for node in ${scu_nodes[@]}
do
	scp flash_all_timing_receivers.sh "${node}:"
	ssh "${node}" "./flash_all_timing_receivers.sh -r ${release_dir} /dev/wbm0"
done

#flash VETARs
vetar_nodes[0]="kp1cx01.acc.gsi.de"
for node in ${vetar_nodes[@]}
do
	scp flash_all_timing_receivers.sh "${node}:"
	ssh "${node}" "./flash_all_timing_receivers.sh -r ${release_dir} /dev/wbm*"
done

# flash local nodes (USB[4*exploder+1*vetar] & PCIe[4*pexarria])
./flash_all_timing_receivers.sh -r ${release_dir} /dev/wbm* /dev/ttyUSB*
