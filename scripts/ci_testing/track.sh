#!/bin/bash
#This script is used to check if the timing receivers are in tracking mode or not
#The check is repeated several times to be sure that the timing receivers are active

#Initial and final values for the number of checks to be performed
i=0
n=10

#This function is used to countdown the timer before performing
#the next check. The function displays the remaining time in seconds by
#simply subtracting current time with end time to start next check
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

#Conditional check. Stay in the loop if variable 'i' is less than variable 'n'
#and increment the value of i.
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
