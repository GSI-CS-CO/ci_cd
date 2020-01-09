#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import time

########################################################################################################################
v_target = "none"
v_operation = "none"
v_gateware_source = "none"
v_debug = 1

########################################################################################################################
def func_print_space():
    print "----------------------------------------------------------------------------------------------------"

########################################################################################################################
def func_probe():
    # Check gateware
    global v_target
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if (v_target == str(q['type'])) or (v_target == "all"):
                        cmd = "timeout 10 ssh %s@%s%s eb-info %s" % (p['login'], p['name'], p['extension'], q['slot'])
                        cmd_list.append(cmd)
                        cmd = "timeout 10 ssh %s@%s%s eb-ls %s" % (p['login'], p['name'], p['extension'], q['slot'])
                        cmd_list.append(cmd)
                        cmd = "timeout 10 ssh %s@%s%s saft-ctl %s -i" % (p['login'], p['name'], p['extension'], q['dev_name'])
                        cmd_list.append(cmd)
                        cmd = "timeout 10 ssh %s@%s%s saft-ctl %s -s" % (p['login'], p['name'], p['extension'], q['dev_name'])
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        if v_debug == 0:
            cmd_to_perform_info = cmd_list[i].split()[3]
            print "Probing %s..." % (cmd_to_perform_info)
            subprocess.call(cmd_list[i].split())
        else:
            print cmd_list[i]
        func_print_space()

########################################################################################################################
def func_start():
    # Start saftd
    global v_target
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                receivers_string = []
                receivers = []
                for q in p['receivers']:
                    if ("ftm" == str(q['type'])) or (v_target == "ftm"):
                        pass
                    elif (v_target == str(q['type'])) or (v_target == "all"):
                        relation = "%s:%s" % ((q['dev_name']), (q['slot']))
                        receivers.append(relation)
                        receivers_string = ' '.join(str(x) for x in receivers)
                    else:
                        pass
                if receivers_string:
                    if p['csco_ramdisk'] == "no":
                        cmd = "timeout 10 ssh %s@%s%s `saftd %s`" % (p['login'], p['name'], p['extension'], receivers_string)
                    else:
                        cmd = "timeout 10 ssh %s@%s%s `/usr/sbin/saftd %s`" % (p['login'], p['name'], p['extension'], receivers_string)
                    cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        if v_debug == 0:
            cmd_to_perform = cmd_list[i].split()
            cmd_to_perform_info = cmd_to_perform[3]
            print "Starting saftd at %s..." % (cmd_to_perform_info)
            subprocess.call(cmd_list[i].split())
            time.sleep(1)
        else:
            print cmd_list[i]
        func_print_space()

########################################################################################################################
def func_stop():
    # Stop saftd
    global v_target
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                saftd_stop_found = 0
                for q in p['receivers']:
                    if ("ftm" == str(q['type'])) or (v_target == "ftm"):
                        pass
                    elif (v_target == str(q['type'])) or (v_target == "all"):
                        if saftd_stop_found == 0:
                            cmd = "timeout 10 ssh %s@%s%s killall saftd" % (p['login'], p['name'], p['extension'])
                            cmd_list.append(cmd)
                            cmd = "timeout 10 ssh %s@%s%s killall saft-ctl" % (p['login'], p['name'], p['extension'])
                            cmd_list.append(cmd)
                            cmd = "timeout 10 ssh %s@%s%s killall saft-pps-gen" % (p['login'], p['name'], p['extension'])
                            cmd_list.append(cmd)
                            cmd = "timeout 10 ssh %s@%s%s killall saft-io-ctl" % (p['login'], p['name'], p['extension'])
                            cmd_list.append(cmd)
                            saftd_stop_found = 1
                    else:
                        pass
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        if v_debug == 0:
            cmd_to_perform = cmd_list[i].split()
            cmd_to_perform_info = cmd_to_perform[3]
            print "Stopping saftd and tools at %s..." % (cmd_to_perform_info)
            subprocess.call(cmd_to_perform)
            time.sleep(1)
        else:
            print cmd_list[i]
        func_print_space()

########################################################################################################################
def func_restart():
    # Restart saftd
    global v_target
    func_stop()
    print "Going to sleep for 10 seconds..."
    time.sleep(10+1)
    func_start()

