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

log 'copying utilities to ramdisk'
cp -a /opt/$NAME/$ARCH/sbin/* /usr/sbin/
#cp -a /opt/$NAME/$ARCH/etc/* /usr/etc/
cp -a /opt/$NAME/$ARCH/etc/* /etc/
cp -a /opt/$NAME/$ARCH/bin/* /usr/bin/
cp -a /opt/$NAME/$ARCH/lib/*.so* /usr/lib
cp -a /opt/$NAME/$ARCH/lib64/*.so* /usr/lib

cp -a /opt/$NAME/$ARCH/usr/bin/* /bin
cp -a /opt/$NAME/$ARCH/usr/sbin/* /sbin
cp -a /opt/$NAME/$ARCH/usr/share/* /share
cp -a /opt/$NAME/$ARCH/usr/include/* /include
cp -a /opt/$NAME/$ARCH/usr/lib/* /lib
cp -a /opt/$NAME/$ARCH/usr/lib64/* /lib

log 'copying saftlib to ramdisk'
cd /
#tar xJf /opt/$NAME/saftlib-$ARCH.tar.xz --strip-components=1

# run ldconfig
ldconfig

log 'setting up dbus acounts'
echo 'dbus:*:100:100:DBus:/:' >> /etc/passwd
echo 'dbus:*:100:' >> /etc/group
mkdir /var/run/dbus
#cp ./usr/etc/system.d/saftlib.conf ./etc/dbus-1/system.d/ # TBD: fix this

log 'starting services'
dbus-daemon --system
saftd baseboard:dev/wbm0 >/tmp/saftd.log 2>&1 &
dbus-uuidgen > /etc/machine-id
