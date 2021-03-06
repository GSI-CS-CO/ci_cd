#!/usr/bin/env python

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

########################################################################################################################

def main():
  # Boundaries
  max_events = 25 # <strike>Don't use a value beyond 40, this will cause a segfault</strike> 
  max_period = 250000000
  min_period = 50000000
  max_rep    = 1000
  
  max_fid    = 0xf
  max_gid    = 0xfff - 3 # -2 (PPS=0xfff, LATCH=0xffe, SPECIAL=0xffd)
  max_evtno  = 0xfff
  max_sid    = 0xfff
  max_bpid   = 0x3fff
  max_res_id = 0x3ff # Unused
  max_par    = 0xffffffffffffffff
  max_tef    = 0x0 # Always zero (0xffffffff planned)
  max_res    = 0xffffffff # Unused
  
  # Generate parameters
  events   = rnd.randint(1, max_events)
  period   = rnd.randint(min_period, max_period)
  rep      = rnd.randint(1, max_rep)
  max_offs = period - 1
  offs_lst = []
  
  
  # Create random messages
  rnd_fid = []
  rnd_gid = []
  rnd_evtno = []
  rnd_sid = []
  rnd_bpid = []
  rnd_par = []
  rnd_tef = []
  rnd_offs = []
  for x in range(0, events):
    rnd_fid.append(rnd.randint(0, max_fid))
    rnd_gid.append(rnd.randint(0, max_gid))
    rnd_evtno.append(rnd.randint(0, max_evtno))
    rnd_sid.append(rnd.randint(0, max_sid))
    rnd_bpid.append(rnd.randint(0, max_bpid))
    rnd_par.append(rnd.randint(0, max_par))
    rnd_tef.append(rnd.randint(0, max_tef))
    rnd_offs.append(rnd.randint(0, max_offs))
  # Sort offsets
  rnd_offs.sort()
    
  # Output parameters
  print "Events:      " + str(events)
  print "Repetitions: " + str(rep)
  print "Period:      " + str(period) + "ns"
  print "Duration:    " + str((period*rep)) + "ns"
  print "Rate~:       " + str((period/events)) + "ns"
  print "Frequency~:  " + str((1.0/(period/events))*1000000000) + "Hz"
  print ""
  
  # Prepare schedule
  doc = Document()
  page = doc.createElement('page')
  doc.appendChild(page)
  
  meta = doc.createElement('meta')
  page.appendChild(meta)
  
  p = doc.createElement('startplan')
  text = doc.createTextNode("A")
  p.appendChild(text)
  meta.appendChild(p)
  
  p = doc.createElement('altplan')
  text = doc.createTextNode("B")
  p.appendChild(text)
  meta.appendChild(p)
  
  plan = doc.createElement('plan')
  page.appendChild(plan)
  
  metap = doc.createElement('meta')

  p = doc.createElement('starttime')
  text = doc.createTextNode("___STARTTIME___")
  p.appendChild(text)
  metap.appendChild(p)

  p = doc.createElement('lastjump')
  text = doc.createTextNode("idle")
  p.appendChild(text)
  metap.appendChild(p)

  plan.appendChild(metap)
  
  chain = doc.createElement('chain')
  plan.appendChild(chain)
  
  metax = doc.createElement('meta')
  
  p = doc.createElement('rep')
  text = doc.createTextNode(str(rep))
  p.appendChild(text)
  metax.appendChild(p)
  
  p = doc.createElement('period')
  text = doc.createTextNode(str(period))
  p.appendChild(text)
  metax.appendChild(p)
  
  p = doc.createElement('branchpoint')
  text = doc.createTextNode("yes")
  p.appendChild(text)
  metax.appendChild(p)
  
  chain.appendChild(metax)
  
  # Print generated random messages
  for x in range(0, events):
    msg = doc.createElement('msg')
  
    inner_id = doc.createElement('id')
    
    p = doc.createElement('FID')
    text = doc.createTextNode(str(rnd_fid[x]))
    p.appendChild(text)
    inner_id.appendChild(p)
    
    p = doc.createElement('GID')
    text = doc.createTextNode(str(rnd_gid[x]))
    p.appendChild(text)
    inner_id.appendChild(p)
    
    p = doc.createElement('EVTNO')
    text = doc.createTextNode(str(rnd_evtno[x]))
    p.appendChild(text)
    inner_id.appendChild(p)
    
    p = doc.createElement('SID')
    text = doc.createTextNode(str(rnd_sid[x]))
    p.appendChild(text)
    inner_id.appendChild(p)
    
    p = doc.createElement('BPID')
    text = doc.createTextNode(str(rnd_bpid[x]))
    p.appendChild(text)
    inner_id.appendChild(p)
    
    msg.appendChild(inner_id)
    
    chain.appendChild(msg)
    
    p = doc.createElement('par')
    text = doc.createTextNode(str(format(rnd_par[x], '#018x')))
    p.appendChild(text)
    msg.appendChild(p)
    
    p = doc.createElement('tef')
    text = doc.createTextNode(str(rnd_tef[x]))
    p.appendChild(text)
    msg.appendChild(p)
    
    p = doc.createElement('offs')
    text = doc.createTextNode(str(rnd_offs[x]))
    p.appendChild(text)
    msg.appendChild(p)
    
  # Save events to XML file
  f = open("log/schedule.xml", "w")
  try:
    f.write(doc.toprettyxml(indent="  "))
  finally:
    f.close()
  
  # Done
  return 0

if __name__ == "__main__":
  main()
