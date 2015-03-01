#!/bin/sh
#
#   Script lors de l'etat diskless
#   Ne pas executer directement
#

dstate=`drbdadm dstate ${ROOT_RESOURCE} | cut -d "/" -f1 | awk '{print tolower($1)}'`

if [ $dstate == "uptodate" ] ; then
    sed -i '/@reboot root \/root\/drbdScriptDoNotRemove/d' /var/spool/cron/root
    rm -f /root/drbdScriptDoNotRemove.sh

else
    echo "/////////////////////////////////////////////////////" >> /var/log/messages
    echo "/////////////////////////////////////////////////////" >> /var/log/messages
    echo "///////////// DRBD STATE UNKNOWN ////////////////////" >> /var/log/messages
    echo "/// Aucune action menee au demarrage de la machine///" >> /var/log/messages
    echo "////////// /root/drbdScriptDoNotRemove.sh ///////////" >> /var/log/messages
    echo "/////////////////////////////////////////////////////" >> /var/log/messages
    echo "/////////////////////////////////////////////////////" >> /var/log/messages
fi
