#!/bin/bash
# Fichier de configuration
. config

# Contient toutes les fonctions utiles à l'installation
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
# On crée cet initram a la fin car des ajouts spécifiques sont effectués pour ce dernier
InitramfsInstall

#postInstall
if [ ! -z ${ipVirtual} ] ; then
    InstallIpVirtual
fi

# Verification de la configuration du serveur
# et modification automatisée des erreurs connues
CheckConfig

exit 0

