#!/bin/bash

. /etc/config


# Permet d'exporter les chemins dans la console physique
export PATH=$PATH:/sbin:/usr/sbin

ping -c5 8.8.8.8 > /dev/null
TEST=$?

if [ $TEST -ne 0 ] ; then

    case ${role} in
        master)
            ip=${ip_master}
            ;;
        slave)
            ip=${ip_slave}
            ;;
    esac
    
    case ${role} in
        master)
            hostname=${hostname_master}
            ;;
        slave)
            hostname=${hostname_slave}
            ;;
    esac

    # Configuration reseau du serveur
    ifconfig down ${devName}
    ifconfig ${devName} up
    ifconfig ${devName} ${ip} netmask ${netmask}
    hostname ${hostname}
    ip route add default via ${gw}
fi
unset TEST

# On active les volumes LVM pour les metadata ou les partitions
vgchange -a y

# On demarre DRBD
/etc/init.d/drbd start
