#!/bin/bash

# Mise en place du service pour l'IP virtuelle uniquement si l'IP est spécifiée dans la configuration
# La vérification de l'existence de l'IP dans le fichier de config s'effectue lors de l'installation
function InstallIpVirtual {

    local serviceFile='/etc/init.d/ipVirtual'


    if [ -n ${serviceFile} ] ; then

cat > ${serviceFile} <<EOF
#!/bin/bash
#
#
# chkconfig: - 70 08

EOF

        echo "ifconfig ${devName}:1 ${ipVirtual} netmask ${netmask}" >> ${serviceFile}

        chmod +x ${serviceFile}

        chkconfig `echo ${serviceFile} | awk -F'/' ' { print $4 }'` on

    fi
}

function answer {
    local answer=''
    local returnValue=''
    local count=0
    while [[ $answer != 'yes'  ]] && [[ $answer != 'no'  ]] && [[ $answer != 'n'  ]] && [[ $answer != 'y'  ]] ; do
        if [ $count -ne 0 ] ; then
            echo "Please yes/no"
        fi
        read -e answer
        answer=`echo ${answer} | awk '{print tolower($0)}'`
        count=$(($count+1))
    done
    if [[ $answer == 'y'  ]] || [[ $answer == 'yes'  ]] ; then
        returnValue=0
    else
        returnValue=1
    fi
    unset answer
    return $returnValue

}

# Verification de la configuration en vigueur sur le serveur et modification automatique au besoin
# iptables :
# Ajout des 2 IP pour autoriser la réplication
# fstab :
# Suppression des UUID
# Ajout des partitions DRBD
function CheckConfig {
    local preEcho="*** Conf Check *** => "
    cat /etc/sysconfig/iptables | grep DRBD > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} /etc/sysconfig/iptables a verifier pour DRBD"
        echo "!!! Ajouter la configuration DRBD automatiquement ? (yes/no) !!!"
        answer
        if [ $? -eq 0 ] ; then
            local myLine=`sed -n '/# DNS/=' /etc/sysconfig/iptables | awk -v ligne=1 'NR== ligne {print $NR}'`
            sed -i $(($myLine))i"# DRBD" /etc/sysconfig/iptables
            sed -i $(($myLine+1))i"-A OUTPUT -d ${ip_master}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+2))i"-A OUTPUT -d ${ip_slave}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+3))i'\\' /etc/sysconfig/iptables
            sed -i $(($myLine+4))i"-A INPUT -d ${ip_master}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+5))i"-A INPUT -d ${ip_slave}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+6))i'\\' /etc/sysconfig/iptables
            unset myLine
        fi
    fi

    cat /etc/fstab | grep UUID > /dev/null
    if [ $? = 0 ] ; then
        echo "${preEcho} Il semble rester des UUID dans le fstab"
        echo "Remplacer les UUID automatiquement ? (yes/no)"
        echo "!!! Valable uniquement pour /boot et SWAP !!!"
        answer
        if [ $? -eq 0 ] ; then
            local bootFstab="/dev/`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/boot") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`"
            local bootUuid=`cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="/boot") print $1}'`
            sed -i "s:${bootUuid}:${bootFstab}:" /etc/fstab

            local swappart="/dev/`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="[SWAP]") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`"
            local swapUuid=`cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="swap") print $1}'`
            local swapline="${swappart}   none    `cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="swap") print $3, $4, $5, $6}'`"
            sed -i /$swapUuid/d /etc/fstab
            echo ${swapline} >> /etc/fstab

        fi
    fi

    cat /etc/fstab | grep drbd > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} Aucune partition DRBD pour ne semble présente dans le fstab"
        echo "Ajouter les partitions DRBD automatiquement ? (yes/no)"
        echo "!!! Valable uniquement pour une partition / et /home !!!"
        answer
        if [ $? -eq 0 ] ; then
            cat /etc/fstab | grep '^[#]' | grep mapper > /dev/null
            if [ $? = 1 ] ; then
                sed -i '/mapper/ s/^/# /' /etc/fstab
            fi
            local drbdParts=`cat ${DRBD_CONFIG} | grep drbd | awk -F' ' '{print $2}' | awk -F';' '{print $1}'`
            for i in ${drbdParts} ; do
                if [[ ${i} == ${DRBD_ROOT} ]] ; then
                    echo "${i}  /   ext4    defaults    0 0" >> /etc/fstab
                else
                    echo "${i}  /home   ext4    defaults    0 0" >> /etc/fstab
                fi

            done
        fi
    fi

    cat /boot/grub/menu.lst | grep 'break=mount' > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} Aucun breakpoint ne semble configuré dans grub (/boot/grub/menu.lst)"
    fi
}
