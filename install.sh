#!/bin/bash
# Fichier de configuration
. config

# Creation des images initramfs
. tools/installInitramfs.sh

. tools/installModulesDir.sh

. tools/installPython.sh

initramfsInstall
initramfsNormal
exit 0


