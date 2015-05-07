#!/bin/bash

#echo "Ip Master ?"
#read -e ipMaster
ipMaster='95.128.77.100'

#echo "Username ?"
#read -e sshUsername
sshUsername='root'

echo "Password"
read -e -s sshPassword

#bootPart=`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/boot") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
#lvmPart=`pvdisplay | grep -i 'pv name' | awk -F' ' '{print $3}'`
#rootPart=`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
#swapPart=`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="[SWAP]") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`

PREFIX='/sbin/'

swapPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}fdisk -l /dev/sda | grep swap | awk -F' ' '{print $1}'`
echo $swapPart

bootPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}fdisk -l /dev/sda | grep "/dev" | grep "*" | awk -F' ' '{print $1}'`
echo $bootPart

lvmPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}fdisk -l /dev/sda | grep "LVM" | awk -F' ' '{print $1}'`
echo $lvmPart

#`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no`
echo "Mode :"
echo "1 - Normal"
echo "2 - Initramfs"
read -e mode

case $mode in
    1)
        echo "Copie de la table de partitions"
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}sfdisk -d /dev/sda"  | sfdisk /dev/sda

        echo "Creation des systemes de fichiers"
        mkfs.ext4 $bootPart
        mkswap $swapPart

        echo "Syncro du /boot"
        mkdir /mnt/boot/
        mount -t ext4 $bootPart /mnt/boot/

        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no mkdir /boot
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no mount -t ext4 ${bootPart} /boot

        rsync -av --rsh="sshpass -p $sshPassword ssh -l $sshUsername" ${ipMaster}:/boot/ /mnt/boot/
        cp -f -v /mnt/boot/initramfs-3.14.19-0.img.slave /mnt/boot/initramfs-3.14.19-0.img

        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no umount /boot
        umount ${bootPart}

        echo "Generation du nouveau grub"
        /sbin/grub --batch <<EOT 1>/dev/null 2>/dev/null
root (hd0,0)
setup (hd0)
quit
EOT


        ;;
    2)
        pvUuid=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm pvdisplay | grep -i uuid | awk '{print $3}'`
        echo $pvUuid
        vgName=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm vgdisplay | grep -i 'VG NAME' | awk '{print $3}'`
        echo $vgName

        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "sed -i s/'locking_type = 4'/'locking_type = 1'/ /etc/lvm/lvm.conf"
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}lvm vgchange -an ${vgName}"
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}lvm vgexport ${vgName}"
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}lvm vgcfgbackup"
        rsync -avi --delete --rsh="sshpass -p $sshPassword ssh -l $sshUsername" ${ipMaster}:/etc/lvm/ /etc/lvm/
        pvcreate --uuid $pvUuid --restorefile /etc/lvm/archive/${vgName}_00000* $lvmPart
        vgcfgrestore $vgName
        vgimport $vgName
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}lvm vgcfgrestore $vgName"
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}lvm vgimport ${vgName}"
        ;;
    *)
        echo "Bye !"
        exit 0
        ;;


esac
