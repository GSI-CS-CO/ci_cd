#!/bin/bash

cd /opt/quartus/quartus/bin

jtagfile=./jtagchk.txt

./jtagconfig > $jtagfile
EXP_DEVICEID="02A010DD"
PEX_DEVICEID="xxxxxxxx"
VET_DEVICEID="xxxxxxxx"
SCU3_DEVICEID="xxxxxxxx"
SCU2_DEVICEID="xxxxxxxx"
DM_DEVICEID="xxxxxxxx"

if (grep -q $EXP_DEVICEID $jtagfile); then
	echo "Exploder-5a connected"
else
	echo "Exploder-5a unavailable"
fi

if (grep -q $PEX_DEVICEID $jtagfile); then
        echo "Pexxaria-5 connected"
else
        echo "Pexarria-5 unavailable"
fi

if (grep -q $VET_DEVICEID $jtagfile); then
        echo "Vetar2a connected"
else
        echo "Vetar2a unavailable"
fi

if (grep -q $SCU3_DEVICEID $jtagfile); then
        echo "SCU3 connected"
else
        echo "SCU3 unavailable"
fi

if (grep -q $SCU2_DEVICEID $jtagfile); then
        echo "SCU2 connected"
else
        echo "SCU2 unavailable"
fi

if (grep -q $DM_DEVICEID $jtagfile); then
        echo "Datamaster connected"
else
        echo "Datamaster unavailable"
fi
rm $jtagfile
