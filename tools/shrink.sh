#!/bin/bash

. /etc/config

/etc/init.d/drbd stop

which bc >/dev/null 2>&1
if [ ! $? -eq 0 ]; then
    echo "Error: bc is not installed"
    exit 1
fi


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
drbdadm create-md ${RESOURCE}
/etc/init.d/drbd start

drbdadm primary ${RESOURCE} --force
drbdadm secondary ${RESOURCE}


