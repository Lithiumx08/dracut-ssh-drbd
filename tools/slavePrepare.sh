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


echo "Partition swap => $swapPart"

echo "Partition boot => $bootPart"

echo "Partition LVM => $lvmPart"

echo "Partition root => $rootPart"

bootFirstLine=`cat /boot/grub/menu.lst | grep -o "(hd[0-9],[0-9])" | awk -v ligne=1 ' NR==ligne {print $1}'`
bootSecondLine="`cat /boot/grub/menu.lst | grep -o "(hd[0-9],[0-9])" | awk -v ligne=1 ' NR==ligne {print $1}' | awk -F',' '{print $1}'`)"



echo "Indiquer le type de raid utilisé"
echo "1 - Hardware"
echo "2 - Software"
echo "Other Key - Quit"
read -e raidType

case ${raidType} in
    1)
        echo "Copie de la table de partitions"
        for i in ${listDisk} ; do
            sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}sfdisk -d ${i}"  | sfdisk ${i}
        done

        echo "Creation des systemes de fichiers"
        mkfs.ext4 ${bootPart}
        mkswap ${swapPart}

        echo "Syncro du /boot"
        mkdir /mnt/boot/
        mount -t ext4 ${bootPart} /mnt/boot/

        rsync -av --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:/boot/ /mnt/boot/
        cp -f -v /mnt/boot/initramfs-3.14.19-0.img.slave /mnt/boot/initramfs-3.14.19-0.img

        umount ${bootPart}

        echo "Generation du nouveau grub"
        /sbin/grub --batch <<EOT 1>/dev/null 2>/dev/null
root ${bootFirstLine}
setup ${bootSecondLine}
quit
EOT

        ;;
    *)
        echo "Bye !"
        exit 0
        ;;


esac

lvmPart=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no pvdisplay | grep -i 'pv name' | awk -F' ' '{print $3}'`

pvUuid=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm pvdisplay | grep -i uuid | awk '{print $3}'`
echo ${pvUuid}
vgName=`sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no ${PREFIX}lvm vgdisplay | grep -i 'VG NAME' | awk '{print $3}'`
echo ${vgName}
rsync -avi --delete --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:/lvmsave/ /etc/lvm/
pvcreate --uuid ${pvUuid} --restorefile /etc/lvm/archive/${vgName}_00000* ${lvmPart}
vgcfgrestore ${vgName}
vgimport ${vgName}




