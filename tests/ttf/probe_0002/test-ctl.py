#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import time

########################################################################################################################
v_operation = "none"

########################################################################################################################
def func_probe():
    # Check gateware
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    cmd = "ssh %s@%s%s eb-info %s" % (p['login'], p['name'], p['extension'], q['slot'])
                    cmd_list.append(cmd)
                    cmd = "ssh %s@%s%s saft-ctl %s -i" % (p['login'], p['name'], p['extension'], q['dev_name'])
                    cmd_list.append(cmd)
                    cmd = "ssh %s@%s%s saft-ctl %s -s" % (p['login'], p['name'], p['extension'], q['dev_name'])
                    cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        subprocess.call(cmd_list[i].split())
        print "----------------------------------------------------------------------------------------------------"

########################################################################################################################
def func_start():
    # Start saftd
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                receivers = []
                for q in p['receivers']:
                    relation = "%s:%s" % ((q['dev_name']), (q['slot']))
                    receivers.append(relation)
                receivers_string = ' '.join(str(x) for x in receivers)
                if p['csco_ramdisk'] == "no":
                    cmd = "ssh %s@%s%s `saftd %s`" % (p['login'], p['name'], p['extension'], receivers_string)
                else:
                    cmd = "ssh %s@%s%s `/usr/sbin/saftd %s`" % (p['login'], p['name'], p['extension'], receivers_string)
                cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        print cmd_list[i]
        cmd_to_perform = cmd_list[i].split()
        cmd_to_perform_info = cmd_to_perform[1]
        print "Starting saftd at %s..." % (cmd_to_perform_info)
        subprocess.call(cmd_to_perform)
        time.sleep(1)
        print "----------------------------------------------------------------------------------------------------"

########################################################################################################################
def func_stop():
    # Stop saftd
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                cmd = "ssh %s@%s%s killall saftd" % (p['login'], p['name'], p['extension'])
                cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        cmd_to_perform = cmd_list[i].split()
        cmd_to_perform_info = cmd_to_perform[1]
        print "Stopping saftd at %s..." % (cmd_to_perform_info)
        subprocess.call(cmd_to_perform)
        time.sleep(1)
        print "----------------------------------------------------------------------------------------------------"

########################################################################################################################
def func_restart():
    # Restart saftd
    func_stop()
    print "Going to sleep for 10 seconds..."
    time.sleep(10+1)
    func_start()

########################################################################################################################
def main():
    # Get arguments
    cmdtotal = len(sys.argv)
    cmdargs = str(sys.argv)
    global v_operation

    # Plausibility check
    if cmdtotal != 2:
        print "Error: Please provide operation name [start/stop/restart/probe]"
        exit(1)
    else:
        try:
            v_operation = str(sys.argv[1])
        except:
            print "Error: Could not parse given arguments!"
            exit(1)

    # Perform operation
    if v_operation == "start":
        func_start()
    elif v_operation == "stop":
        func_stop()
    elif v_operation == "restart":
        func_restart()
    elif v_operation == "probe":
        func_probe()
    else:
        print "Error: Please provide operation name [start/stop/restart/probe]"
        exit(1)

    # Done
    exit(0)

# Main
if __name__ == "__main__":
    main()
