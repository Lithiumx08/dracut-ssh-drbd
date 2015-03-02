#!/bin/bash
#
#   Script de demarrage de drbd
#
#
. /etc/config

conn=`/sbin/drbdadm cstate ${ROOT_RESOURCE} | /bin/cut -d "/" -f1 | /bin/awk '{print tolower($1)}'`
if [[ ${conn} == "wfconnection" ]] ; then
    echo "status 2eme serveur : ${conn}"
    echo "Demarrage lancé"
else
    echo "Le statut du 2eme serveur ne permet pas de demarrer le serveur"
    exit 2
fi
unset conn


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

role=`/sbin/drbdadm role ${ROOT_RESOURCE} | /bin/cut -d "/" -f1 | /bin/awk '{print tolower($1)}'`
if [[ ${role} == "primary" ]] ; then
    mount -t ext4 /dev/drbd0 /sysroot
    returnCode=$?
sleep 2
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
#/bin/rm -f /dev/root
#/bin/ln -s /dev/drbd0 /dev/root
#echo "Montage en MOUNT"
#/bin/df
#/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null
#echo "Montage en SWITCH ROOT"
#/bin/df
#/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null
#echo "Demarrage du systeme"
