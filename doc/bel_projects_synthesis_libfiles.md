#The following files must be installed in order to synthesize bel_projects

sudo apt-get install gcc-multilib g++-multilib

sudo apt-get install lib32z1 lib32ncurses5

sudo apt-get install libtool automake docbook-utils

sudo apt-get install linux-headers-$(uname -r)

sudo apt-get install libxml2-dev libxml2-doc libxml2 (While compiling data master on host, these files were missing)
