## Script to flash timing receivers

1) **flash.sh**: This script is used to flash the devices in the facility mentioned as an argument. Following arguments can be passed to the script.

a) `-h or --help`: Provides information about the script and its options.

b) `-l or --local <$directory name>`: Checks if `<$directory name>` exists and copies the device-list text file to this directory. This options assumes that the files required to flash the devices are available in the directory. Hence does not copy any file from the web server.

c) `-w or --web <$directory name>`: This option is not mandatory. But if specified, then it checks if `<$directory name>` exists and copies all the .rpd files and device list from the web server to this directory.

d) `-f or --facility <$deployment_target>`: When this option is specified, the device list of the particular target is copied to the working directory. Keywords that can be used for  `<$deployment_target>` are `testing` or `production` or `cicd`

e) `-r or --release <$release_name>`: When this option is specified, the bit streams of the release mentioned  will be copied from the web server. Keywords than can be used for `<$release_name>` are `balloon` or `golden_image` or `nightly`.

f) `-d or --device <$device_name>`: When this option is used, the user can pass the keyword of the device to be flashed as an argument. When this option is used, user will not be prompted to type the keyword of the device to be flashed. Accepted arguments are `exp/pex/vet/scu2/scu3/dm/all`

All the .rpd files from the web server will be copied on to the `<$directory name>` directory and devices in the testing facility will be flashed with latest gateware

The script informs the user to provide a keyword of the device that should be flashed. The keywords include `exp` for Exploder, `pex` for Pexarria, `vet` for VME, `scu3` for SCU3, `scu2` for SCU2, `dm` for Datamaster and `all` to flash all the devices available in the device_list.txt file.

The script searches for the keyword of every device and flashes that particular device using the IP address. The directory `<$directory name>` is deleted after the devices are flashed.

**Note**: If no arguments are passed to this script then the default settings are applied. Default settings include

1) Creating a directory called `nightly_files` in the current directory.

2) Default `<$deployment_target>` used is `testing`

3) Default `<$release_name>` used is `nightly`
