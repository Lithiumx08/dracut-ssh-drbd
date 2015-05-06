#!/bin/bash
# Fichier de configuration
. config

# Creation des images initramfs
. tools/installInitramfs.sh

. tools/installModulesDir.sh

. tools/postInstall.sh

##  ##############  ##############  ##              ##############  ##############
##  ##############  ##############  ##              ##############  ##############
##  ###`            ##              ##              ##              ##          ##
##  ###`            ##              ##              ##              ##          ##
##  ###`            ##############  ##              ##############  ##          ##
##  ###`            ##############  ##              ##############  ##          ##
##  ###`            ##              ##              ##              ##          ##
##  ###`            ##              ##              ##              ##          ##
##  ##############  ##############  ##############  ##############  ##############
##  ##############  ##############  ##############  ##############  ##############

#InstallModulesDir
installDirectory

#InstallInitramfs
initramfsNormal

#InstallInitramfs
initramfsInstall

#postInstall
InstallIpVirtual
exit 0

