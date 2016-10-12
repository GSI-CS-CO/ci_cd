#!/bin/bash

exp_IO1_log1=./exp_IO1_log1.log
exp_IO1_log=./exp_IO1_log.log

pex_IO1_log1=./pex_IO1_log1.log
pex_IO1_log=./pex_IO1_log.log

saft-io-ctl exp -w
saft-io-ctl pex -w

saft-io-ctl exp -n IO1 -o 0 -t 1
saft-io-ctl exp -n IO2 -o 0 -t 1
saft-io-ctl exp -n IO3 -o 0 -t 1
saft-pps-gen pex -s > $pex_IO1_log1 &
saft-io-ctl exp -s > $exp_IO1_log1 &
ssh root@scuxl0097.acc.gsi.de '
saft-io-ctl baseboard -w
saft-pps-gen baseboard -s &
sleep 60

echo $!
kill $!
exit'

for pid in `ps -ef | grep [s]aft-io-ctl | awk '{print $2}'` ; do 
echo $pid ;
kill $pid ; 
done

for pid in `ps -ef | grep [s]aft-pps-gen | awk '{print $2}'` ; do
echo $pid ;
kill $pid ;
done

exp_IO1_count=$(wc -l < $exp_IO1_log1)
pex_IO1_count=$(wc -l < $pex_IO1_log1)

if [ "$exp_IO1_count" -ge "60" ]; then
        echo "Count reached required limit";
	sed '203,$d' $exp_IO1_log1 > $exp_IO1_log
	rm $exp_IO1_log1
fi

if [ "$pex_IO1_count" -ge "60" ]; then
        echo "Count reached required limit";
        sed '203,$d' $pex_IO1_log1 > $pex_IO1_log
        rm $pex_IO1_log1
fi
