#!/bin/bash

. /etc/dracut-celeo/config


# Permet d'exporter les chemins dans la console physique
export PATH=$PATH:/sbin:/bin:/usr/bin:/usr/sbin

ping -c5 8.8.8.8 > /dev/null
TEST=$?

if [ ${TEST} -ne 0 ] ; then

    case ${role} in
        master)
            ip=${ip_master}
            hostname=${hostname_master}
            ;;
        slave)
            ip=${ip_slave}
            hostname=${hostname_slave}
            ;;
    esac

    # Configuration reseau du serveur
    ifconfig ${devName} down
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


# Cas du 1er boot de l'esclave (preparation des metadata)
diskState=`drbdadm dstate r0 | awk -F'/' '{print $1}' | awk -v ligne=1 'NR==ligne {print $0}'`

case ${role} in 
    slave)
        case ${diskState} in
            Diskless)
                /etc/init.d/drbd stop
                drbdadm create-md ${RESOURCE}
                /etc/init.d/drbd start
                ;;
        esac
        ;;
esac

