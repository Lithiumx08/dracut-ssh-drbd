#!/bin/bash

. config

rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/88snmp/
rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/89cryptssh/
rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/90drbd/
dracut -f
