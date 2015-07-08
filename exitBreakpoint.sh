#!/bin/bash

# L'ajout de temps était necessaire dans centos 7 lors des tests effectués
addtime(){
    if cat /etc/*release* | grep -o "CentOS Linux 7" > /dev/null ; then
        sleep 1
    elif cat /etc/*release* | grep -o "6.6" > /dev/null ; then
        :
    else
        echo "Version de CentOS inconnue"
        echo "Aucun temps d'attente ajouté"
    fi
}

/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null

addtime

/sbin/tiocsti /dev/console "$(echo -e 'exit\r')" > /dev/null
