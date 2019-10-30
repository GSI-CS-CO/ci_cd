#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import time
import socket

########################################################################################################################
v_target = "none"
v_operation = "none"
v_gateware_source = "none"
v_graphite_conf = "graphite.conf"
v_debug = 0
v_interval_seconds = 60
v_host = "127.0.0.1"
v_port = 2003
v_graphite_addr = (v_host, v_port)
v_graphite_prefix = "ttf"
v_metrics = {"temp":"temp", "offset":"offset", "sync":"sync", "offsyn":"offsyn"}
v_msg_graphite = ""

########################################################################################################################
def func_print_space():
    print "----------------------------------------------------------------------------------------------------"

#########################################################################################################################
def func_send_metric(metric_list):
    # send metric set through UDP socket (on remote side run 'nc -ulk <v_port>' to check socket transmission)
    for i in range(len(metric_list)):
        v_sock.sendto(metric_list[i], v_graphite_addr)

#########################################################################################################################
def func_find_option(target, opt_key):
    try:
        timing_tool = "eb-mon"

        if opt_key == "temperature":
            timing_tool = "saft-ctl"

        cmd = "timeout 15 ssh root@%s.acc.gsi.de %s -h" % (target, timing_tool)
        output = subprocess.check_output(cmd.split(), stderr=subprocess.STDOUT)
        if output:
            lines = output.split('\n')
            for line in lines:
                if opt_key in line:
                    opt = line.split()[0].strip()
                    return opt

    except subprocess.CalledProcessError as e:
        print e

#######################################################################################################################
def func_probe():
    # Check gateware
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if (v_target == str(q['type'])) or (v_target == "all"):
                        cmd = "timeout 10 ssh %s@%s%s eb-info %s" % (p['login'], p['name'], p['extension'], q['slot'])
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
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                receivers_string = []
                receivers = []
                for q in p['receivers']:
                    if (v_target == str(q['type'])) or (v_target == "all"):
                        relation = "%s:%s" % ((q['dev_name']), (q['slot']))
                        receivers.append(relation)
                        receivers_string = ' '.join(str(x) for x in receivers)
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
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                saftd_stop_found = 0
                for q in p['receivers']:
                    if (v_target == str(q['type'])) or (v_target == "all"):
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
    func_stop()
    print "Going to sleep for 10 seconds..."
    time.sleep(10+1)
    func_start()

