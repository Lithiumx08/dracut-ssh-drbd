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
if [ ! -z ${ipVirtual} ] ; then
    InstallIpVirtual
fi
CheckConfig
exit 0

