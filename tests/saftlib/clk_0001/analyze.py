#!/usr/bin/env python 
# ==================================================================================================

# Synopsis
# ==================================================================================================
# Analyzes a given log file, calculates phases and frequencies.
#
# Expected format: <Edge> <Timestamp>
# Example:         0 4123
#                  1 8231
#
# Note: Number of falling and rising edges must be equal.

# Imports
# ==================================================================================================
import sys
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft, arange
from numpy import sin, linspace, pi
from pylab import plot, show, title, xlabel, ylabel, subplot

# Classes
# ==================================================================================================
class IOMeasurement(object):
  # Internal variables
  # ------------------------------------------------------------------------------------------------
  shortest_low_phase      = 0
  longest_low_phase       = 0
  average_low_phase       = 0.0
  shortest_high_phase     = 0
  longest_high_phase      = 0
  average_high_phase      = 0.0
  average_duty_cycle      = 0.0
  average_duty_cycle_low  = 0.0
  average_duty_cycle_high = 0.0
  average_frequeny        = 0.0
  first_edge              = 0
  edges                   =[]
  edges_inv               =[]
  phases                  =[]
  low_phases              =[]
  high_phases             =[]
  timestamps              =[]
  timestamps_diff         =[]
  allowed_uncertainty_ns  = 1
  
  # Initialize Class
  # ------------------------------------------------------------------------------------------------
  def __init__(self, log_file):
    # Analyze log file
    for line in open(log_file) :
      values=line.split(" ")                 # Split edge and timestamp
      values[1]=values[1].replace("\n", "")  # Remove new line character
      self.edges.append(int(values[0]))      # Get edges
      self.timestamps.append(int(values[1])) # Get timestamps
    
    # Invert edges for better "step" plotting
    for i in range(0, (len(self.edges))):
      if int(self.edges[i]) == 1:
        self.edges_inv.append(0)
      else:
        self.edges_inv.append(1)
    
    # Calculate timestamps without offsets
    for i in range(0, (len(self.timestamps))):
      self.timestamps_diff.append(self.timestamps[i]-self.timestamps[0])
    
    # Calculate phases
    for i in range(0, ((len(self.timestamps_diff))-1)):
      self.phases.append(self.timestamps_diff[i+1]-self.timestamps_diff[i])
    
    # Get the first edge
    self.first_edge=int(self.edges[0])
    
    # Get all high and low phases
    length = (len(self.phases))-1
    if self.first_edge == 0:
      for i in range(0,length+1,2):
        self.low_phases.append(self.phases[i])
        if i != 0:
          self.high_phases.append(self.phases[i-1])
    else:
      for i in range(0,length+1,2):
        self.high_phases.append(self.phases[i])
        if i != 0:
          self.low_phases.append(self.phases[i-1])
        
    # Analyze low phases
    self.shortest_low_phase = self.low_phases[0]
    for i in range(0, (len(self.low_phases))):
      if self.shortest_low_phase > self.low_phases[i]:
        self.shortest_low_phase = self.low_phases[i]
        
    self.longest_low_phase = self.low_phases[0]
    for i in range(0, (len(self.low_phases))):
      if self.longest_low_phase < self.low_phases[i]:
        self.longest_low_phase = self.low_phases[i]
    
    phase_len_total = 0.0
    for i in range(0, (len(self.low_phases))):
      phase_len_total = phase_len_total + self.low_phases[i]
    self.average_low_phase = phase_len_total/(len(self.low_phases))
    
    # Analyze high phases
    self.shortest_high_phase = self.high_phases[0]
    for i in range(0, (len(self.high_phases))):
      if self.shortest_high_phase > self.high_phases[i]:
        self.shortest_high_phase = self.high_phases[i]
        
    self.longest_high_phase = self.high_phases[0]
    for i in range(0, (len(self.high_phases))):
      if self.longest_high_phase < self.high_phases[i]:
        self.longest_high_phase = self.high_phases[i]
    
    phase_len_total = 0.0
    for i in range(0, (len(self.high_phases))):
      phase_len_total = phase_len_total + self.high_phases[i]
    self.average_high_phase = phase_len_total/(len(self.high_phases))
    
    # Calculate duty cycle
    average_duty_cycle_full = self.average_low_phase + self.average_high_phase
    self.average_duty_cycle_low  = (100/average_duty_cycle_full) * self.average_low_phase
    self.average_duty_cycle_high  = (100/average_duty_cycle_full) * self.average_high_phase
    
    # Calculate frequency
    self.average_frequeny = (1/average_duty_cycle_full)*1000000000
    
  # Generate plot from sampled edges
  # Argument show:
  #   0: Save as file
  #   1: Show plot
  # ------------------------------------------------------------------------------------------------
  def generate_plot(self, show):
    # Create plot
    xlim_last_item=len(self.timestamps_diff)-1
    xlim_value=(self.timestamps_diff[xlim_last_item])+1
    plt.grid()
    plt.ylim(-0.5, 1.5)
    plt.xlim(-1, xlim_value)
    plt.plot(self.timestamps_diff, self.edges_inv, linewidth=2.0, color='blue', drawstyle='steps', label='Step Format')
    plt.plot(self.timestamps_diff, self.edges,     linewidth=2.0, color='red',  linestyle='--',    label='Unformatted')
    plt.ylabel('Edge [Boolean]')
    plt.xlabel('Time [ns]')
    plt.title('IO Measurement Results')
    plt.legend()
    # Save to file or display plot
    if show == 1:
      plt.show()
    else:
      plt.plot()
      plt.savefig('log/clock.png')
  
  # Dump values
  # ------------------------------------------------------------------------------------------------
  def display(self):
    # Print all data
    print 50 * "="
    print "Edges:"
    print self.edges
    print "Timestamps:"
    print self.timestamps
    print "Timestamps (without offsets):"
    print self.timestamps_diff
    print "Phases:"
    print self.phases
    print "Low Phases:"
    print self.low_phases
    print "High Phases:"
    print self.high_phases
    print "Shortest Low Phase:  %dns" % self.shortest_low_phase
    print "Longest Low Phase:   %dns" % self.longest_low_phase
    print "Average Low Phase:   %fns" % self.average_low_phase
    print "Shortest High Phase: %dns" % self.shortest_high_phase
    print "Longest High Phase:  %dns" % self.longest_high_phase
    print "Average High Phase:  %fns" % self.average_high_phase
    print "Average Duty Cycle:  %f/%f [H/L]" % (self.average_duty_cycle_high, self.average_duty_cycle_low)
    if self.average_frequeny >= 1000000:
      print "Average Frequency:   %fMHz" % (self.average_frequeny/1000000)
    elif self.average_frequeny >= 1000:
      print "Average Frequency:   %fkHz" % (self.average_frequeny/1000)
    else:
      print "Average Frequency:   %fHz" % self.average_frequeny
    print 50 * "="
    
  # Compare results to expected values
  # Argument mode:
  #   0: Compare frequency (uses param1)
  #   1: Compare high and low phase (uses param1 and param2)
  # ------------------------------------------------------------------------------------------------
  def compare(self, mode, param1, param2):
    # Calculate or get the phases
    if mode == 0:
      high_phase_cmp = (int((1.0/int(param1))*1000000000.0))/2
      low_phase_cmp = int(high_phase_cmp)
    else:
      high_phase_cmp = int(param1)
      low_phase_cmp = int(param2)
      
    # Check if phases are fine
    if self.shortest_low_phase <= (low_phase_cmp-self.allowed_uncertainty_ns):
      print "Low phase to short!"
      return 1
    if self.highest_low_phase >= (low_phase_cmp+self.allowed_uncertainty_ns):
      print "Low phase to long!"
      return 1
    if self.shortest_high_phase <= (high_phase_cmp-self.alhighed_uncertainty_ns):
      print "High phase to short!"
      return 1
    if self.highest_high_phase >= (high_phase_cmp+self.alhighed_uncertainty_ns):
      print "High phase to long!"
      return 1
    
    # Results are fine
    return 0
  
