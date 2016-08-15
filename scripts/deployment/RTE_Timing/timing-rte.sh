#!/bin/sh
. /etc/functions

log 'initializing'

KERNELVER=$(/bin/uname -r)
ARCH=$(/bin/uname -m)
HOSTNAME=$(/bin/hostname -s)

# TODO put a list of kernel modules here
MODULES="wishbone pcie_wb vmebus vme_wb"

if [ -f /opt/$NAME/local/$HOSTNAME/conf/sysconfig ]; then
	. /opt/$NAME/local/$HOSTNAME/conf/sysconfig
fi

[ ! -d /lib/modules/$KERNEL_VERSION ] && mkdir -p /lib/modules/$KERNEL_VERSION


if [ ! -d /opt/$NAME/$ARCH/lib/modules/$KERNEL_VERSION ]; then
	log_error "kernel modules for $KERNELVER not available"
fi


log 'copying utilities to ramdisk'
cp -a /opt/$NAME/$ARCH/bin/* /usr/bin/
cp -a /opt/$NAME/$ARCH/sbin/* /usr/sbin/
cp -a /opt/$NAME/$ARCH/usr/bin/* /usr/bin/
cp -a /opt/$NAME/$ARCH/usr/sbin/* /sbin
cp -a /opt/$NAME/$ARCH/usr/share/* /share
cp -a /opt/$NAME/$ARCH/usr/include/* /include
cp -a /opt/$NAME/$ARCH/usr/lib/* /lib
cp -a /opt/$NAME/$ARCH/usr/lib64/* /lib
cp -a /opt/$NAME/$ARCH/lib/*.so* /usr/lib
cp -a /opt/$NAME/$ARCH/lib64/*.so* /usr/lib
mkdir /lib/modules/3.10.101-rt111-scu01/extra/
cp -a /opt/$NAME/$ARCH/lib/modules/3.10.101-rt111-scu01/extra/*.ko* /lib/modules/3.10.101-rt111-scu01/extra/
cp -a /opt/$NAME/$ARCH/lib/modules/3.10.101-rt111-scu01/legacy-vme64x-core/drv/driver/*.ko* /lib/modules/3.10.101-rt111-scu01/extra/
cp -a /opt/$NAME/$ARCH/etc/* /etc/

# run ldconfig
ldconfig

#load drivers
insmod /lib/modules/$KERNEL_VERSION/extra/wishbone.ko
insmod /lib/modules/$KERNEL_VERSION/extra/pcie_wb.ko
insmod /lib/modules/$KERNEL_VERSION/extra/vmebus.ko

# Start etherbone TCP->PCIe gateway
test -f /usr/bin/socat || cp -a /opt/$NAME/socat /usr/bin
/usr/bin/socat tcp-listen:60368,reuseaddr,fork file:/dev/wbm0 &

# vme_wb driver is loaded if vmebus is already loaded
if [ `ls /proc/vme/info | grep -o info` ]
then	
	/sbin/rmmod pcie_wb
	/sbin/insmod /lib/modules/$KERNEL_VERSION/extra/vme_wb.ko slot=2 vmebase=0x0 vector=1 level=7 lun=1
fi

log 'setting up dbus acounts'
echo 'dbus:*:100:100:DBus:/:' >> /etc/passwd
echo 'dbus:*:100:' >> /etc/group
mkdir /var/run/dbus

log 'starting services'
dbus-daemon --system
saftd baseboard:dev/wbm0 >/tmp/saftd.log 2>&1 &
dbus-uuidgen > /etc/machine-id