########################################################################################################################
def func_reset():
    # Reset devices and hosts
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
def func_flash():
    # Flash devices
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
def func_get_metric():
    # Get metric (temperature, offset, sync etc)
    cmd_list = []
    test_target = "" # <user>@<tr>.acc.gsi.de

    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if (v_target == str(q['type'])) or (v_target == "all"):
                        # dev = prefix.host.dev.type.role
                        dev = "%s.%s.%s.%s.%s" % (v_graphite_prefix, p['name'], q['dev_name'], q['type'], q['role'])
                        if test_target:
                            cmd = "%s.%s timeout 10 ssh %s saft-ctl -ft bla" % (dev, v_metrics['temp'], test_target)
                            cmd_list.append(cmd)
                            cmd = "%s.%s timeout 10 ssh %s eb-mon -o dev/wbm0" % (dev, v_metrics['offset'], test_target)
                            cmd_list.append(cmd)
                            cmd = "%s.%s timeout 10 ssh %s eb-mon -y dev/wbm0" % (dev, v_metrics['sync'], test_target)
                            cmd_list.append(cmd)
                            cmd = "%s.%s timeout 10 ssh %s eb-mon -oy dev/wbm0" % (dev, v_metrics['offsyn'], test_target)
                            cmd_list.append(cmd)
                        else:
                            cmd = "%s.%s timeout 10 ssh %s@%s%s saft-ctl -t %s" % (dev, v_metrics['temp'], p['login'], p['name'], p['extension'], q['dev_name'])
                            cmd_list.append(cmd)
                            opt = func_find_option(p['name'], "sync") # find a valid option to get WR sync status (option depends on eb-mon version)
                            cmd = "%s.%s timeout 10 ssh %s@%s%s eb-mon -o %s %s" % (dev, v_metrics['offsyn'], p['login'], p['name'], p['extension'], opt, q['slot'])
                            cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

    # Present commands
    for i in range(len(cmd_list)):
        metric_key = cmd_list[i].split()[0]
        cmd = cmd_list[i].partition(metric_key)[2].strip()
        print cmd
        func_print_space()

    # Launch commands
    if v_debug == 0:
        print v_msg_graphite

        while True:
            metric_list = []

            for i in range(len(cmd_list)):
                metric_key = cmd_list[i].split()[0]
                cmd = cmd_list[i].partition(metric_key)[2].strip()

                ts = str(int(time.time()))
                metric = [metric_key]
                try:
                    status = subprocess.check_output(cmd.split(), stderr=subprocess.STDOUT)

                    if v_metrics['temp'] in metric_key:
                        if "(Celsius):" in status:
                            value = status.partition("(Celsius):")[2].strip()
                            metric.append(value)
                            metric.append(ts)
                            metric_list.append(" ".join(metric))
                    if v_metrics['offset'] in metric_key:
                        if status:
                            value = str(status).rstrip('\n')
                            metric.append(value)
                            metric.append(ts)
                            metric_list.append(" ".join(metric))
                    if v_metrics['sync'] in metric_key:
                        if status:
                            value = ""
                            if "TRACKING" in status:
                                value = "100"
                            elif "NO SYNC" in status:
                                value = "20"
                            elif status:
                                value ="0"
                            if value:
                                metric.append(value)
                                metric.append(ts)
                                metric_list.append(" ".join(metric))
                    if v_metrics['offsyn'] in metric_key:
                        values = status.split('\n')
                        for value in values:
                            if value.isdigit(): # offset
                                metric = [metric_key.replace(v_metrics['offsyn'], v_metrics['offset'])]
                                metric.append(str(value))
                                metric.append(ts)
                                metric_list.append(" ".join(metric))
                            elif value:         # sync
                                val = ""
                                if "TRACKING" in value:
                                    val = "100"
                                elif "NO SYNC" in value:
                                    val = "20"
                                elif value:
                                    val = "0"
                                if val:
                                    metric = [metric_key.replace(v_metrics['offsyn'], v_metrics['sync'])]
                                    metric.append(val)
                                    metric.append(ts)
                                    metric_list.append(" ".join(metric))

                except subprocess.CalledProcessError as e:
                    print e

            if metric_list:
                func_send_metric(metric_list)

            time.sleep(v_interval_seconds)

########################################################################################################################
def main():
    # Get arguments
    cmdtotal = len(sys.argv)
    cmdargs = str(sys.argv)
    global v_target
    global v_operation
    global v_gateware_source
    global v_host
    global v_port
    global v_sock
    global v_graphite_addr
    global v_interval_seconds
    global v_graphite_prefix
    global v_msg_graphite

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
            print "Error: Please provide operation name [start target, stop target, restart target, probe target, reset target, flash target [bitstream.rpd], metric target"
            print "Targets: all scu2 scu3 pexarria5 exploder5 microtca pmc vetar2a vetar2a-ee-butis ftm"
            print "Flashing: Target <<all>> is ignored here, please provide a dedicated bitstream here"
            exit(1)
        try:
            if os.path.exists(v_graphite_conf):
                with open(v_graphite_conf) as file:
                    obj = json.load(file)
                    if "host" in obj:
                        v_host = obj['host']
                    if "port" in obj:
                        v_port = obj['port']
                    if "interval" in obj:
                        v_interval_seconds = obj['interval']
                    if "prefix" in obj:
                        v_graphite_prefix = obj['prefix']
            v_msg_graphite = "send TR metrics to %s:%d (host:port) every %d seconds" % (v_host, v_port, v_interval_seconds)
        except (ValueError, KeyError, TypeError):
            print "JSON formar error: %s " % (file)

        v_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        v_graphite_addr = (v_host, v_port)

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
    elif v_operation == "flash":
        if cmdtotal != 4:
            print "Error: Missing bitstream!"
            exit(1)
        else:
            func_flash()
    elif v_operation == "metric":
        func_get_metric()
    else:
        print "Error: Ambiguous arguments!"
        exit(1)

    # Done
    exit(0)

# Main
if __name__ == "__main__":
    main()
