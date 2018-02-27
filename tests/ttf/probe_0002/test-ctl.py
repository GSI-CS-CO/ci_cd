#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json

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
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        subprocess.call(cmd_list[i].split())

########################################################################################################################
def func_start():
    pass

########################################################################################################################
def func_stop():
    pass

########################################################################################################################
def func_restart():
    pass

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
    if v_operation == "restart":
        func_restart()
    if v_operation == "probe":
        func_probe()
    else:
        print "Error: Please provide operation name [start/stop/restart/probe]"
        exit(1)

    # Done
    exit(0)

# Main
if __name__ == "__main__":
    main()
