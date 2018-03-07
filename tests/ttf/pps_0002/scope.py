#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import time
import signal
import multiprocessing
import random
import threading
import matplotlib.pyplot as plt
import numpy as np
from PyQt4 import QtGui
import matplotlib.pyplot as plt
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.backends.backend_qt4agg import NavigationToolbar2QTAgg as NavigationToolbar

########################################################################################################################
l_sorted_edges = []
l_sorted_positive_edges = []
l_monitor_devices = []
l_io_mapping_table = []
v_collected_sampled_edges = []
v_collected_positve_sampled_edges = []
v_finish_test = 0
v_monitors = 0
v_legend = True
v_ax = 0

########################################################################################################################
class PrettyWidget(QtGui.QWidget):
    def __init__(self):
        super(PrettyWidget, self).__init__()
        self.initUI()

    def initUI(self):
        self.setGeometry(800,400, 1000, 600)
        self.center()
        self.setWindowTitle('PPS Monitor')

        grid = QtGui.QGridLayout()
        self.setLayout(grid)

        btn1 = QtGui.QPushButton('Refresh', self)
        btn1.resize(btn1.sizeHint())
        btn1.clicked.connect(self.refresh_button)
        grid.addWidget(btn1, 3,0)

        btn2 = QtGui.QPushButton('Close', self)
        btn2.resize(btn2.sizeHint())
        btn2.clicked.connect(self.close_button)
        grid.addWidget(btn2, 3,2)

        btn3 = QtGui.QPushButton('Hide Legend', self)
        btn3.resize(btn3.sizeHint())
        btn3.clicked.connect(self.hide_legend_button)
        grid.addWidget(btn3, 3,1)

        self.figure = plt.figure(figsize=(15,5))
        self.canvas = FigureCanvas(self.figure)
        self.toolbar = NavigationToolbar(self.canvas, self)
        grid.addWidget(self.canvas, 1,0,1,3)
        grid.addWidget(self.toolbar, 0,0,1,3)

        self.show()

    def hide_legend_button(self):
        global v_ax

        if (v_ax == 0):
            pass
        else:
            egend = v_ax.legend('')
            self.canvas.draw()

    def refresh_button(self):
        global l_sorted_positive_edges
        global l_io_mapping_table
        global v_ax

        plt.cla()
        ax = self.figure.add_subplot(111)
        v_ax = ax
        ax.grid()
        ts_start_max = 0
        ts_end_min = 9999999999999999999
        for i in range(len(l_sorted_positive_edges)):
            time_diff = []
            for j in range(len(l_sorted_positive_edges[i])):
                # Catch negative offset from switch
                if l_sorted_positive_edges[i][j]%1000000000 > 999999000:
                    neg_offset = (l_sorted_positive_edges[i][j]%1000000000)-1000000000
                    time_diff.append(neg_offset)
                else:
                    time_diff.append(l_sorted_positive_edges[i][j]%1000000000)
                if ts_start_max < l_sorted_positive_edges[i][0]:
                    ts_start_max = l_sorted_positive_edges[i][0]
                if ts_end_min > l_sorted_positive_edges[i][(len(l_sorted_positive_edges[i])-1)]:
                  ts_end_min = l_sorted_positive_edges[i][len(l_sorted_positive_edges[i])-1]
            ax.plot(l_sorted_positive_edges[i],time_diff, linewidth=2, marker='p', label=l_io_mapping_table[i],)
        ax.set_xlim(ts_start_max,ts_end_min)
        ax.legend()
        ax.set_title('Timestamp vs Offset to Reference')
        ax.set_xlabel('Timestamp TAI [ns]')
        ax.set_ylabel('$\delta$t [ns]')
        self.canvas.draw()

    def close_button(self):
        global v_finish_test
        v_finish_test = 1
        self.close()

    def center(self):
        qr = self.frameGeometry()
        cp = QtGui.QDesktopWidget().availableGeometry().center()
        qr.moveCenter(cp)
        self.move(qr.topLeft())

########################################################################################################################
class c_monitor:
    v_name = ""
    v_login = ""
    v_extension = ""
    v_dev_name = ""
    v_sampled_edges = []

    def __init__(self, name, login, extension, dev_name):
        self.v_name = name
        self.v_login = login
        self.v_extension = extension
        self.v_dev_name = dev_name

    def func_show_vars(self):
        print ("Found device {} at host {}@{}{}".format(self.v_dev_name, self.v_login, self.v_name, self.v_extension))

########################################################################################################################
def signal_handler(signal, frame):
    # Vars
    global v_finish_test

    # Catch CTRL+C
    v_finish_test = 1
    print ("Caught CTRL+C => Sampling will finish now...")

########################################################################################################################
def func_discover_monitors():
    # Vars
    global l_monitor_devices
    global v_monitors

    # Find all PPS monitor devices in list
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if q['role'] == "pps_monitor":
                        l_monitor_devices.append(c_monitor(p['name'], p['login'], p['extension'], q['dev_name']))
                        v_monitors += 1
    except (ValueError, KeyError, TypeError):
        print ("JSON format error")
    for i in range(len(l_monitor_devices)):
        l_monitor_devices[i].func_show_vars()

