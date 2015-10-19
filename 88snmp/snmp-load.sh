#!/bin/bash

. /etc/dracut-celeo/config


# Permet d'exporter les chemins dans la console physique
export PATH=$PATH:/sbin:/bin:/usr/bin:/usr/sbin

ping -c5 8.8.8.8 > /dev/null
TEST=$?

if [ $TEST -ne 0 ] ; then

    # Configuration reseau du serveur
    ifconfig ${devName} down
    ifconfig ${devName} up
    ifconfig ${devName} ${ip} netmask ${netmask}
    hostname ${hostname}
    ip route add default via ${gw}
fi
unset TEST

/etc/init.d/snmpd start
