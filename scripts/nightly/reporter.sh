#!/bin/bash
# Usage
# =================================================================================================
# ./reporter.sh <target_name>
# -> <target_name> must match with job name (ftm, exploder5, pexarria5, ...)

# Custom settings
# =================================================================================================
# Which warnings do you want to ignore?
warnings_to_ignore=(
                     125092 # Tcl Script File <name> not found...
                     18236  # Number of processors has not been specified...
                     20013  # Ignored <n> assignments for entity <name> -- entity does not exist in design...
                     14320  # Synthesized away node <name>...
                     18060  # Ignored Maximum Fan-Out logic option for node <name>...
                     13040  # Bidirectional pin <name> has no driver...
                     20013  # Ignored <n> assignments for entity <name> -- entity does not exist in design...
                     13049  # Converted tri-state buffer "comb~synth" feeding internal logic into a wire...
                     276027 # Inferred dual-clock RAM node <name>...
                     12161  # Node <path><name> is stuck at GND because node is in wire loop and does not have a source...
                     176251 # Ignoring some wildcard destinations of fast I/O register assignmen...
                     15705  # Ignored locations or region assignments to the following nodes...
                     15706  # Node <name> is assigned to location or region, but does not exist in design...
                   )

# Which information messages do you want?
info_to_get=(
              332146 # Worst-case <type> slack is <f>...
              332119 # Slack - End Point - TNS Clock...
              332114 # Typical MTBF of Design is...
            )

# Which files do you want to scan?
report_files=(
               $(find . -name "*asm.rpt")
               $(find . -name "*fit.rpt")
               $(find . -name "*flow.rpt")
               $(find . -name "*map.rpt")
               $(find . -name "*sta.rpt")
             )

# Start report filter
# =================================================================================================
# Create report file
target=$1
if [ -f $target.rpt ]; then
  rm $target.rpt
fi
touch $target.rpt

# Initialize file
echo `date` >> $target.rpt
echo "" >> $target.rpt

# Iterate files
for j in "${report_files[@]}"
do
  report_file=$j
  echo "Content of $report_file" >> $target.rpt
  echo "================================================================================" >> $target.rpt
  while read LINE
  do
    # Get warnings from file
    temp=$(echo $LINE | grep "Warning")
    for i in "${warnings_to_ignore[@]}"
    do
      temp=$(echo $temp | grep -v "Warning ($i)")
    done
    # Now warnings found? Check for information
    if [ -z "$temp" -a "$temp" != " " ]; then
      for h in "${info_to_get[@]}"
      do
        if [ -z "$temp" -a "$temp" != " " ]; then
          temp=$(echo $LINE | grep "Info ($h)")
        fi
      done
    fi
    # Check if string is neither empty nor space in shell script
    if [ ! -z "$temp" -a "$temp" != " " ]; then
      echo $temp >> $target.rpt
    fi
  done <$report_file
done
