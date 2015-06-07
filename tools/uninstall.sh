#!/bin/bash

. config

for i in ${modToUninstall} ; do
    rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/${i}/
done
echo "N'oubliez pas de générer le nouveau initramfs"
