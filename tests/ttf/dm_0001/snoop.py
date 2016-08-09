#!/usr/bin/env python

########################################################################################################################

import sys
import os 
import subprocess

########################################################################################################################

def main():
  # Get arguments
  cmdtotal = len(sys.argv)
  cmdargs = str(sys.argv)
  
  # Plausibility check
  if cmdtotal != 3:
    print "Error: Arguments are {device name} {max. events}"
    sys.exit(1)
  
  # Settings
  device = str(sys.argv[1])
  number_of_events = int(sys.argv[2])
  
  # Create/open log file
  f = open('snooped_events.txt', 'w')
    
  # Snoop events
  event_count = 0
  process = subprocess.Popen(["saft-ctl", device, "snoop", "0x0", "0x0", "0", "-x"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  
  # Wait for events
  while True:
    line = process.stdout.readline()
    if not line: break
    else: 
      #event_count = event_count + 1
      reception_string = line
      reception_string = reception_string.replace("!", " ") # get rid of exclamation marks
      reception_string = reception_string.split()
      
      # Remove PPS events from stream
      if (reception_string[3] == "0xffff000000000000"):
        pass
      # Remove IO LATCH events from stream
      elif (reception_string[3] == "0xfffe000000000000"):
        pass
      # Remove SPECIAL events from stream
      elif (reception_string[3] == "0xfffd000000000000"):
        pass
      else:
        # Write to log file
        f.write(str(reception_string[1]))
        f.write(" ")
        f.write(str(reception_string[3]))
        f.write(" ")
        f.write(str(reception_string[5]))
        f.write("\n")
        event_count = event_count + 1
    
    # Done?
    if (event_count == number_of_events):
      break
    
  # Close log file
  f.close()
  
  # Close snoop process
  process.terminate()
  
  # Done
  sys.exit(0)

########################################################################################################################

if __name__ == "__main__":
  main()
