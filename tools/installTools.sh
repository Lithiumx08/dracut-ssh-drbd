#!/bin/bash
#
# Author : Adrien
#
# Contient tous les outils necessaires à l'installation des modules de dracut
#
#


##########################################
##############    TOOLS   ################
##########################################
#
# Fonction permettant de demander a l'utilisateur si oui ou non il souhaite effectuer l'action
#
function Answer {
    # Contient la réponse de l'utilisateur
    local answer=''
    # Sera utilisée a la fin pour transformer la réponse de l'utilisateur en valeur standard (0/1)
    local returnValue=''
    # Compteur pour eviter de rester dans la boucle trop longtemps
    local count=0
    # On crée une boucle tant que la réponse attendue n'est pas correcte
    while [[ ${answer} != 'yes'  ]] && [[ ${answer} != 'no'  ]] && [[ ${answer} != 'n'  ]] && [[ ${answer} != 'y'  ]] ; do
        # Si on a fait 10 tours dans la boucle, on force a non, et on casse la boucle
        if [ ${count} -eq 10 ] ; then
            answer='n'
            echo "N'ecrit pas n'importe quoi le prochain coup"
            echo "Value set to >no<"
            break;
        # Le message n'est a afficher qu'apres le 1er tour de boucle pisque la question est demandée avant d'appeler la fonction
        elif [ ${count} -ne 0 ] ; then
            echo "Please yes/no"
        fi
        # On demande a l'utilisateur sa réponse
        read -e answer
        # On repasse tout en minuscule
        answer=`echo ${answer} | awk '{print tolower($0)}'`
        # Le compteur est la pour afficher le yes/no en cas d'erreur de frappe, et transmettre une valeur par défaut si l'utilisateur fait n'importe quoi
        count=$(($count+1))
    done

    # On utilise une valeur standard pour le retour de fonction
    # 0 => l'utilisateur a répondu oui
    # 1 => l'utilisateur a répondu non
    if [[ ${answer} == 'y'  ]] || [[ ${answer} == 'yes'  ]] ; then
        returnValue=0
    else
        returnValue=1
    fi
    return ${returnValue}
}

#
# Recupération de la version de Centos
#
function GetVersion {
    local version=0
    if cat /etc/centos-release | grep -o "7.0" > /dev/null ; then
        version=7
    elif cat /etc/centos-release | grep -o "6.6" > /dev/null ; then
        version=6
    fi
    return ${version}
}

