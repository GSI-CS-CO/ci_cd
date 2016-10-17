#!/bin/bash

expIOtemp1=./exp_IO1_log.log1
expIOtemp2=./exp_IO1_log.log2
expIO=./exp_IO1_log.log

sed '/Falling/d' $expIO > $expIOtemp1
sed '/Edge/d' $expIOtemp1 > $expIOtemp2
sed '/--/d' $expIOtemp2 > $expIO

rm $expIOtemp1 $expIOtemp2

port=( $(awk '{print $1}' $expIO) )
var=( $(awk '{print $6}' $expIO) )

n=${#var[@]}
i=0

while [[ $i -lt $n ]]
do
	if [ "${port[i]}" == "IO2" ] && [ "${port[i+1]}" == "IO1" ] ; then
		difference=$(( ${var[i+1]} - ${var[i]}))
	        num=`echo "obase=10; $difference" | bc`
        	echo "${var[i+1]} ${port[i+1]} ---- ${var[i]} ${port[i]} Diff= $num ns Switch vs pex"
		echo
	fi

	if [ "${port[i]}" == "IO2" ] && [ "${port[i+2]}" == "IO1" ] ; then
                difference=$(( ${var[i+2]} - ${var[i]}))
                num=`echo "obase=10; $difference" | bc`
                echo "${var[i+2]} ${port[i+2]} ---- ${var[i]} ${port[i]} Diff= $num ns Switch vs pex"
                echo
        fi


	if [ "${port[i]}" == "IO3" ] && [ "${port[i+1]}" == "IO1" ] ; then
                difference=$(( ${var[i+1]} - ${var[i]}))
                num=`echo "obase=10; $difference" | bc`
                echo "${var[i+1]} ${port[i+1]} ---- ${var[i]} ${port[i]} Diff= $num ns Switch vs scu"
                echo
        fi
	let i++
done

rm $expIO
