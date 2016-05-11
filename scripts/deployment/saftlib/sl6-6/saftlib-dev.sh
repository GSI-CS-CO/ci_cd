#!/bin/sh
. /etc/functions

log 'initializing'
log $NAME

ARCH=$(/bin/uname -m)
HOSTNAME=$(/bin/hostname -s)

if [ -f /opt/$NAME/local/$HOSTNAME/conf/sysconfig ]; then
	. /opt/$NAME/local/$HOSTNAME/conf/sysconfig
	log 'Got sysconfig'
fi

#log 'erasing competing obsolete etherbone library'
#rm -f /usr/lib/libetherbone*
#for i in discover find get ls put read snoop tunnel write; do
#  rm -f /usr/bin/eb-$i
#done

log 'copying utilities to ramdisk'
cp -a /opt/$NAME/$ARCH/sbin/* /usr/sbin/
cp -a /opt/$NAME/$ARCH/etc/* /usr/etc/
cp -a /opt/$NAME/$ARCH/bin/* /usr/bin/
cp -a /opt/$NAME/$ARCH/lib/*.so* /usr/lib

#log 'unloading obsolete kernel driver'
rmmod pcie_wb
rmmod vme_wb
rmmod wishbone

log 'copying utilities to ramdisk'
cd /
tar xJf /opt/$NAME/saftlib-$ARCH.tar.xz

# run ldconfig
ldconfig

#log 'loading new kernel drivers'
insmod /lib/modules/*/extra/wishbone.ko
insmod /lib/modules/*/extra/pcie_wb.ko
insmod /lib/modules/*/extra/vme_wb.ko

log 'setting up dbus acounts'
echo 'dbus:*:100:100:DBus:/:' >> /etc/passwd
echo 'dbus:*:100:' >> /etc/group
cp ./usr/etc/system.d/saftlib.conf ./etc/dbus-1/system.d/ # TBD: fix this

log 'starting services'
/bin/dbus-daemon --system
/usr/sbin/saftd baseboard:dev/wbm0 >/tmp/saftd.log 2>&1 &