#
# Verification de la configuration en vigueur sur le serveur et modification automatique au besoin
# iptables :
# Ajout des 2 IP pour autoriser la réplication
# fstab :
# Suppression des UUID
# Ajout des partitions DRBD
#
function CheckConfig {
    # Pas envie d'ecrire ca a chaque fois
    local preEcho="*** Conf Check *** => "
    # Si aucune entete DRBD n'est présente on ajoute les lignes dans la conf
    cat /etc/sysconfig/iptables | grep -i drbd > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} /etc/sysconfig/iptables a verifier pour DRBD"
        echo "!!! Ajouter la configuration DRBD automatiquement ? (yes/no) !!!"
        Answer
        if [ $? -eq 0 ] ; then
            # On prend le numéro de ligne pour l'entete DNS, et on ajoute les lignes relatives a DRBD juste au dessus
            local myLine=`sed -n '/# DNS/=' /etc/sysconfig/iptables | awk -v ligne=1 'NR== ligne {print $NR}'`
            sed -i $(($myLine))i"# DRBD" /etc/sysconfig/iptables
            sed -i $(($myLine+1))i"-A OUTPUT -d ${ip_master}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+2))i"-A OUTPUT -d ${ip_slave}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+3))i'\\' /etc/sysconfig/iptables
            sed -i $(($myLine+4))i"-A INPUT -d ${ip_master}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+5))i"-A INPUT -d ${ip_slave}/32 -j ACCEPT" /etc/sysconfig/iptables
            sed -i $(($myLine+6))i'\\' /etc/sysconfig/iptables
            unset myLine
        fi
        echo "================================================================================="
    fi
    # On recherche les UUID dans le fichier fstab
    cat /etc/fstab | grep UUID > /dev/null
    if [ $? = 0 ] ; then
        echo "${preEcho} Il semble rester des UUID dans le fstab"
        echo "Remplacer les UUID automatiquement ? (yes/no)"
        echo "!!! Valable uniquement pour /boot et SWAP !!!"
        Answer
        if [ $? -eq 0 ] ; then
            local bootFstab="/dev/`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="/boot") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`"
            local bootUuid=`cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="/boot") print $1}'`
            sed -i "s:${bootUuid}:${bootFstab}:" /etc/fstab
            local swappart="/dev/`lsblk -nl -o name,mountpoint,label | awk -F' ' '{if ($2=="[SWAP]") print $1}'| awk -v ligne=1 ' NR == ligne { print $0}'`"
            local swapUuid=`cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="swap") print $1}'`
            local swapline="${swappart}   none    `cat /etc/fstab | grep UUID | awk -F' ' '{if ($2=="swap") print $3, $4, $5, $6}'`"
            sed -i /$swapUuid/d /etc/fstab
            echo ${swapline} >> /etc/fstab
        fi
        echo "================================================================================="
    fi
    # On recherche les partitions DRBD dans le fstab
    cat /etc/fstab | grep drbd > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} Aucune partition DRBD pour ne semble présente dans le fstab"
        echo "Ajouter les partitions DRBD automatiquement ? (yes/no)"
        echo "!!! Valable uniquement pour une partition / et /home !!!"
        Answer
        if [ $? -eq 0 ] ; then
            # On recherche les lignes commencant par un # et contenant 'mapper', cela fait donc reference uniquement aux partitions LVM
            # On ajoute donc un # devant la ligne car on ne les montera plus directement
            cat /etc/fstab | grep '^[#]' | grep mapper > /dev/null
            if [ $? = 1 ] ; then
                sed -i '/mapper/ s/^/# /' /etc/fstab
            fi
            # On ajoute les partitions DRBD automatiquement
            local drbdParts=`cat ${DRBD_CONFIG} | grep drbd | awk -F' ' '{print $2}' | awk -F';' '{print $1}'`
            for i in ${drbdParts} ; do
                if [[ ${i} == ${DRBD_ROOT} ]] ; then
                    echo "${i}  /   ext4    defaults    0 0" >> /etc/fstab
                else
                    echo "${i}  /home   ext4    defaults    0 0" >> /etc/fstab
                fi
            done
        fi
        echo "================================================================================="
    fi
    # On verifie si le breakpoint est créé
    cat /boot/grub/menu.lst | grep 'break=mount' > /dev/null
    if [ $? = 1 ] ; then
        echo "${preEcho} Aucun breakpoint ne semble configuré dans grub (/boot/grub/menu.lst)"
        echo "Ajouter le breakpoint automatiquement ? (yes/no)"
        Answer
        if [ $? -eq 0 ] ; then
            sed -i "/kernel.*$(uname -r)/ s/$/ rdbreak=mount/" /boot/grub/grub.conf
        fi
        echo "================================================================================="
    fi
}

#
# Installation des répertoires, et des fichiers necessaires
#
function InstallDirectory {
    # On recupere la version de CentOS
    GetVersion
    local centosRelease=$?
    # Suppression des dossiers precedemment créés
    for i in ${modToUninstall} ; do
        rm -rf ${DRACUT_MODULE_DIR}/${i}
    done
    # On créé le dossier de modules s'il n'existe pas
    mkdir -p ${DRACUT_MODULE_DIR}/
    # On installe les nouveaux modules
    for i in ${modToInstall} ; do
        cp -a ${i} ${DRACUT_MODULE_DIR}
        cp -p ./config ${DRACUT_MODULE_DIR}/${i}
        cp -p ./exitBreakpoint.sh ${DRACUT_MODULE_DIR}/${i}
        cp -p ./tiocsti ${DRACUT_MODULE_DIR}/${i}
        echo "dracut_install ${commandsToAdd}" >> ${DRACUT_MODULE_DIR}/${i}/install
        echo "${i} installé"
        echo "instmods ${devName_master}" >> ${DRACUT_MODULE_DIR}/${i}/installkernel
    # Specifications d'installation suivant les modules
        case ${i} in
            89dropbear)
                # Sur CentOS 6 rien a faire, donc le cas n'est pas traité
                if [[ ${i} == "89dropbear" ]] ; then
                    # Gestion de l'arret de l'accès SSH suivant la version de CentOS
                    # Sur CentOS 7 l'arret se fait automatiquement, on n'execute donc pas le script
                    if [ ${centosRelease} -eq 7 ] ; then
                        sed -i /'kill-dropbear.sh'/d ${DRACUT_MODULE_DIR}/${i}/install
                    # Si la version de CentOS est inconnue on previent l'utilisateur
                    elif [ ${centosRelease} -eq 0 ] ; then
                        echo "!!! Version de CentOS inconnue !!!"
                        echo "Verifiez comment doit s'arreter l'accès SSH sur cet OS"
                        echo "Veillez a avoir accès a la console physique en cas de probleme lors du boot de l'OS"
                    fi
                fi
                # On ne copie pas le hash du password root si la connexion par
                # mot de passe n'est pas autorisée
                if ! ${allowPassword} ; then
                    sed -i /'\/etc\/shadow'/d ${DRACUT_MODULE_DIR}/89dropbear/install
                fi
                ;;
            # On copie la liste de fichiers/dossiers à installer
            # La liste est etablie en fonction de la variable pythonpath dans le fichier de configuration
            91python)
                cat .pythonFiles >> ${DRACUT_MODULE_DIR}/${i}/install
                ;;
        esac
    done
    # On passe de dash a bash si la config le demande et si on est sur CentOS 6
    if [[ ${centosRelease} == 6 ]] && ${useBash} ; then
        if [[ -d ${DRACUT_MODULE_DIR}/00dash/ ]] ; then
            rm -rf ${DRACUT_MODULE_DIR}/00dash/
        fi
        if [[ ! -d ${DRACUT_MODULE_DIR}/00bash/ ]] ; then
            cp -a 00bash ${DRACUT_MODULE_DIR}
        fi
    fi
    echo "================================================================================="
}

