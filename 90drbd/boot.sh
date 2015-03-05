#!/bin/bash
#
#   Script de demarrage de drbd
#
#
. /etc/config

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
/sbin/drbdadm primary r0
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
    mount -t ext4 /dev/drbd0 /sysroot
    returnCode=$?
    sleep 2
    /bin/rm -f /dev/root
    /bin/ln -s /dev/drbd0 /dev/root
    if [[ ${returnCode} == 0 ]] ; then
        echo "Partition montee en /sysroot"
    elif [[ ${returnCode} == 32 ]] ; then
        echo "Partition deja montee en /sysroot"
    else
        echo "Erreur lors du montage de la partition"
        error=$((error+1))
    fi
fi
unset role

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
