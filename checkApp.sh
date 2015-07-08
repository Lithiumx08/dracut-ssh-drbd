#!/bin/bash

# Sans ces packages / cmd l'install ne demarre pas
NEEDED_COMMANDS="dropbear gcc snmpd sshpass"
NEEDED_PACKAGES="dracut-network"

error=0
dropbearkey='dropbearkey'

for cmd in ${NEEDED_COMMANDS} ; do
    if ! command -v ${cmd} &> /dev/null ; then
        echo "Please install ${cmd}!"
        error=$((error+1))
    fi
done

if [[ ! -d /etc/dracut-cryptssh/ ]] ; then
    mkdir /etc/dracut-cryptssh/
fi

if [[ ! -e /etc/dracut-cryptssh/dropbear_rsa_host_key ]] ; then
    if command -v ${dropbearkey} $> /dev/null ; then
        dropbearkey -t rsa -s 3072 -f /etc/dracut-cryptssh/dropbear_rsa_host_key
        echo "Cle RSA OK"	
    else 
        echo "Cle RSA non installee"
        error=$((error+1))
    fi
fi


for pkg in ${NEEDED_PACKAGES} ; do
    if ! rpm -q ${pkg} &> /dev/null ; then
        echo "Please install ${pkg} package!"
        error=$((error+1))
    fi
done

if [[ ${error} > 1 ]] ; then
    echo "Erreurs rencontrees"
    echo "Si vous savez ce que vous faites vous pouvez editer la liste des commandes requises dans checkApp.sh"
	exit 1
fi

touch .cmd_ok
