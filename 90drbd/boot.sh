#!/bin/bash
#
#   Script de demarrage de drbd
#
#
. /etc/dracut-celeo/config


if [[ $1 == "--help" ]] ; then
    echo "Script de demarrage"
    echo "Les options existantes sont :"
    echo ""
    echo "--help            Affiche ce message"
    echo "--no-boot         Ne sort pas des breakpoints"
    echo "--force-primary   Forcer le passage des partitions en primaire"
    echo "--ignore-answer   Ignorer la vérification UP du 2eme serveur"
    echo ""
    exit 0
fi


######################################################
######################################################
###                    TOOLS                       ###
######################################################
######################################################

# Si la valeur retournée est différente de 0, toutes les partitions DRBD de ce serveur ne sont pas en primaire
# Le nombre retourné étant equivalent aux nombre de partitions n'étant pas en primaire
function IsPrimary {

    local error=0
    local role=`/sbin/drbdadm role ${RESOURCE} | /bin/cut -d "/" -f1 | /bin/awk '{print tolower($1)}'`
    for i in ${role} ; do
        if [[ ! $i == "primary" ]] ; then
            error=$((error+1))
        fi
    done

    return ${error}
}

# Si la valeur retournée est différente de 0, toutes les partitions DRBD du 2eme serveur ne sont pas en primaire
# Le nombre retourné étant equivalent aux nombre de partitions n'étant pas en primaire
function IsOtherPrimary {

    local error=0
    local role=`/sbin/drbdadm role ${RESOURCE} | /bin/cut -d "/" -f2 | /bin/awk '{print tolower($1)}'`
    local nbLines=`/sbin/drbdadm role ${RESOURCE} | /bin/cut -d "/" -f2 | /bin/awk '{print tolower($1)}' | wc -l`
    for i in ${role} ; do
        if [[ ! $i == "primary" ]] ; then
            error=$((error+1))
        fi
    done

    if [[ ${error} != 0 ]] && [[ ${error} != ${nbLines} ]] ; then
        echo "Problème avec le MASTER ?"
        echo "Les 2 partitions n'ont pas le meme role (master/slave)"
        echo "Fonction => IsOtherPrimary"
    fi

    return ${error}
}

# Si la valeur retournée est 0, l'autre serveur répond aux yeux de DRBD
# Toute autre valeur correpond a une non reponse de l'autre serveur
function IsOtherAnswering {

    local error=0
    local conn=`/sbin/drbdadm cstate ${RESOURCE} | /bin/cut -d "/" -f1 | /bin/awk '{print tolower($1)}'`
    for i in ${conn} ; do
        if [[ $i == "wfconnection" ]] ; then
            error=$((error+1))
        fi
    done

    return ${error}
}


######################################################
######################################################
#######             Vérifications             ########
######################################################
######################################################

# On verifie que le 2eme serveur n'est pas en primaire
IsOtherPrimary

if [ $? -eq 0 ] ; then
    echo "L'autre serveur est deja en primaire"
    exit 1
fi

# On verifie si le 2eme serveur est connecté a DRBD
echo "${@}" | grep "\--ignore-answer" 2>&1 > /dev/null
if [ $? -eq 0 ] ; then
    echo "!!! Answer check desactivé !!!"
else
    IsOtherAnswering
    if [[ $? == 0 ]] ; then
        echo "L'autre serveur repond"
        exit 1
    else
        echo "Demarrage lancé"
    fi
fi


######################################################
######################################################
###          Procédure de demarrage                ###
######################################################
######################################################

# Si le /boot est monté => crash kernel
umount `fdisk -l /dev/sda | grep "/dev" | grep "*" | awk -F' ' '{print $1}'`

# Passage de la partition en primaire
echo "${@}" | grep "\--force-primary" 2>&1 > /dev/null
if [ $? -eq 0 ] ; then
    /sbin/drbdadm primary ${RESOURCE} --force
else
    /sbin/drbdadm primary ${RESOURCE}
fi

# Verifications apres passage en primaire
sleep 3

IsPrimary

if [ $? -eq 0 ] ; then
    echo "Passage de la racine en primaire reussi"
else
    echo "Probleme lors du passage en primaire"
    exit 1
fi


# Montage de la partition
mount -t ext4 ${DRBD_ROOT} /sysroot
returnCode=$?
sleep 2

if [[ ${returnCode} == 0 ]] ; then
    echo "Partition montee en /sysroot"
elif [[ ${returnCode} == 32 ]] ; then
    echo "Partition deja montee en /sysroot"
else
    echo "Erreur lors du montage de la partition"
    echo "Procédure de boot annulée"
    exit 1
fi

# Modification du HOSTNAME au demarrage
sed -i /"HOSTNAME="/d /sysroot/etc/sysconfig/network
echo "HOSTNAME=${hostname}" >> /sysroot/etc/sysconfig/network

# Suppression des rules qui font chier
rm -f /sysroot/etc/udev/rules.d/70-persistent-net.rules


#
#
#
#   NETWORK
#
#
#

# Modification du fichier racine dans le system
/bin/rm -f /dev/root
/bin/ln -s ${DRBD_ROOT} /dev/root


# Sortie du breakpoint
echo "${@}" | grep "\--no-boot" 2>&1 > /dev/null
if [ $? -eq 0 ] ; then
    echo "stay on breakpoint"
else
    echo "Boot du serveur"
    /sbin/exitBreakpoint.sh
fi

