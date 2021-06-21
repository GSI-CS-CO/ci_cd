#!/bin/bash
list=update.list
firmware=$1
reboot_only=0

# Check if at least one argument is given
if [ $# -ne 1 ]; then
  echo "Error: Illegal number of parameters, please provide a valid firmware file (or reboot)!"
  exit 1
fi

# Check if firmware (arguments) exists
if [ -f $firmware ]; then
  echo "Info: Using $firmware to update a/all TTF switch(es)!"
  md5sum $firmware
else
  if [ $firmware == "reboot" ]; then
    reboot_only=1
    echo "Info: Rebooting switch(es)!"
  else
    echo "Error: Sorry, can't find file $firmware!"
    exit 1
  fi
fi

# Remove old list (if file exists)
if [ -f $list ]; then
  rm $list
fi

# Create cheap update list
cat ../../switches.json | grep name | awk {'print $7"@"$4""$10"" '} >> $list
sed -i 's/"//g' $list
sed -i 's/,//g' $list

# Start update process
echo "Info: Found the following switch(es):"
cat $list

echo "Info: Starting update:"
lines=$(cat $list)
for line in $lines; do
  echo ""
  echo "**************************************************"
  echo "Info: Updating $line now..."
  if [ $reboot_only -eq 0 ]; then
    echo "-> Deploying firmware..."
    scp $firmware $line":/update"
  fi
  echo "-> Rebooting switch..."
  ssh $line reboot
done

echo "Info: Cleaning up..."
if [ -f $list ]; then
  rm $list
fi

echo "Info: Updated a/all switch(es)!"
