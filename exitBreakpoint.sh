#!/bin/bash
#
# Recupération de la version de Centos
#
function GetVersion {
    local version=0
    if cat /etc/centos-release | grep -o "7.0" > /dev/null ; then
        version=7
    elif cat /etc/centos-release | grep -o "6.6" > /dev/null ; then
        version=6
    fi
    return ${version}
}

# L'ajout de temps était necessaire dans centos 7 lors des tests effectués
function AddTime {
    GetVersion
    if [ $? -eq 7 ] ; then
        sleep 1
    elif [ $? -eq 6 ] ; then
        :
    elif [ $? -eq 0 ] ; then
        echo "Version de CentOS inconnue"
        echo "Aucun temps d'attente ajouté"
    fi
}

/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null

AddTime

/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null
