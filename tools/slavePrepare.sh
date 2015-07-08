#!/bin/bash
PREFIX='/sbin/'

echo "Ip Master ?"
read -e ipMaster
#ipMaster='95.128.77.100'

echo "Username ?"
read -e sshUsername
#sshUsername='root'

echo "Password"
read -e -s sshPassword

function copyPartitionTable {
    echo "================================================================================="
    echo "Copie de la table de partitions"
    echo "================================================================================="
    for i in ${listDisk} ; do
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "${PREFIX}sfdisk -d ${i}"  | sfdisk ${i}
    done
}

function postCopy {
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

    # Ces infos sont récupérés dans le grub directement comme ca pas d'erreur, le master a la meme chose
    # du genre hd(0,0)
    bootFirstLine=`cat /mnt/boot/grub/menu.lst | grep -o "(hd[0-9],[0-9])" | awk -v ligne=1 ' NR==ligne {print $1}'`
    # du genre hd(0)
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
}


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
echo "Other Key - Quit"
read -e raidType

case ${raidType} in
    1)
        copyPartitionTable

        postCopy
        ;;
    2)
        copyPartitionTable

        # On recupere dans un fichier puis on le supprime:
        # La liste des partition, des types de raid, et le nom des partitions
        partitionFileName='/partitionsToReplicate'
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "cat /proc/mdstat | grep ^md[0-9] > ${partitionFileName}"
        rsync -av --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:${partitionFileName} ${partitionFileName}
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no rm -f /${partitionFileName}

        # On recupere la liste des uuid associés a chaque partition dans un fichier, puis on supprime le fichier sur le master
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no "mdadm --detail --scan > /uuidToCheck"
        rsync -av --rsh="sshpass -p ${sshPassword} ssh -l ${sshUsername}" ${ipMaster}:/uuidToCheck /uuidToCheck
        sshpass -p "${sshPassword}" ssh ${sshUsername}@${ipMaster} -o StrictHostKeyChecking=no rm -f /uuidToCheck

        # On créer l'array tant que le fichier contenant les partitions n'a pas été lu entierement
        while read line ; do
            # Type de raid a utiliser
            deviceRaid=$(echo ${line} | grep -o raid[0-5] | grep -o [0-9])
            # Nom de la partition
            deviceName=$(echo "/dev/$(echo ${line} | grep -o md[0-9])")
            # Partitions utilisées pour l'array
            deviceParts=$(for i in `echo ${line} | grep -o sd[a-z][0-9]` ; do echo "/dev/${i}" ; done)
            # Nombre de partitions pour le raid (particulierement utile pour les raids 5)
            deviceNb=$(echo ${deviceParts} | wc -w )

            # UUID du raid soft a utiliser
            # Si l'UUID n'est pas défini, on aura une partition différente utilisée au montage (md127 a la place de md0 par exemple)
            # Cette erreur génère le mod isci_wait not found lors du chargement de l'initramfs
            while read lineBis ; do
                check=`echo ${lineBis} | grep ${deviceName} | awk -F' ' '{print $5}' | awk -F'=' '{print $2}'`
                if [[ ${check} != '' ]] ; then
                    deviceUuid=${check}
                fi
            done < /uuidToCheck

            # On doit utiliser une version de metadata différente pour la partition de boot, les 2 lignes sont donc legerement différentes
            # BOOT => 1.0 (attention si on utilise 1 la version utilisée réellement sera 1.2)
            # LES AUTRES => 1.1 ou 1.2 (par défaut Centos utilise 1.1)
            if [[ ${bootPart} == ${deviceName} ]] ; then
                mdadm --create ${deviceName} --level=${deviceRaid} --raid-devices=${deviceNb} `echo ${deviceParts}` --metadata=1.0 -u "${deviceUuid}"
            else
                mdadm --create ${deviceName} --level=${deviceRaid} --raid-devices=${deviceNb} `echo ${deviceParts}` --metadata=1.1 -u "${deviceUuid}"
            fi

        done < /${partitionFileName}

        postCopy
        ;;
    *)
        echo "Bye !"
        exit 0
        ;;
esac