########################################################################################################################
def func_reset():
    # Reset devices and hosts
    global v_target
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                host_reset_found = 0
                host_has_target_devices = 0
                for q in p['receivers']:
                    if (v_target == str(q['type'])) or (v_target == "all"):
                        cmd = "timeout 10 ssh %s@%s%s eb-reset %s fpgareset" % (p['login'], p['name'], p['extension'], q['slot'])
                        cmd_list.append(cmd)
                        host_has_target_devices = 1
                if (p['reset2host'] == "no") and (host_has_target_devices == 1):
                    if host_reset_found == 0:
                        if p['csco_ramdisk'] == "no":
                            cmd = "timeout 10 ssh %s@%s%s reboot" % (p['login'], p['name'], p['extension'])
                        else:
                            cmd = "timeout 10 ssh %s@%s%s /sbin/reboot" % (p['login'], p['name'], p['extension'])
                        cmd_list.append(cmd)
                        host_reset_found = 1
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        if v_debug == 0:
            cmd_to_perform = cmd_list[i].split()
            cmd_to_perform_info = cmd_to_perform[3]
            print "Resetting device(s) and host at %s..." % (cmd_to_perform_info)
            subprocess.call(cmd_to_perform)
            time.sleep(1)
        else:
            print cmd_list[i]
        func_print_space()

########################################################################################################################
def func_wrstatreset():
    # Reset statistics for eCPU stalls and WR time
    global v_target
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                host_has_target_devices = 0
                for q in p['receivers']:
                    if (v_target == str(q['type'])) or (v_target == "all"):
                        cmd = "timeout 10 ssh %s@%s%s eb-mon %s wrstatreset 8 50000;" % (p['login'], p['name'], p['extension'], q['slot'])
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        if v_debug == 0:
            cmd_to_perform = cmd_list[i].split()
            cmd_to_perform_info = cmd_to_perform[3]
            print "Resetting statistics for eCPU stalls and WR time at %s..." % (cmd_to_perform_info)
            subprocess.call(cmd_to_perform)
            time.sleep(1)
        else:
            print cmd_list[i]
        func_print_space()

########################################################################################################################
def func_flash(secure_mode):
    # Flash devices
    global v_target
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if (v_target == "all"):
                        pass
                    elif (v_target == str(q['type'])):
                        cmd = "timeout 10 ssh %s@%s%s rm %s" % (p['login'], p['name'], p['extension'], v_gateware_source)
                        cmd_list.append(cmd)
                        cmd = "timeout 120 scp %s %s@%s%s:/ " % (v_gateware_source, p['login'], p['name'], p['extension'])
                        cmd_list.append(cmd)
                        cmd = "timeout 720 ssh %s@%s%s eb-reset %s cpuhalt 0xff" % (p['login'], p['name'], p['extension'], q['slot'])
                        cmd_list.append(cmd)
                        if secure_mode:
                            if (v_target == "scu2" or v_target == "scu3" or v_target == "vetar2a" or v_target == "vetar2a-ee-butis"):
                                cmd = "timeout 900 ssh %s@%s%s eb-flash -s 0x40000 -w 3 %s /%s" % (p['login'], p['name'], p['extension'], q['slot'], v_gateware_source)
                            else:
                                cmd = "timeout 900 ssh %s@%s%s eb-flash -s 0x10000 -w 3 %s /%s" % (p['login'], p['name'], p['extension'], q['slot'], v_gateware_source)
                        else:
                            cmd = "timeout 720 ssh %s@%s%s eb-flash %s /%s" % (p['login'], p['name'], p['extension'], q['slot'], v_gateware_source)
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        if v_debug == 0:
            cmd_to_perform = cmd_list[i].split()
            cmd_to_perform_info = cmd_to_perform[3]
            print "Flashing device(s) at/with %s..." % (cmd_to_perform_info)
            subprocess.call(cmd_list[i].split())
            time.sleep(1)
        else:
            print cmd_list[i]
        func_print_space()

########################################################################################################################
def main():
    # Get arguments
    cmdtotal = len(sys.argv)
    cmdargs = str(sys.argv)
    global v_target
    global v_operation
    global v_gateware_source

    # Plausibility check
    try:
        if cmdtotal == 3:
            v_operation = str(sys.argv[1])
            v_target = str(sys.argv[2])
        elif cmdtotal == 4:
            v_operation = str(sys.argv[1])
            v_target = str(sys.argv[2])
            v_gateware_source = str(sys.argv[3])
        else:
            print "Error: Please provide operation name [start target, stop target, restart target, probe target, reset target, wrstatreset target, flash(_secure) target [bitstream.rpd]"
            print "Targets: all scu2 scu3 pexarria5 exploder5 microtca pmc vetar2a vetar2a-ee-butis ftm"
            print "Flashing: Target <<all>> is ignored here, please provide a dedicated bitstream here"
            exit(1)
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
    elif v_operation == "reset":
        func_reset()
    elif v_operation == "wrstatreset":
        func_wrstatreset()
    elif v_operation == "flash":
        if cmdtotal != 4:
            print "Error: Missing bitstream!"
            exit(1)
        else:
            func_flash(0)
    elif v_operation == "flash_secure":
        if cmdtotal != 4:
            print "Error: Missing bitstream!"
            exit(1)
        else:
            func_flash(1)
    else:
        print "Error: Ambiguous arguments!"
        exit(1)

    # Done
    exit(0)

# Main
if __name__ == "__main__":
    main()
