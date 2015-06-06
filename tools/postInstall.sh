#!/bin/bash

function InstallIpVirtual {

    serviceFile='/etc/init.d/ipVirtual'


    if [ -n ${serviceFile} ] ; then

cat > ${serviceFile} <<EOF
#!/bin/bash
#
#
# chkconfig: - 70 08
    
EOF
    
        echo "ifconfig ${devName}:1 ${ipVirtual}" >> ${serviceFile}
    
        chmod +x ${serviceFile}
    
        chkconfig `echo ${serviceFile} | awk -F'/' ' { print $4 }'` on
    
    fi
}

function CheckConfig {
    preEcho="*** Conf Check *** => "
    cat /etc/sysconfig/iptables | grep DRBD > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} /etc/sysconfig/iptables a verifier pour DRBD"
    fi

    cat /etc/fstab | grep UUID > /dev/null
    if [ $? = 0 ] ; then
        echo "${preEcho} Il semble rester des UUID dans le fstab"
        echo "Remplacer les UUID automatiquement ? (yes/no)"
        echo "Valable uniquement pour /boot et SWAP"
        read -e userAnswer
        if [[ ${userAnswer} == 'yes' ]] ; then
            bootFstab="/dev/`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/boot") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`"
            bootUuid=`cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="/boot") print $1}'`
            sed -i "s:${bootUuid}:${bootFstab}:" /etc/fstab

            swappart="/dev/`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="[SWAP]") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`"
            swapUuid=`cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="swap") print $1}'`
            swapline="${swappart}   none    `cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="swap") print $3, $4, $5, $6}'`"
            sed -i /$swapUuid/d /etc/fstab
            echo ${swapline} >> /etc/fstab

        fi
        unset userAnswer
    fi

    cat /etc/fstab | grep drbd > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} Aucune partition DRBD pour ne semble présente dans le fstab"
        echo "Ajouter les partitions DRBD automatiquement ? (yes/no)"
        echo "Valable uniquement pour une partition / et /home"
        read -e userAnswer
        if [[ ${userAnswer} == 'yes' ]] ; then
            cat /etc/fstab | grep '^[#]' | grep mapper > /dev/null
            if [ $? = 1 ] ; then
                sed -i '/mapper/ s/^/# /' /etc/fstab
            fi
            drbdParts=`cat ${DRBD_CONFIG} | grep drbd | awk -F' ' '{print $2}' | awk -F';' '{print $1}'`
            for i in ${drbdParts} ; do
                if [[ ${i} == ${DRBD_ROOT} ]] ; then
                    echo "${i}  /   ext4    defaults    0 0" >> /etc/fstab
                else
                    echo "${i}  /home   ext4    defaults    0 0" >> /etc/fstab
                fi

            done
        fi
        unset userAnswer
    fi

    cat /boot/grub/menu.lst | grep 'break=mount' > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} Aucun breakpoint ne semble configuré dans grub (/boot/grub/menu.lst)"
    fi
}
