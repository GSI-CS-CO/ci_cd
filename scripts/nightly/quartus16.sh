#!/bin/bash

export QUARTUS_PATH=/opt/quartus
export QUARTUS_ROOTDIR=$QUARTUS_PATH/quartus
export QUARTUS=$QUARTUS_PATH/quartus
export QUARTUS_64BIT=1

export NIOS2EDS=$QUARTUS_PATH/nios2eds
export SOPC_KIT_NIOS2=$QUARTUS_PATH/nios2eds
export NIOS2LINUX=$QUARTUS_PATH/nios2eds

export ALTERAOCLSDKROOT=$QUARTUS_PATH/hld
export QSYS_ROOTDIR=$QUARTUS_PATH/quartus/sopc_builder/bin

export PATH=$PATH:$QUARTUS_PATH/quartus/bin


