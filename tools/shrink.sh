#!/bin/bash

. /etc/config

# Si ce script doit tourner sur l'esclave, il faut virer la ligne "primary --force"
# Merci recherche dans le fichier
if [[ ${role} == 'slave' ]] ; then
    echo "C'est pas prévu pour tourner sur l'esclave, tu vas foutre la merde ..."
    exit 1
fi

# What else
/etc/init.d/drbd stop

# Sans bc c'est la merde
# Faut pas faire n'imp avec le fichier de conf
which bc >/dev/null 2>&1
if [ ! $? -eq 0 ]; then
    echo "Error: bc is not installed"
    echo "T'as encore touché a la conf n'importe comment ..."
    exit 1
fi

# Pas de blabla la dessus, pour plus d'infos :
# https://drbd.linbit.com/users-guide/ch-internals.html#s-meta-data-size
# Si t'aimes pas les maths evite ca
# Te voila prévenu
for DEVICE in ${lvm} ; do

    SECTOR_SIZE=$( blockdev --getss $DEVICE )
    SECTORS=$( blockdev --getsz $DEVICE )
    MD_SIZE=$( echo "((($SECTORS + (2^18)-1) / 262144 * 8) + 72)" | bc )
    FS_SIZE=$( echo "$SECTORS - $MD_SIZE" | bc )

    MD_SIZE_MB=$( echo "($MD_SIZE / 4 / $SECTOR_SIZE) + 1" | bc )
    FS_SIZE_MB=$( echo "($FS_SIZE / 4 / $SECTOR_SIZE)" | bc )

    echo "Filesystem: $FS_SIZE_MB MiB"
    echo "Filesystem: $FS_SIZE Sectors"
    echo "Meta Data:  $MD_SIZE_MB MiB"
    echo "Meta Data:  $MD_SIZE Sectors"
    echo "--"
    echo "Resize commands: resize2fs -p "$DEVICE $FS_SIZE_MB"M"

    e2fsck -f ${DEVICE}
    resize2fs -p ${DEVICE} $FS_SIZE_MB"M"
done

# Une fois le paritionnement effectué on peut créer les metadatas
drbdadm create-md ${RESOURCE}

# On relance DRBD
/etc/init.d/drbd start

# On force le 1er passage en primaire pour l'accès aux données puisque le serveur est tout neuf
drbdadm primary ${RESOURCE} --force

# On repasser en secondaire pour eviter les betises
drbdadm secondary ${RESOURCE}

# L'arret est indispensable pour recupere les infos LVM pour la replication sur l'esclave
/etc/init.d/drbd stop

# Les données LVM doivent etre exportées pour pouvoir importer de la meme maniere de l'autre coté
# On retrouvera les fichiers sur le système dans /lvmsave/
vgName=`lvm vgdisplay | grep -i 'VG NAME' | awk '{print $3}'`

sed -i s/'locking_type = 4'/'locking_type = 1'/ /etc/lvm/lvm.conf

lvm vgchange -an ${vgName}

lvm vgexport ${vgName}

lvm vgcfgbackup

rsync -avi --delete /etc/lvm/ /lvmsave/

lvm vgcfgrestore

lvm vgimport ${vgName}

lvm vgchange -ay ${vgName}

#~On relande DRBD comme si de rien n'était
/etc/init.d/drbd start

# On déplace les données sur la partition systeme sinon tout va disparaitre de l'initramfs
drbdadm primary ${RESOURCE}

# Sysroot parce que c'est la partition normale lors du boot d'un systeme
mount -t ext4 ${DRBD_ROOT} /sysroot

rsync -avi --delete /lvmsave/ /sysroot/lvmsave/

umount ${DRBD_ROOT}

# C'est fini
# T'as pas de preuves, j'ai rien fait
drbdadm secondary ${RESOURCE}
