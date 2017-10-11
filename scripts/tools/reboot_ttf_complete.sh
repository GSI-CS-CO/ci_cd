#!/bin/bash

# Topology -> Top Down
ssh root@192.168.20.50 '/sbin/reboot' # nwt0037m66 - Betriebsgebaeude - TTF Clock Master
ssh root@192.168.20.55 '/sbin/reboot' # nwt0042m66 - Betriebsgebaeude - TTF Data Master and Management
ssh root@192.168.20.21 '/sbin/reboot' # nwt0009m66 - Vorortlabor - TTF Switch #1
ssh root@192.168.20.22 '/sbin/reboot' # nwt0010m66 - Vorortlabor - TTF Switch #2
ssh root@192.168.20.28 '/sbin/reboot' # nwt0016m66 - Vorortlabor - TTF Switch #3
ssh root@192.168.20.30 '/sbin/reboot' # nwt0018m66 - Vorortlabor - TTF Switch #4
ssh root@192.168.20.13 '/sbin/reboot' # nwt0011m66 - Vorortlabor - TTF Switch #5
