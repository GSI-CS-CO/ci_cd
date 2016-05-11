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
	#exit 1
fi

#for module in $MODULES; do
#	find /opt/$NAME/$ARCH/lib/modules/$KERNEL_VERSION \
#		-name $module.ko \
#		-exec cp "{}" /lib/modules/$KERNEL_VERSION/ \;
#done

#rm -f /lib/modules/$KERNEL_VERSION/modules.dep.bb 
#for module in $MODULES; do
#	log "loading module $module"
#	/sbin/modprobe $module
#	sleep 1
#done

log 'copying utilities to ramdisk'
cp -a /opt/$NAME/$ARCH/bin/* /usr/bin/
cp -a /opt/$NAME/$ARCH/lib/*.so* /usr/lib
cp -a /opt/$NAME/$ARCH/lib/modules/2.6.33.9-rt31-scu01/extra/*.ko* /lib/modules/2.6.33.9-rt31-scu01/
mkdir /lib/modules/2.6.33.9-rt31-scu01/extra/
cp -a /opt/$NAME/$ARCH/lib/modules/2.6.33.9-rt31-scu01/extra/*.ko* /lib/modules/2.6.33.9-rt31-scu01/extra/

# run ldconfig
ldconfig

# Start etherbone TCP->PCIe gateway
test -f /usr/bin/socat || cp -a /opt/$NAME/socat /usr/bin
/usr/bin/socat tcp-listen:60368,reuseaddr,fork file:/dev/wbm0 &

# vme_wb driver is loaded if vmebus is already loaded
#if [ `lsmod | grep -o ^vmebus` ]
if [ `ls /proc/vme/info | grep -o info` ]
then
	/sbin/insmod /lib/modules/$KERNEL_VERSION/vme_wb.ko slot=1 vmebase=0x0 vector=1 level=7 lun=1
fi
