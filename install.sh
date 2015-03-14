#!/bin/bash
# Fichier de configuration
. config

# Creation des images initramfs
. tools/installInitramfs.sh

. tools/installModulesDir.sh

initramfsInstall
initramfsNormal
exit 0


