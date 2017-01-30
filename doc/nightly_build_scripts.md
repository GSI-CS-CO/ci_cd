## Scripts written for the nightly build process

The following scripts are written for the nightly build process

1) **git_chkout.sh**: Checks out proposed_master branch from bel_projects. Keeps the branch up to date by using `git pull`.

Note: Any other branch should be manually added in the Jenkins project configuration page for a checkout at the end of `execute shell command` page

2) **git_init.sh**: Initializes and updates the branch

3) **filecopy_websrvr.sh**: Compiles the nightly build project for every gateware and copies the files (.jic, .rpd, .sof) to the web server. Also compiles wrpc-sw, etherbone and saftlib projects.

4) **jtag_check.sh**: After manually checking which device is connected to the JTAG, this script is used to provide information about the device connected with a particular jtag ID.

5) **nightly_build_programmer.sh**: Checks if the required device (exploder, pexarria etc) is connected by running `jtag_check.sh` script internally. The script then programs the device using JTAG and later flashes this device using eb-flash.

Note: This script checks the build status of nightly build project.  If the build is successful then it uses the latest gateware to flash the device. But if the build is a failure then it uses the golden image to flash the device.

6) **logfile.sh**: Creates a log file called nighty_build.log with information about the status of the nightly_build project (eg: if build was successful or if build failed). It also provides information about the date and time of the files that were generated.

7) **quartus16.sh**: exports quartus path and adds the `quartus/bin` folder to the environment PATH.

8) **balloon_filecopy_websrvr.sh**: Compiles bel_projects balloon branch for every gateware and copies the files (.jic, .rpd, .sof) to the web server with date of compilation. Also compiles wrpc-sw and etherbone projects. The files in the web server are stored for 7 days, after which the newest files generated will replace the oldest files.

## Some Notes

1) Use `echo -e` to interpret escape characters, which can be used to change the color of the line being printed.

eg: `echo -e "\e[31mWARNING: BUILD STATUS FAILED. USING GOLDEN IMAGE"` will print the line in red on the terminal.

Different color combinations to use with echo can be found [here](http://misc.flogisoft.com/bash/tip_colors_and_formatting)
