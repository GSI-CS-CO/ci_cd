#!/usr/bin/env python
import snmp
import logging

import binascii
import socket

# timing domain name
domain='.timing'

# default remote system name for timing receivers
def_remote_sysname='WR PTP Core'

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class Device:
    __doc__ = "Networked device"
    info = {}

    def __init__(self, hostname):
        self.hostname = hostname + domain

    def snmpConfig(self, oid, version=2, community="public", test=False):
        self.snmp = snmp.Connection(host=self.hostname, version=version, community=community)
        self.oid = oid
        if test:
            return self.snmpTest()

    def snmpTest(self, oid=".1.3.6.1.2.1.1.5.0"):
        result = self.snmp.get(oid)
        if not result:
            logger.warning("Cannot get OID %s on host %s" % oid, self.hostname)
        return result

    #
    # returns real interface name (LLDP OIDs use only numbers while the device might use letters).
    #
    def getInterfaceName(self, interface):
        snmp = self.snmp
        oid = self.oid
        # <interface names OID><interface number> is what we're looking for
        name = snmp.get(oid['if']['ifname'] + str(interface))
        if name:
            interface = name
        logger.info("Returning interface name %s", interface)
        return interface

    #
    # returns interface description
    #
    def getInterfaceDesc(self, interface):
        snmp = self.snmp
        oid = self.oid
        # <interface descriptions OID><interface number> is what we're looking for
        desc = snmp.get(oid['if']['ifdesc'] + str(interface))
        logger.info("Returning interface description %s", desc)
        return desc

    #
    # returns interface ID
    #
    # def getInterfaceByName(self, interfacename):

    #
    # given subinterface name as input, finds and returns parent interface ID.
    #
    def getParentInterface(self, interface, subname):
        parentname = subname.split('.')[0]
        logger.debug("Searching for interface name %s", parentname)

        originalinterface = interface
        while True:
            interface = int(interface) - 1
            name = self.getInterfaceName(interface)
            if name == parentname:
                logger.debug("Found name %s on interface number %s", name, interface)
                return interface
            if parentname not in name:
                logger.debug("Encountered name %s. Giving up.", name)
                # Give up
                return originalinterface

    #
    # returns interface speed
    #
    def getInterfaceSpeed(self, interface, user_format='M'):
        snmp = self.snmp
        oid = self.oid
        speed = None
        divide = {'G': 1000000000, 'M': 1000000, 'K': 1000, 'B': 1}
        if user_format.upper() not in divide:
            user_format = 'M'

        # <interface speeds OID><interface number> is what we're looking for
        speed = snmp.get(oid['if']['ifspeed'] + str(interface))
        if speed:
                speedInBits = int(speed)
        speed = speedInBits / divide[user_format.upper()]
        logger.info("Returning interface speed %s", speed)
        return speed

    #
    # Get the remote chassis ID of LLDP neighbours from SMTP information, returns dict of oid:chassis pairs.
    #
    def getRemoteChassisId(self):
        oid = self.oid
        chassis = self.snmp.walk(oid['lldp']['remotechassis'])
        if not chassis:
            return None
        return chassis

    #
    # Get the remote port description of LLDP neighbours from SMTP information, returns dict of oid:port_desc pairs.
    #
    def getRemotePortDesc(self):
        oid = self.oid
        port_desc = self.snmp.walk(oid['lldp']['remoteportdesc'])
        if not port_desc:
            return None
        return port_desc

    #
    # Collects LLDP neighbours from SMTP information, returns dict of oid:neighbour pairs.
    #
    def getNeighbours(self):
        oid = self.oid
        n_sysname = self.snmp.walk(oid['lldp']['remotesysname'])
        if not n_sysname:
            return None
        logger.debug(n_sysname)

        # Modify the remote system name if it has the default value
        chassis = self.getRemoteChassisId()
        if chassis:
            for key in n_sysname.keys():
                if def_remote_sysname in str(n_sysname[key]):
                    chass_oid = str(key.replace(oid['lldp']['remotesysname'], oid['lldp']['remotechassis']))
                    if chass_oid in chassis.keys():
                        #extended = n_sysname[key] + '\n' + binascii.b2a_hex(chassis[chass_oid])
                        extended = n_sysname[key][0:2] + ' ' + binascii.b2a_hex(chassis[chass_oid]) # slice of s from i to j, s[i:j]
                        logger.debug("name modification: %s -> %s", n_sysname[key], extended)
                        n_sysname[key] = extended
        return n_sysname

    #
    # Returns list of dicts with interface number, name, speed and neighbour.
    #
    def getNeighbourInterfaceInfo(self, neighbours=None):
        iflist = []
        if not isinstance(neighbours, dict):
            # neighbours is not a dict. Let's get us something to work with.
            neighbours = self.getNeighbours()

        if not neighbours:
            return None

        # get port description (ie., wri1) of each neighbour
        remote_port_desc = self.getRemotePortDesc()

        for n in neighbours.keys():
            # Take the OID's second to last dot separated number. That's our local interface.
            ifnumber = n.split('.')[-2]
            logger.debug("From OID %s interface is %s", n, ifnumber)
            ifname = self.getInterfaceName(ifnumber)
            if '.' in str(ifname):
                # Do we have a subinterface?
                ifnumber = self.getParentInterface(ifnumber, ifname)
            ifspeed = self.getInterfaceSpeed(ifnumber)

            port_desc_oid = str(n.replace(self.oid['lldp']['remotesysname'], self.oid['lldp']['remoteportdesc']))
            if port_desc_oid in remote_port_desc.keys():
                remote_port = remote_port_desc[port_desc_oid]
            else:
                remote_port = 'u'

            logger.info("%s interface %s has neighbour %s, speed %s", self.hostname, ifname, neighbours[n], ifspeed)
            iflist.append({'number': ifnumber, 'name': ifname, 'speed': ifspeed, 'neighbour': neighbours[n],
                           'neighbour_port': remote_port})

        return iflist

    def getDeviceInfo(self):
        snmp = self.snmp
        oid = self.oid
        # Let's start collecting info
        deviceFamily = None

        # First we poll standard OIDs
        deviceinfo = snmp.populateDict(oid['standard'])
        if 'sysdesc' in deviceinfo:
            # Split into words (space separated), take the first one and lowercase it
            deviceFamily = deviceinfo['sysdesc'].split(' ')[0].lower()
            logger.info("Found device family %s", deviceFamily)

        # If we have a device family identified, let's look for a matching set of OIDs
        if deviceFamily in oid['device']:
            familyinfo = snmp.populateDict(oid['device'][deviceFamily])
            # Add the information to the deviceinfo dict
            deviceinfo.update(familyinfo)

        self.deviceFamily = deviceFamily
        deviceinfo['if'] = self.getNeighbourInterfaceInfo()
        self.info.update(deviceinfo)
        return deviceinfo
