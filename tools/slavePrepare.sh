#!/bin/bash

#echo "Ip Master ?"
#read -e ipMaster
ipMaster='95.128.77.100'

#echo "Username ?"
#read -e sshUsername
sshUsername='root'

echo "Password"
read -e -s sshPassword

bootPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/boot") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
bootPart="/dev/$bootPart"

lvmPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no pvdisplay | grep -i 'pv name' | awk -F' ' '{print $3}'`

rootPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
rootPart="/dev/$rootPart"

swapPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="[SWAP]") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`
swapPart="/dev/$swapPart"

PREFIX='/sbin/'

echo "Partition swap => $swapPart"

echo "Partition boot => $bootPart"

echo "Partition LVM => $lvmPart"

echo "Partition root => $rootPart"

echo "1 - Installation"
echo "Other Key - Quit"
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

        rsync -av --rsh="sshpass -p $sshPassword ssh -l $sshUsername" ${ipMaster}:/boot/ /mnt/boot/
        cp -f -v /mnt/boot/initramfs-3.14.19-0.img.slave /mnt/boot/initramfs-3.14.19-0.img

        umount ${bootPart}

        echo "Generation du nouveau grub"
        /sbin/grub --batch <<EOT 1>/dev/null 2>/dev/null
root (hd0,0)
setup (hd0)
quit
EOT

        pvUuid=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm pvdisplay | grep -i uuid | awk '{print $3}'`
        echo $pvUuid
        vgName=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm vgdisplay | grep -i 'VG NAME' | awk '{print $3}'`
        echo $vgName
        rsync -avi --delete --rsh="sshpass -p $sshPassword ssh -l $sshUsername" ${ipMaster}:/lvmsave/ /etc/lvm/
        pvcreate --uuid $pvUuid --restorefile /etc/lvm/archive/${vgName}_00000* $lvmPart
        vgcfgrestore $vgName
        vgimport $vgName
        ;;
    *)
        echo "Bye !"
        exit 0
        ;;


esac