#
# Installation de l'initramfs de tous les jours
#
function InitramfsNormal {
    # On ajoute les informations requises au bon fonctionnement de DRBD dans le fichier hosts
    # Si cette partie est supprimée, il faut penser a le faire avant installation sinon ce ne fonctionnera pas
    cat /etc/hosts | grep ${ip_master} > /dev/null
    if [ $? = 1 ] ; then
        echo "${ip_master}  ${hostname_master}" >> /etc/hosts
    fi
    cat /etc/hosts | grep ${ip_slave} > /dev/null
    if [ $? = 1 ] ; then
        echo "${ip_slave}  ${hostname_slave}" >> /etc/hosts
    fi
    echo "N'oubliez pas de vérifier si les fichiers suivants sont correctement configurés avant génération :"
    echo "- /usr/local/drbd/etc/drbd.conf"
    echo "- /etc/init.d/drbd"
    echo "Eventuellement la clé ssh dans /root/.ssh/authorized_keys"
    echo "================================================================================="
    # On vérifie si une sauvegarde de l'initramfs est présente avant toute chose, et on previent l'utilisateur
    # Libre a lui de stopper l'execution et d'en générer une s'il le souhaite
    if [ -e /boot/initramfs-`uname -r`.img.bak ] ; then
        echo "Une sauvegarde de l'Initramfs est presente"
    else
        echo "Aucune sauvegarde de l'initramfs ne semble presente"
    fi
    echo "================================================================================="
    # Génération de l'initramfs
    echo "Generer le nouveau Initramfs (yes/no) ?"
    Answer
    if [ $? -eq 0 ] ; then
        if ${createNewInitramfs} ; then
            echo "Generation du nouveau initramfs"
            ${DRACUT_PREFIX}dracut -f
            # Si le script est executé sur le MASTER, on prepare automatiquement pour le SLAVE
            grep "role=master" config 2>&1 > /dev/null
            if [ $? -eq 0 ] ; then
                sed -i s/'role=master'/'role=slave'/ ./config
                echo "================================================================================="
                echo "Preparation pour l'esclave"
                echo "================================================================================="
                InstallDirectory
                echo "Génération de l'intramfs de l'esclave"
                echo "================================================================================="
                ${DRACUT_PREFIX}dracut -f /boot/initramfs-`uname -r`.img.slave `uname -r`
                sed -i s/'role=slave'/'role=master'/ ./config
                echo "================================================================================="
                echo "Remise en place des fichiers d'origine"
                echo "================================================================================="
                InstallDirectory
            fi
        fi
    else
        echo "Initramfs non generé ! Tapez  > dracut -f < pour le generer le moment voulu"
        echo "================================================================================="
    fi
}

#
# Initramfs pour l'installation de drbd
#
# Cet initramfs n'est normalement utile que pour le master
# Au besoin il suffit de copier les lignes 'echo inst ...' 'sed -i ...' et remplacer la ligne 'dracut --install "${commandInstall}"'
# au dessus pour obtenir le necessaire dans l'initramfs normal
#
function InitramfsInstall {
    echo "Generer initramfs pour l'install de drbd (yes/no) ?"
    Answer
    if [ $? -eq 0 ] ; then
        cp tools/shrink.sh ${DRACUT_MODULE_DIR}/90drbd/
        echo 'inst "$moddir/shrink.sh" /sbin/shrink.sh' >> ${DRACUT_MODULE_DIR}/90drbd/install
        sed -i /'\/etc\/init.d\/drbd start'/d ${DRACUT_MODULE_DIR}/90drbd/install
        ${DRACUT_PREFIX}dracut --install "${commandsInstall}" -f /boot/initramfs-`uname -r`.img.install `uname -r`
        echo "================================================================================="
        echo "Ajoutez '.install' au fichier initramfs (.img) dans grub pour obtenir les commandes necessaires dans l'initram"
        echo "================================================================================="
    fi
}
