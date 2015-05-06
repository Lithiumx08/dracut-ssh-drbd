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
    
        echo "ifconfig eth0:1 ${ipVirtual}" >> ${serviceFile}
    
        chmod +x ${serviceFile}
    
        chkconfig `echo ${serviceFile} | awk -F'/' ' { print $4 }'` on
    
    fi
}
