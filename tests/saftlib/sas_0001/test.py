#!/usr/bin/env python

########################################################################################################################
# 1. Spawns saft-ctl in snoop modus
# 2. Injects events (using saft-ctl)
# 3. Compares snooped and inject events (saved in a XML file)
########################################################################################################################

########################################################################################################################

import numpy as np
import random as rnd
import os 
import subprocess
import sys
import time
import threading

import xml.dom
from xml.dom import minidom

from xml.dom.minidom import Document
from threading import Thread
from multiprocessing import Process

########################################################################################################################

def snoop_events(number_of_events, device):
  # Prepare XML log document
  doc = Document()
  root = doc.createElement('root')
  doc.appendChild(root)
  event_count = 0

  # Snoop events
  process = subprocess.Popen(["saft-ctl", device, "snoop", "0x0", "0x0", "0", "-x"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  
  # Wait for events
  while True:
    line = process.stdout.readline()
    if not line: break
    else: 
      event_count = event_count + 1
      print line
      reception_string = line
      reception_string = reception_string.replace("!", " ") # get rid of exclamation marks
      reception_string = reception_string.split()
      
      # Dump feedback (send stuff) to XML log file
      main = doc.createElement('event')
      root.appendChild(main)
      
      # Log id
      p = doc.createElement('id')
      text = doc.createTextNode(reception_string[3])
      p.appendChild(text)
      main.appendChild(p)
      
      # Log parameter
      p = doc.createElement('parameter')
      text = doc.createTextNode(reception_string[5])
      p.appendChild(text)
      main.appendChild(p)
      
      # Log execution time
      p = doc.createElement('time')
      text = doc.createTextNode(reception_string[1])
      p.appendChild(text)
      main.appendChild(p)
  
    if (event_count == number_of_events):
      break
      
  # Close snoop process
  process.terminate()
  
  # Save events to XML file
  f = open("snooped_events.xml", "w")
  try:
    f.write(doc.toprettyxml(indent="  "))
  finally:
    f.close()
  
  # Done
  return 0

########################################################################################################################

def inject_events(number_of_events, device):
  # Variables
  out_send = [0 for x in range(number_of_events)]
  err_send = [0 for x in range(number_of_events)]
  max_uint64 = np.iinfo(np.uint64).max;
  
  # Prepare XML log document
  doc = Document()
  root = doc.createElement('root')
  doc.appendChild(root)

  # Send events
  for x in range(0, number_of_events):
    eid = np.uint64(rnd.randint(0, max_uint64))
    epara = np.uint64(rnd.randint(0, max_uint64))
    process_send = subprocess.Popen(["saft-ctl", device, "inject", str(eid), str(epara), "0", "-v", "-x",], stdout=subprocess.PIPE)
    out_send[x], err_send[x] = process_send.communicate()
    out_send_split = out_send[x].split()
    
    #print "send string:"
    print out_send[x]
        
    # Dump feedback (send stuff) to XML log file
    main = doc.createElement('event')
    root.appendChild(main)
    
    # Log ID
    if eid == int(out_send_split[3], 0): # check if given id was send
      p = doc.createElement('id')
      text = doc.createTextNode(out_send_split[3])
      p.appendChild(text)
      main.appendChild(p)
    else:
      sys.exit(1)
    
    # Log parameter
    if epara == int(out_send_split[4], 0): # check if given parameter was send
      p = doc.createElement('parameter')
      text = doc.createTextNode(out_send_split[4])
      p.appendChild(text)
      main.appendChild(p)
    else:
      sys.exit(1)
    
    # Log execution tme
    p = doc.createElement('time')
    text = doc.createTextNode(out_send_split[5])
    p.appendChild(text)
    main.appendChild(p)
  
  # Save events to XML file
  f = open("injected_events.xml", "w")
  try:
    f.write(doc.toprettyxml(indent="  "))
  finally:
    f.close()
  
  # Done
  return 0

########################################################################################################################

def main():
  # Get arguments
  cmdtotal = len(sys.argv)
  cmdargs = str(sys.argv)
  
  # Plausibility check
  if cmdtotal != 4:
    print "Error: Arguments are {device name} {max. events} {max. loops}"
    sys.exit(1)
  
  # Settings
  sleep_time = 1
  device = str(sys.argv[1])
  max_events = int(sys.argv[2])
  max_loops = int(sys.argv[3])

  # Generate random test boundaries
  number_of_events = rnd.randint(1, max_events)
  number_of_loops = rnd.randint(1, max_loops)
  
  # Run test cases
  for i in range(1, max_loops+1):
    p_snoop = Process(target=snoop_events, args=(number_of_events, device))
    p_snoop.start()
    time.sleep(sleep_time)
    p_inject = Process(target=inject_events, args=(number_of_events, device))
    p_inject.start()
    p_inject.join()
    p_snoop.join()
    time.sleep(sleep_time)
    if (subprocess.call(["cmp", "injected_events.xml", "snooped_events.xml"])):
      print "Error: Injected and snooped events don't match!"
      sys.exit(1)
  
  # Done
  sys.exit(0)

if __name__ == "__main__":
  main()
