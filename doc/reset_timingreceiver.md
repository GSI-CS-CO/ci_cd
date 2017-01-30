## Script to reset timing receivers using LAN controlled power socket

The script `reset.sh` is located in the `ci_cd/scripts/nightly` directory in the `ci_cd git project`. The following operations are internally performed when `./reset.sh` script is executed.

1) The script uses a submodule named egctl, available in the `ci_cd/tools/egctl` directory. This submodule contains a C program to power on and off the LAN controlled power socket.

2) `egctl-power-socket-list-testing.txt` is a text file in the web server that contains information about the devices connected to each socket. The link to the file can be found [here](http://tsl002.acc.gsi.de/config_files/egctl-power-socket-list-testing.txt).

3) An option in the script is provided to select the target to be reset. Default is the testing facility. Available options are testing, prod (production facility) and cicd (continuous integration facility). Run the script as below to reset the devices in the facility provided by the user. eg: `./reset.sh -f cicd` to reset the devices in the continuous integration facility.

4) During execution of the script, the user must provide an input stating the device that should be reset. Accepted keywords are `exp, pex, vet, scu, sw, all`.

5) Based on the keyword provided by the user, the script will reset the device accordingly.

Some Notes:

1) SCU reset is performed by running a script fpga_reset.sh internally in the reset.sh script. The fpga_reset.sh script will write DEADBEEF to the `FPGA Reset` crossbar of individual device using eb-write tool. After this operation is complete, the reset.sh script will continue its execution.

2) Pexarria is connected to an industrial PC, therefore, the PC will be put to halt before a reset request is sent to the power socket. After a delay of 30 seconds, the reset request is sent to the power socket.

3) When keyword used is `all`, the reset script will execute fpga_reset script first, followed by IPC going to halt state and then the power cycle for all the devices will take place.

4) Step 2 of PC halt is followed even when exploder is powered through pcie cables connected to a PC.

**fpga_reset.sh**: This script uses `eb-find` tool to obtain the address of the _FPGA Reset_ crossbar and then uses `eb-write` to write `DEADBEEF` on this address. The script performs reset operation for the devices mentioned as keyword during execution of the flash script.

This script is included as a sub-script in `reset.sh` as a part of SCU flashing.

There are 3 cases in this script:

1) 2 argument passed: If the scu_name scu_IP is passed as an argument, then the individual SCU will be written with DEADBEEF in the Reset crossbar. eg: `./scu_reset scuxl0001t 192.168.135.1`

2) No arguments passed: If no arguments are passed to the script, then the script will get the device list from web server and reset all the SCUs available in the list.

3) Any other arguments passed: If arguments other than 2 or 0 are passed, then the script will give an error information and exit.