########################################################################################################################
def func_close_saft_tools():
    # Make sure saft-io-ctl is closed on every device
    for i in range(len(l_monitor_devices)):
        cmd = "ssh %s@%s%s killall saft-io-ctl" % (l_monitor_devices[i].v_login, l_monitor_devices[i].v_name, l_monitor_devices[i].v_extension)
        subprocess.call(cmd.split())
    time.sleep(1)

########################################################################################################################
def func_start_logging():
    # Vars
    global v_collected_sampled_edges
    trash_cnt = []
    procs = []
    dev_names = []

    # Apply connection to host
    func_close_saft_tools()
    for i in range(len(l_monitor_devices)):
        cmd = "ssh %s@%s%s saft-io-ctl %s -s" % (l_monitor_devices[i].v_login, l_monitor_devices[i].v_name, l_monitor_devices[i].v_extension, l_monitor_devices[i].v_dev_name)
        procs.append(subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True))
        dev_names.append(l_monitor_devices[i].v_dev_name)
        trash_cnt.append(0)

    # Get edges
    for i in range(len(trash_cnt)):
        trash_cnt[i] = 0
    while True:
        func_plot_data()
        for i in range(len(procs)):
            edge = procs[i].stdout.readline()
            if (trash_cnt[i] > 1):
                if (v_finish_test == 0):
                    edge_split = edge.split()
                    ident = "%s_%s" % (dev_names[i], edge_split[0])
                    time = int(edge_split[5],16)
                    edge = edge_split[1]
                    if edge == "Rising":
                        edge = 1
                    else:
                        edge = 0
                    edge_collected = ([ident, edge, time])
                    v_collected_sampled_edges.append(edge_collected)
            else:
                trash_cnt[i] += 1

        # Logging done?
        if (v_finish_test == 1):
            func_close_saft_tools()
            break

########################################################################################################################
def func_get_io_name_number(name):
    # Vars
    global l_io_mapping_table
    get_number = 0

    # Iterate list
    for i in range(len(l_io_mapping_table)):
        if l_io_mapping_table[i] == name:
            return i

########################################################################################################################
def func_plot_data():
    # Vars
    global v_collected_sampled_edges
    global v_collected_positve_sampled_edges
    global l_io_mapping_table
    global l_sorted_edges
    global l_sorted_positive_edges

    # Create a mapping table <DEV_IO_NAME> <<>> <NUMBER>
    for i in range(len(v_collected_sampled_edges)):
        get_io_name = v_collected_sampled_edges[i]
        get_io_name = get_io_name[0]
        if any(get_io_name in s for s in l_io_mapping_table):
            pass
        else:
            l_io_mapping_table.append(get_io_name)

    # Sort IOs and their edges
    x = [[] for i in range(len(l_io_mapping_table))]
    y = [[] for i in range(len(l_io_mapping_table))]
    ref = 0
    for i in range(len(v_collected_sampled_edges)):
        get_content = v_collected_sampled_edges[i]
        get_io_name = get_content[0]
        get_edge = get_content[1]
        get_ts = get_content[2]
        list_position = func_get_io_name_number(get_io_name)
        x[list_position].append([get_edge,get_ts])
        if get_edge == 1:
            y[list_position].append(get_ts)
    l_sorted_edges = x
    l_sorted_positive_edges = y

########################################################################################################################
def func_debug():
    # Vars
    global v_collected_sampled_edges
    global l_io_mapping_table
    global l_sorted_edges
    global l_sorted_positive_edges

    # Debug print
    for i in range(len(v_collected_sampled_edges)):
        print v_collected_sampled_edges[i]
    print "========================================================================================"
    for i in range(len(l_io_mapping_table)):
        print "Item %s at position %s -> %s" % (l_io_mapping_table[i], i, func_get_io_name_number(l_io_mapping_table[i]))
    print "========================================================================================"
    for i in range(len(l_sorted_edges)):
        print l_io_mapping_table[i]
        print l_sorted_edges[i]
    print "========================================================================================"
    for i in range(len(l_sorted_edges)):
        print l_io_mapping_table[i]
        print l_sorted_edges[i]
    print "========================================================================================"
    for i in range(len(l_sorted_positive_edges)):
        print l_io_mapping_table[i]
        print l_sorted_positive_edges[i]

########################################################################################################################
def spawn_gui():
    # Show GUI
    app = QtGui.QApplication(sys.argv)
    w = PrettyWidget()
    app.exec_()

########################################################################################################################
def main():
    # Place signal handler
    signal.signal(signal.SIGINT, signal_handler)

    # Start GUI tread
    t_gui_thread = threading.Thread(target=spawn_gui)
    t_gui_thread.start()

    # Start logging
    func_discover_monitors()
    func_start_logging()

    # Done
    t_gui_thread.join()
    exit(0)

# Main
if __name__ == "__main__":
    main()
