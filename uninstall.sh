#!/bin/bash

. config

rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/88snmp/
rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/89cryptssh/
rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/90drbd/
rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/91python/
echo "N'oubliez pas de générer le nouveau initramfs"
