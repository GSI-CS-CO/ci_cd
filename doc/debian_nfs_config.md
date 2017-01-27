# Installation and Set-up of DHCP

1) `sudo apt-get install dnsmasq`

2) Edit `/etc/dnsmasq.conf` to work as DHCP server (ref configuration:tsl002)

3) Add the required config files (host config file with IP address for devices that will be connected, dhcp leases file, domain name and range file) in `/etc/dnsmasq.d/` folder

4) Start the service `/etc/init.d/dnsmasq start`

5) Create a local network to check if DHCP server is assigning the IP address to clients connected to this server.

# Possible errors
1) Assigned IP address and configured range mismatch.

# Installation and Set-up of TFTP and NFS

1) `sudo apt-get install nfs-kernel-server`

2) Configure dnsmasq to serve as TFTP. In `/etc/dnsmasq.d/` folder create tftp.conf file with the following information

`enable-tftp`
`tftp-root=/common/usr/tftp`

3) Create the nfs root filesystem in `/common/usr/nfs/` folder using debootstrap

`debootstrap --include linux-image-amd64,vim,openssh-server --arch amd64 stable (or required version. ex: wheezy) /common/usr/nfs/directory_name http://ftp.us.debian.org/debian`

4) Change root to the new filesystem `chroot /common/usr/nfs/directory_name`
`apt-get update`
`update-initramfs -u`

5) Edit `/etc/exports` file to provide access to the new filesystem for NFS clients

6) `exportfs -r` to update the export file

7) Copy the required kernel and initramdisk image from the new root filesystem into `/common/usr/tftp/` folder

8) Edit the `/common/usr/tftp/pxelinux.cfg/default` file to use the appropriate kernel and initramdisk image for NFS boot (ref pc: tsl002)

9) `/etc/init.d/nfs-kernel-server` start 

10) Boot the device which is assigned with IP address from DHCP and check if the device boots with the new root filesystem

Some notes

* Device used is Asrock H81M-ITX for NFS

* Qualcomm Atheros ethernet control driver is supported with the stable root filesystem for the device

# Possible errors
1) Configuration in `/etc/exports` file.

# Possible solutions in `/etc/exports` file
1) Check the options being used for /etc/exports file

ex: `/srv/tftp hostname(rw,root_squash,sync,no_subtree_check)`
    `/srv/tftp hostname(rw,root_squash,sync,no_subtree_check)`

2) nfs server can be configured to run as version 2,3 or 4.

3) Configuration options for version 2 and 3 differ from version 4. Refer `man exports` or refer 
[nfs version configuration page](http://chschneider.eu/linux/server/nfs.shtml) for more details about setting nfs version.


