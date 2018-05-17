#!/bin/bash

# Aliases
alias ll='ls -la'
alias ..='cd ..'

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '

# Debug Splash screen
if [ -f /etc/admin ]; then
  echo -e "[\e[38;5;11minfo\e[0m] Timing RTE admin edition is loaded..."
fi
uptime=$(uptime)
echo -e "[\e[38;5;11minfo\e[0m] Uptime:$uptime"
mem=$(free | grep Mem | awk '{print ((100/$2)*$3) "%"}')
echo -e "[\e[38;5;11minfo\e[0m] Memory usage: $mem"
os_release=$(cat /etc/os-release)
echo -e "[\e[38;5;11minfo\e[0m] OS version: $os_release"

# Status
status=$(lsmod | grep wishbone)
if [ $? -eq 0 ]; then
  echo -e "[\e[38;5;82m ok \e[0m] Wishbone kernel driver is loaded..."
else
  echo -e "[\e[38;5;196mfail\e[0m] Wishbone kernel driver is not loaded..."
fi

status=$(lsmod | grep pcie_wb)
if [ $? -eq 0 ]; then
  echo -e "[\e[38;5;82m ok \e[0m] PCIe kernel driver is loaded..."
else
  echo -e "[\e[38;5;196mfail\e[0m] PCIe kernel driver is not loaded..."
fi

status=$(lsmod | grep vmebus)
if [ $? -eq 0 ]; then
  echo -e "[\e[38;5;82m ok \e[0m] VME kernel driver is loaded..."
else
  echo -e "[\e[38;5;196mfail\e[0m] VME kernel driver is not loaded..."
fi

status=$(ps | grep socat | grep -v grep)
if [ $? -eq 0 ]; then
  pid=$(ps | grep socat | grep -v grep | awk '{print $1}')
  echo -e "[\e[38;5;82m ok \e[0m] Socat is running (PID $pid)..."
else
  echo -e "[\e[38;5;196mfail\e[0m] Socat is not running..."
fi

status=$(ps | grep dbus-daemon | grep -v grep)
if [ $? -eq 0 ]; then
  pid=$(ps | grep dbus-daemon | grep -v grep | awk '{print $1}')
  echo -e "[\e[38;5;82m ok \e[0m] DBus daemon is running (PID $pid)..."
else
  echo -e "[\e[38;5;196mfail\e[0m] DBus daemon is not running..."
fi

status=$(ps | grep saftd | grep -v grep)
if [ $? -eq 0 ]; then
  pid=$(ps | grep saftd | grep -v grep | awk '{print $1}')
  echo -e "[\e[38;5;82m ok \e[0m] Saftlib daemon is running (PID $pid)..."
else
  echo -e "[\e[38;5;196mfail\e[0m] Saftlib daemon is not running..."
fi

