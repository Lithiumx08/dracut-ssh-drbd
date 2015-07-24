#!/bin/bash

. ./config

# Sans ces packages / cmd l'install ne demarre pas
NEEDED_COMMANDS=""
NEEDED_PACKAGES=""

error=0
dropbearkey='dropbearkey'

for i in ${modToInstall} ; do
    case ${i} in
        88snmp)
            echo ${NEEDED_PACKAGES} | grep "dracut-network" 1>&2 > /dev/null
            if [ $? -eq 1 ] ; then
                NEEDED_PACKAGES="${NEEDED_PACKAGES} dracut-network"
            fi
            NEEDED_COMMANDS="${NEEDED_COMMANDS} snmpd"
            ;;
        89dropbear)
            echo ${NEEDED_PACKAGES} | grep "dracut-network" 1>&2 > /dev/null
            if [ $? -eq 1 ] ; then
                NEEDED_PACKAGES="${NEEDED_PACKAGES} dracut-network"
            fi
            NEEDED_PACKAGES="${NEEDED_PACKAGES} dracut-network"
            NEEDED_COMMANDS="${NEEDED_COMMANDS} dropbear"
            ;;
        90drbd)
            echo ${NEEDED_PACKAGES} | grep "dracut-network" 1>&2 > /dev/null
            if [ $? -eq 1 ] ; then
                NEEDED_PACKAGES="${NEEDED_PACKAGES} dracut-network"
            fi
            NEEDED_COMMANDS="${NEEDED_COMMANDS} sshpass rsync bc"
            ;;
        91python)
            NEEDED_COMMANDS="${NEEDED_COMMANDS} python"
            ;;
    esac
done

for cmd in ${NEEDED_COMMANDS} ; do
    if ! command -v ${cmd} &> /dev/null ; then
        echo "Please install ${cmd}!"
        error=$((error+1))
    fi
done

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

for i in ${modToInstall} ; do
    case ${i} in
        89dropbear)
            if [[ ! -d /etc/dracut-dropbear/ ]] ; then
                mkdir /etc/dracut-dropbear/
            fi
            if [[ ! -e /etc/dracut-dropbear/dropbear_rsa_host_key ]] ; then
                if command -v ${dropbearkey} $> /dev/null ; then
                    dropbearkey -t rsa -s 3072 -f /etc/dracut-dropbear/dropbear_rsa_host_key
                    echo "Cle RSA OK"	
                else 
                    echo "Cle RSA non installee"
                    echo "L'installation ne peut pas continuer"
                    exit 1
                fi
            fi
            ;;
    esac
done

touch .cmd_ok
