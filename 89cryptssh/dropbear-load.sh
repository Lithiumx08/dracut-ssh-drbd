#!/bin/bash

. /etc/config


ping -c5 8.8.8.8 > /dev/null
TEST=$?

if [ $TEST -ne 0 ] ; then

    case ${role} in
        master)
            ip=${ip_master}
            ;;
        slave)
            ip=${ip_slave}
            ;;
    esac
    
    case ${role} in
        master)
            hostname=${hostname_master}
            ;;
        slave)
            hostname=${hostname_slave}
            ;;
    esac

    # Configuration reseau du serveur
    ifconfig down ${devName}
    ifconfig ${devName} up
    ifconfig ${devName} ${ip} netmask ${netmask}
    hostname ${hostname}
    ip route add default via ${gw}
fi

[ -f /tmp/dropbear.pid ] || {
info '[Dropbear-sshd] Starting Dropbear'
info '[Dropbear-sshd] sshd port: ${dropbear_port}'
info '[Dropbear-sshd] sshd key fingerprint: ${key_fp}'
info '[Dropbear-sshd] Creating /var/log/lastlog'
mkdir -p /var/log > /var/log/lastlog

if ${allowPassword} ; then
    dropbear -m -p 22 -r /etc/dropbear/dropbear_rsa_host_key -P /tmp/dropbear.pid
    [ $? -gt 0 ] && info 'Dropbear sshd failed to start'

elif ! ${allowPassword} ; then
    dropbear -m -p 22 -s -r /etc/dropbear/dropbear_rsa_host_key -P /tmp/dropbear.pid
    [ $? -gt 0 ] && info 'Dropbear sshd failed to start'
else
    echo "Erreur au demarrage de dropbear"
fi

}
