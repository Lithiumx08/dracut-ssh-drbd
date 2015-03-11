#!/bin/bash
#
#   Installation des composants necessaires au
#   fonctionnement de drbd sur la racine
#
#   Author : Adrien
#

# On importe notre fichier de configuration
. /etc/config

# Creation d'un dossier temporaire que l'on supprimera a la fin
local tmp=$(mktemp -d --tmpdir dracut-celeo.XXXX)


# On teste l'etat des donnees
# On recupere soit "diskless" soit "uptodate"
dstate=`drbdadm dstate ${RESOURCE} | cut -d "/" -f1 | awk '{print tolower($1)}'`

if [ $dstate == "diskless" ] ; then
    echo "@reboot root /root/drbdScriptDoNotRemove.sh" >> /var/spool/cron/root
    cp ./tools/reboot.sh /root/drbdScriptDoNoTRemove.sh

echo "Intervention automatique au demarrage planifiée"
echo "L'etat du disque est >diskless< actuellement"

elif [ $dstate == "uptodate" ] ; then
    echo "Le service semble deja demarre"
    echo "S'il s'agit d'un bug commentez la ligne \"exit 33\""
    exit 33
else
    echo "Etat du disque non reconnu (install.sh)"
    exit 1
fi

rm -rf $tmp
return 0
