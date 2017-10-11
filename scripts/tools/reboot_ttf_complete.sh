#!/bin/bash

# Topology -> Top Down
ssh root@192.168.20.40 '/sbin/reboot' # Betriebsgebaeude - TTF Clock Master
ssh root@192.168.20.45 '/sbin/reboot' # Betriebsgebaeude - TTF Data Master Connection
ssh root@192.168.20.20 '/sbin/reboot' # SE Messtation - TTF Switch 1
ssh root@192.168.20.18 '/sbin/reboot' # SE Messtation - TTF Switch 2
ssh root@192.168.20.12 '/sbin/reboot' # SE Messtation - TTF Switch 3
ssh root@192.168.20.11 '/sbin/reboot' # SE Messtation - TTF Switch 4
