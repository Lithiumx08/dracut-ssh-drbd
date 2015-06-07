#!/bin/bash


#
# Creation de l'initramfs
#

cat /etc/hosts | grep ${ip_master} > /dev/null
if [ $? = 1 ] ; then
    echo "${ip_master}  ${hostname_master}" >> /etc/hosts
fi

cat /etc/hosts | grep ${ip_slave} > /dev/null
if [ $? = 1 ] ; then
    echo "${ip_slave}  ${hostname_slave}" >> /etc/hosts
fi


echo "N'oubliez pas de vérifier si les fichiers suivants sont correctement configurés avant génération :"
echo "- /usr/local/drbd/etc/drbd.conf"
echo "- /etc/init.d/drbd"
echo "Eventuellement la clé ssh dans /root/.ssh/authorized_keys"

function initramfsNormal {

    if [ -e /boot/initramfs-`uname -r`.img.bak ] ; then
        backupExist=true
    else
        backupExist=false
    fi

    if ! ${backupExist} ; then
        echo "Aucune sauvegarde de l'initramfs ne semble presente"
    else
        echo "Une sauvegarde de l'Initramfs est presente"
    fi
    unset backupExist

    echo "Generer le nouveau Initramfs (yes/no) ?"
    read -n5 -e user
    if [[ ${user} == "yes" ]] ; then
        if ${createNewInitramfs} ; then
            echo "Generation du nouveau initramfs"
            ${DRACUT_PREFIX}dracut -f

            sed -i s/'role=master'/'role=slave'/ ./config
            installDirectory
            ${DRACUT_PREFIX}dracut -f /boot/initramfs-`uname -r`.img.slave `uname -r`

            sed -i s/'role=slave'/'role=master'/ ./config
            installDirectory


        fi
    else
        echo "Initramfs non generé ! Tapez  > dracut -f < pour le generer le moment voulu"
    fi
    unset user
}

#
# Initramfs pour l'installation de drbd
#
function initramfsInstall {
    echo "Generer initramfs pour l'install de drbd (yes/no) ?"
    read -n5 -e user
    if [[ ${user} == "yes" ]] ; then
        cp tools/shrink.sh ${DRACUT_MODULE_DIR}/90drbd/
        echo 'inst "$moddir/shrink.sh" /sbin/shrink.sh' >> ${DRACUT_MODULE_DIR}/90drbd/install
        sed -i /'\/etc\/init.d\/drbd start'/d ${DRACUT_MODULE_DIR}/90drbd/install
        ${DRACUT_PREFIX}dracut --install "${commandsInstall}" -f /boot/initramfs-`uname -r`.img.install `uname -r`
        echo "Ajoutez '.install' au fichier initramfs (.img) dans grub pour obtenir les commandes necessaires dans l'initram"
    fi
    unset user
}

