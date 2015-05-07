#!/bin/bash
#
#   Script de demarrage de drbd
#
#
. /etc/config
umount `fdisk -l /dev/sda | grep "/dev" | grep "*" | awk -F' ' '{print $1}'`

conn=`/sbin/drbdadm cstate ${RESOURCE} | /bin/cut -d "/" -f1 | /bin/awk '{print tolower($1)}'`

error=0
statusConn=0
for i in ${conn} ; do
    if [[ $i == "wfconnection" ]] ; then
        statusConn=$((statusConn+1))
    else
        error=$((error+1))
    fi
done

if [[ ${error} > 0 ]] ; then
    echo "L'autre serveur repond"
    exit 1
else
    echo "Demarrage lancé"
fi

unset conn
unset error

######################################################
######################################################
###          Procédure de demarrage                ###
######################################################
######################################################
error=0
if [[ $1 == "force" ]] ; then {
    /sbin/drbdadm primary ${RESOURCE} --force
}
else {
    /sbin/drbdadm primary ${RESOURCE}
}
fi
returnCode=$?
sleep 3
if [ ! ${returnCode} == 0 ] ; then
    echo "Probleme lors du passage en primary"
    error=$((error+1))
elif [ ${returnCode} == 0 ] ; then
    echo "Passage de la racine en primaire"
fi
returnCode=1

role=`/sbin/drbdadm role ${RESOURCE} | /bin/cut -d "/" -f1 | /bin/awk '{print tolower($1)}'`
statusRole=0
for i in ${role} ; do
    if [[ $i == "primary" ]] ; then
        statusrole=$((statusConn+1))
    else
        error=$((error+1))
    fi
done

if [[ ${error} > 0 ]] ; then
    echo "Tous les volumes ne sont pas primary"
    exit 1
else
    mount -t ext4 ${DRBD_ROOT} /sysroot
    returnCode=$?
    sleep 2
    sed -i /"HOSTNAME="/d /sysroot/etc/sysconfig/network
    echo "HOSTNAME=${hostname}" > /sysroot/etc/sysconfig/network
    rm -f /sysroot/etc/udev/rules.d/70-persistent-net.rules
    /bin/rm -f /dev/root
    /bin/ln -s ${DRBD_ROOT} /dev/root
    if [[ ${returnCode} == 0 ]] ; then
        echo "Partition montee en /sysroot"
    elif [[ ${returnCode} == 32 ]] ; then
        echo "Partition deja montee en /sysroot"
    else
        echo "Erreur lors du montage de la partition"
        error=$((error+1))
    fi
fi

if [[ ${error} > 0 ]] ; then
    echo "${error} erreurs au boot, procédure annulée"
    exit 666
fi

if [[ $1 == "noboot" ]] ; then
    echo "stay on breakpoint"
    exit 0
fi
/sbin/exitBreakpoint.sh
#echo "Montage en MOUNT"
#/bin/df
#/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null
#echo "Montage en SWITCH ROOT"
#/bin/df
#/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null
#echo "Demarrage du systeme"
