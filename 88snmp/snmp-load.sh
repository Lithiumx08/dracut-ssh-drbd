#!/bin/bash

. /etc/config

ping -c5 8.8.8.8 > /dev/null
TEST=$?

if [ $TEST -ne 0 ] ; then
    # Configuration reseau du serveur
    ifconfig down ${devName}
    ifconfig ${devName} up
    ifconfig ${devName} ${ip} netmask ${netmask}
    hostname ${hostname}
    ip route add default via ${gw}
fi

/etc/init.d/snmpd start
