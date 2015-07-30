#!/bin/bash
# Ce script n'est pas prévu pour etre executé de facon autonome

. config

for i in ${modToUninstall} ; do
    rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/${i}/
done
echo "N'oubliez pas de générer le nouveau initramfs"
