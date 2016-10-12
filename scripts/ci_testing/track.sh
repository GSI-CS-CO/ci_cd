#!/bin/bash

i=0
n=10

function countdown
{
        local ARR=( $1 )
        local START=$(date +%s)
        local END=$((START + ARR))
        local CUR=$START

        while [[ $CUR -lt $END ]]
        do
                CUR=$(date +%s)
                LEFT=$((END-CUR))

		printf "\r%02d" $((LEFT))
                sleep 1
        done
	echo
}

while [[ $i -lt $n ]]
do
	echo "Exp track phase check"
	saft-ctl exp -s
	echo
	echo "Pex track phase check"
	saft-ctl pex -s
	echo
	countdown 15
	let i++
done

echo "SCU track phase check"
ssh root@scuxl0097.acc.gsi.de 'saft-ctl baseboard -s'
