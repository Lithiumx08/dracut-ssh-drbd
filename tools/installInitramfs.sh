#!/bin/bash


#
# Creation de l'initramfs
#
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
            installDirectory
            echo "Generation du nouveau initramfs"
            dracut -f
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
    echo "N'oubliez pas de vérifier si les fichiers suivants sont correctement configurés avant génération :"
    echo "- /etc/hosts"
    echo "- /usr/local/drbd/etc/drbd.conf"
    echo "- /etc/init.d/drbd"
    echo "Eventuellement la clé ssh dans /root/.ssh/authorized_keys"
    echo "Generer initramfs pour l'install de drbd (yes/no) ?"
    read -n5 -e user
    if [[ ${user} == "yes" ]] ; then
        installDirectory
        cp tools/shrink.sh ${DRACUT_MODULE_DIR}/90drbd/
        echo 'inst "$moddir/shrink.sh" /sbin/shrink.sh' >> ${DRACUT_MODULE_DIR}/90drbd/install
        sed -i /'drbdadm primary ${RESOURCE} --force'/d ${DRACUT_MODULE_DIR}/90drbd/shrink.sh
        dracut --install "${commandsInstall}" -f /boot/initramfs-`uname -r`.img.install `uname -r`
        echo "Ajoutez '.install' au fichier initramfs (.img) dans grub pour obtenir les commandes necessaires dans l'initram"
    fi
    unset user
}

