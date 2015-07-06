#!/bin/bash
PREFIX='/sbin/'

#echo "Ip Master ?"
#read -e ipMaster
ipMaster='95.128.77.100'

#echo "Username ?"
#read -e sshUsername
sshUsername='root'

echo "Password"
read -e -s sshPassword


listDisk=`ls /dev/[hs]d[a-z]`


bootPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/boot") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
bootPart="/dev/${bootPart}"


rootPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
rootPart="/dev/${rootPart}"

swapPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="[SWAP]") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
swapPart="/dev/${swapPart}"

echo "Merci de quitter et de relancer si l'authentification a echouee"
echo "================================================================================="
echo "Indiquer le type de raid utilisé"
echo "1 - Hardware"
echo "2 - Software"
echo "3 - Software - Test"
echo "4 - Software - Suite"
echo "Other Key - Quit"
read -e raidType


lvmCopy=false

case ${raidType} in
    1)
        echo "================================================================================="
        echo "Copie de la table de partitions"
        echo "================================================================================="
        for i in ${listDisk} ; do
            sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}sfdisk -d ${i}"  | sfdisk ${i}
        done

        echo "================================================================================="
        echo "Creation des systemes de fichiers"
        echo "================================================================================="
        mkfs.ext4 ${bootPart}
        mkswap ${swapPart}

        echo "================================================================================="
        echo "Syncro du /boot"
        echo "================================================================================="
        mkdir /mnt/boot/
        mount -t ext4 ${bootPart} /mnt/boot/

        rsync -av --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:/boot/ /mnt/boot/
        cp -f -v /mnt/boot/initramfs-3.14.19-0.img.slave /mnt/boot/initramfs-3.14.19-0.img
        
        bootFirstLine=`cat /mnt/boot/grub/menu.lst | grep -o "(hd[0-9],[0-9])" | awk -v ligne=1 ' NR==ligne {print $1}'`
        bootSecondLine="`cat /mnt/boot/grub/menu.lst | grep -o "(hd[0-9],[0-9])" | awk -v ligne=1 ' NR==ligne {print $1}' | awk -F',' '{print $1}'`)"

        umount ${bootPart}

        echo "================================================================================="
        echo "Generation du nouveau grub"
        echo "================================================================================="
        /sbin/grub --batch <<EOT 1>/dev/null 2>/dev/null
root ${bootFirstLine}
setup ${bootSecondLine}
quit
EOT
        lvmCopy=true
        ;;
    2)
        echo "================================================================================="
        echo "Copie de la table de partitions"
        echo "================================================================================="
        for i in ${listDisk} ; do
            sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}sfdisk -d ${i}"  | sfdisk ${i}
        done
        ;;
    3)
        partitionFileName='/partitionsToReplicate'
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "cat /proc/mdstat | grep ^md[0-9] > ${partitionFileName}"
        rsync -av --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:${partitionFileName} ${partitionFileName}
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no rm -f /${partitionFileName}

        while read line ; do
            deviceRaid=$(echo ${line} | grep -o raid[0-5] | grep -o [0-9])
            deviceName=$(echo "/dev/$(echo ${line} | grep -o md[0-9])")
            deviceParts=$(for i in `echo ${line} | grep -o sd[a-z][0-9]` ; do echo "/dev/${i}" ; done)
            deviceNb=$(echo ${deviceParts} | wc -w )
            echo "Partition Name :"
            echo ${deviceName}
#            echo "/dev/$(echo ${line} | grep -o md[0-9])"
            echo "Raid Mode :"
            echo ${deviceRaid}
#            echo ${line} | grep -o raid[0-5] | grep -o [0-9]
            echo "Partitions used :"
            echo ${deviceParts}
            echo "Part numbers :"
            echo ${deviceNb}
#            echo "$(echo ${myParts} | wc -w )"
            echo "line for creation :"
            echo "mdadm --create ${deviceName} --level=${deviceRaid} --raid-devices=${deviceNb} `echo ${deviceParts}`"
            echo "=============="
        done < /${partitionFileName}

        ;;
    4)
        echo "================================================================================="
        echo "Creation des systemes de fichiers"
        echo "================================================================================="
        mkfs.ext4 ${bootPart}
        mkswap ${swapPart}

        echo "================================================================================="
        echo "Syncro du /boot"
        echo "================================================================================="
        mkdir /mnt/boot/
        mount -t ext4 ${bootPart} /mnt/boot/

        rsync -av --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:/boot/ /mnt/boot/
        cp -f -v /mnt/boot/initramfs-3.14.19-0.img.slave /mnt/boot/initramfs-3.14.19-0.img
        
        bootFirstLine=`cat /mnt/boot/grub/menu.lst | grep -o "(hd[0-9],[0-9])" | awk -v ligne=1 ' NR==ligne {print $1}'`
        bootSecondLine="`cat /mnt/boot/grub/menu.lst | grep -o "(hd[0-9],[0-9])" | awk -v ligne=1 ' NR==ligne {print $1}' | awk -F',' '{print $1}'`)"

        umount ${bootPart}

        echo "================================================================================="
        echo "Generation du nouveau grub"
        echo "================================================================================="
        /sbin/grub --batch <<EOT 1>/dev/null 2>/dev/null
root ${bootFirstLine}
setup ${bootSecondLine}
quit
EOT
        lvmCopy=true
        ;;
    *)
        echo "Bye !"
        exit 0
        ;;


esac

if ${lvmCopy} ; then
    echo "================================================================================="
    echo "Replication des partitions LVM"
    echo "================================================================================="
    lvmPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no pvdisplay | grep -i 'pv name' | awk -F' ' '{print $3}'`
    
    pvUuid=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm pvdisplay | grep -i uuid | awk '{print $3}'`
    vgName=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm vgdisplay | grep -i 'VG NAME' | awk '{print $3}'`
    rsync -avi --delete --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:/lvmsave/ /etc/lvm/
    pvcreate --uuid ${pvUuid} --restorefile /etc/lvm/archive/${vgName}_00000* ${lvmPart}
    vgcfgrestore ${vgName}
    vgimport ${vgName}
fi





