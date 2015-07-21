#!/bin/bash

#
# Creation de l'initramfs
#

# On ajoute les informations requises au bon fonctionnement de DRBD dans le fichier hosts
# Si cette partie est supprimée, il faut penser a le faire avant installation sinon ce ne fonctionnera pas
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

# Installation de l'initramfs de tous les jours
function initramfsNormal {

    # On vérifie si une sauvegarde de l'initramfs est présente avant toute chose, et on previent l'utilisateur
    # Libre a lui de stopper l'execution et d'en générer une s'il le souhaite
    if [ -e /boot/initramfs-`uname -r`.img.bak ] ; then
        local backupExist=true
    else
        local backupExist=false
    fi

    if ! ${backupExist} ; then
        echo "Aucune sauvegarde de l'initramfs ne semble presente"
    else
        echo "Une sauvegarde de l'Initramfs est presente"
    fi
    unset backupExist

    echo "Generer le nouveau Initramfs (yes/no) ?"
    answer
    if [ $? -eq 0 ] ; then
        if ${createNewInitramfs} ; then
            echo "Generation du nouveau initramfs"
            ${DRACUT_PREFIX}dracut -f

            # Si le script est executé sur le MASTER, on prepare automatiquement pour le SLAVE
            grep "role=master" config 2>&1 > /dev/null
            if [ $? -eq 0 ] ; then
                sed -i s/'role=master'/'role=slave'/ ./config
                installDirectory
                ${DRACUT_PREFIX}dracut -f /boot/initramfs-`uname -r`.img.slave `uname -r`

                sed -i s/'role=slave'/'role=master'/ ./config
                installDirectory
            fi

        fi
    else
        echo "Initramfs non generé ! Tapez  > dracut -f < pour le generer le moment voulu"
    fi
}

#
# Initramfs pour l'installation de drbd
#
# Cet initramfs n'est normalement utile que pour le master
# Au besoin il suffit de copier les lignes 'echo inst ...' 'sed -i ...' et remplacer la ligne 'dracut --install "${commandInstall}"'
# au dessus pour obtenir le necessaire dans l'initramfs normal
function initramfsInstall {
    echo "Generer initramfs pour l'install de drbd (yes/no) ?"
    answer
    if [ $? -eq 0 ] ; then
        cp tools/shrink.sh ${DRACUT_MODULE_DIR}/90drbd/
        echo 'inst "$moddir/shrink.sh" /sbin/shrink.sh' >> ${DRACUT_MODULE_DIR}/90drbd/install
        sed -i /'\/etc\/init.d\/drbd start'/d ${DRACUT_MODULE_DIR}/90drbd/install
        ${DRACUT_PREFIX}dracut --install "${commandsInstall}" -f /boot/initramfs-`uname -r`.img.install `uname -r`
        echo "Ajoutez '.install' au fichier initramfs (.img) dans grub pour obtenir les commandes necessaires dans l'initram"
    fi
}

