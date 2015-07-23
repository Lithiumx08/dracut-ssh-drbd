#!/bin/bash
# Fichier de configuration
. config

#. tools/installInitramfs.sh

#. tools/installModulesDir.sh

#. tools/postInstall.sh

. tools/installTools.sh

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
InstallDirectory

#InstallInitramfs
InitramfsNormal

#InstallInitramfs
InitramfsInstall

#postInstall
# Attention si l'IP virtuelle est configurée dans le systeme il faut supprimer cette partie
if [ ! -z ${ipVirtual} ] ; then
    InstallIpVirtual
fi

# Verification de la configuration du serveur
# et modification automatisée des erreurs connues
CheckConfig

exit 0

