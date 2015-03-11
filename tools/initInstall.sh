#!/bin/bash
#
#   Author : Adrien
#
#
#

# Fonction permettant de générer un initramfs pour automatiser l'installation des metadata DRBD
needToInstall(){
    dracut --install "${commandsInstall}" -f /boot/initramfs-`uname -r`.img.install `uname -r`
    echo "Ajoutez '.install' au fichier initramfs dans grub pour obtenir les commandes mkfs dans l'initram"
}