# Main
# ==================================================================================================
def main():
  # Get arguments
  cmdtotal = len(sys.argv)
  cmdargs = str(sys.argv)
  app_name = str(sys.argv[0])
  cmp_type = 0
  high_phase_or_frequency = 0
  low_phase = 0
  result = 0
  
  # Plausibility check
  if cmdtotal == 3: # Compare frequency
    high_phase_or_frequency = str(sys.argv[2])
  elif cmdtotal == 4: # Compare phases
    high_phase_or_frequency = str(sys.argv[2])
    low_phase = str(sys.argv[3])
    cmp_type = 1
  else:
    print "Error: Arguments are ambiguous!"
    print cmdtotal
    print ""
    print "Usage:"
    print "%s {log_file_name.txt} {expected frequency [Hz]}" % app_name
    print "or"
    print "%s {log_file_name.txt} {expected high and low phase [ns]}" % app_name    
    sys.exit(1)
  
  # Settings
  log_file_name = str(sys.argv[1])
  
  # Evaluate log file
  data = IOMeasurement(log_file_name)
  data.display()
  data.generate_plot(0)
  result = data.compare(cmp_type, high_phase_or_frequency, low_phase)
  
  # Done
  sys.exit(result)

# Execute main function
# ==================================================================================================
if __name__ == "__main__":
  main()
  
