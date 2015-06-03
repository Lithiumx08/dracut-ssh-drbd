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
    cat /etc/sysconfig/iptables | grep DRBD > /dev/null
    if [ $? = 1 ] ; then
        echo "/etc/sysconfig/iptables a verifier pour DRBD"
    fi

    cat /etc/fstab | grep UUID > /dev/null
    if [ $? = 0 ] ; then
        echo "Il semble rester des UUID dans le fstab"
    fi

    cat /etc/fstab | grep drbd > /dev/null
    if [ $? = 1 ] ; then
        echo "Aucune partition DRBD pour ne semble présente dans le fstab"
    fi

    cat /boot/grub/menu.lst | grep 'break=mount' > /dev/null
    if [ $? = 1 ] ; then
        echo "Aucun breakpoint ne semble configuré dans grub (/boot/grub/menu.lst)"
    fi
}
