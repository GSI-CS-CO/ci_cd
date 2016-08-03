#!/usr/bin/env python

########################################################################################################################

from lxml import etree
from StringIO import StringIO

########################################################################################################################

class EventMessage(object):
  # Internal variables
  fid = 0
  gid = 0
  evtno = 0
  sid = 0
  bpid = 0
  event = 0
  par = 0
  tef = 0
  offs = 0
  
  # Generate 64 bit EventID field (FID[4] - GID[12] - EVTNO[12] - SID[12] - BPID[14] - Reserved[10])
  def generate_event(self):
    self.event = self.event + (self.bpid  << (10))
    self.event = self.event + (self.sid   << (10+14))
    self.event = self.event + (self.evtno << (10+14+12))
    self.event = self.event + (self.gid   << (10+14+12+12))
    self.event = self.event + (self.fid   << (10+14+12+12+12))
    return 0
  
  # Dump values
  def dump_values(self):
    print 50 * "="
    print "FID:   ", self.fid
    print "GID:   ", self.gid
    print "EVTNO: ", self.evtno
    print "SID:   ", self.sid
    print "BPID:  ", self.bpid
    print "EVENT: ", self.event
    print "PAR:   ", self.par
    print "TEF:   ", self.tef
    print "OFFS:  ", self.offs
    print 50 * "="
    return 0
  
  # Print <deadline> <eventid> <parameter> as hex
  def print_cmp_line(self, iteration, start_time, period):
    tmp = str(format(start_time+(iteration*period)+self.offs, '#016x') + " " + format(self.event, '#016x') + " " + format(self.par, '#016x') + '\n')
    return tmp


########################################################################################################################

def parseBookXML(xmlFile, verbose):

    v_lst = [EventMessage() for _ in range(100)]
    v_starttime = 0
    v_rep = 0
    v_period = 0
    v_messages = 0

    f = open(xmlFile)
    xml = f.read()
    f.close()
 
    tree = etree.parse(StringIO(xml))
    print tree.docinfo.doctype
    context = etree.iterparse(StringIO(xml))
    book_dict = {}
    books = []
    for action, elem in context:
    
      if not elem.text:
          text = "None"
      else:
          text = elem.text
      
      if (verbose == 1):
        print elem.tag + " => " + text
      
      if (elem.tag == "FID"):
        v_lst[v_messages].fid = int(text, 0)
      elif  (elem.tag == "GID"):
        v_lst[v_messages].gid = int(text, 0)
      elif  (elem.tag == "EVTNO"):
        v_lst[v_messages].evtno = int(text, 0)
      elif  (elem.tag == "SID"):
        v_lst[v_messages].sid = int(text, 0)
      elif  (elem.tag == "BPID"):
        v_lst[v_messages].bpid = int(text, 0)
      elif  (elem.tag == "par"):
        v_lst[v_messages].par = int(text, 0)
      elif  (elem.tag == "tef"):
        v_lst[v_messages].tef = int(text, 0)
      elif  (elem.tag == "offs"):
        v_lst[v_messages].offs = int(text, 0)
        
      if (elem.tag == "id"):
        v_messages = v_messages + 1
        
      if (elem.tag == "starttime"):
        v_starttime = int(text, 0)
      elif (elem.tag == "rep"):
        v_rep = int(text, 0)
      elif (elem.tag == "period"):
        v_period = int(text, 0)
    
    print "Found start time:"
    print v_starttime
    print "Found repeatation count:"
    print v_rep
    print "Found period:"
    print v_period
    print "Found messages:"
    print v_messages
    print ""
    
    for x in range(0, v_messages):
      v_lst[x].generate_event()

    f = open('expected_events.txt', 'w')
    for x in range(0, v_rep):
      for y in range(0, v_messages):
        tmp = v_lst[y].print_cmp_line(x, v_starttime, v_period)
        f.write(str(tmp))
    f.close()

if __name__ == "__main__":
    parseBookXML("ring.xml",1)
















