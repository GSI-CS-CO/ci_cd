# Automatic power on and power off switches in Energenie Programmable power strip

# LAN Control

1) Program to control power socket of the LAN controllable power strip is added as a submodule to the ci_cd project on git hub.

2) A fork from `https://github.com/unterwulf/egctl.git` to `https://github.com/GSI-CS-CO-Forks/egctl.git` is created and this forked project is used as a submodule in ci_cd project

3) After cloning the ci_cd project, perform `git submodule init` and `git submodule update` to access the submodule.

4) Submodule location: ci_cd/tools/egctl

5) Run `make` in `ci_cd/tools/egctl` to create the output file `egctl` 

6) Configure the `egtab` file with information about the switches that will be used for automatic power on and off of the devices connect to the switch.

7) Copy and paste this `egtab` file in `/etc/` directory [Reference- tsl002: /etc/egtab]

8) Run the program as the below example from `ci_cd/tools/egctl` directory

`./egctl $SW_NAME $Socket1_sts $Socket2_sts $Socket3_sts $Socket4_sts`

ex: ./egctl eg-pwr1 on on off off

9) Possible status are on, off, toggle, left (hold state)

# USB control

1) Install the required applications to implement the automatic power on and off the Power strip

`sudo apt-get install libusb-dev` (dependency)

`sudo apt-get install sispmctl`

sispmctl (Silver Shield Power Management Control) is a software application used to implement the USB controlled power outlet device for switching operations.

2) `sispmctl -s` scans for the device connected to the PC

3) `sispmctl -f $(SWITCH_NUMBER)` switches the given outlet to OFF.

4) `sispmctl -o $(SWITCH_NUMBER)` switches the given outlet to ON.
