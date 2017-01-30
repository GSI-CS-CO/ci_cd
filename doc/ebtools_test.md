##Documentation for ebtools test in the CI system

The ebtools that are checked with this script are eb-read, eb-write, eb-get and eb-put. The test is carried out on the LM32-RAM-User crossbar.

Arguments that can be passed to this script are as follows

a) `-h or --help`: Provides information about the script and its options.

b) `-c or --connection <$communication_mode>`: Mode of communication for the timing receivers. Options available are (nw for network(default), usb for USB connected to timing receiver, pcie for PCI express connected to timing receiver)

c) `-f or --facility <$deployment_target>`: Target where the ebtools test should be performed. Keywords that can be used for  `<$deployment_target>` are `testing(default)` or `production` or `cicd`

d) `-u or --user <$username>`: When connection type is usb or pcie, this option is used to connect to the IPC user that is performing the test

e) `-p or --pcname <$pcname>`: When connection type is usb or pcie, this option is used to connect to the IPC with the user mentioned in the -u argument to perform the test

f) `-t or --ttynumber <$ttyUSB_number>`: When connection type is usb, giving a number as argument will communicate to the device connected via USB. Example: when argument passed is 0, then device connected is dev/ttyUSB0

g) `-w or --wbmnumber <$wbm_number>`: When connection type is pcie, giving a number as argument will communicate to the device connected via PCIe. Example: when argument passed is 0, then device connected is dev/wbm0

h) `-d or --device <$device_name>`: Device on which the ebtools functionality should be performed. Possible arguments are exp/pex/vet/scu/dm/all

eb-write writes some random data on the LM32-RAM-User crossbar using the function $RANDOM (which provides a random positive integer value every time the function is called). eb-read is used to read the value currently available in the LM32-RAM-User crossbar.

Create a file with random data on it using the dd command (dd if=/dev/urandom of=$putfile bs=4432 count=1) and transfer this data on to the LM32-RAM-User crossbar using eb-put. Fetch this data on another file using eb-get tool. Compare both the files to check if they are equal.
