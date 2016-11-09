#!/bin/bash

saftdaemon=$(ps -ef | grep [s]aftd | awk '{print $2}')

if [ "$saftdaemon" != "" ]; then
        echo $saftdaemon
else
        echo "saftd not started. Starting saftd."
        sudo saftd exp:dev/wbm0 pex:dev/wbm1
fi
