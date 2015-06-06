#!/bin/bash

function installDirectory {
    # Suppression des dossiers precedemment créés
    for i in ${modToInstall} ; do
        rm -rf ${DESTDIR}${DRACUT_MODULE_DIR}/$i
    done
    
    # On créé le dossier de modules d'il n'existe pas
    mkdir -p ${DESTDIR}${DRACUT_MODULE_DIR}/
    
    # On installe les nouveaux modules
    for i in ${modToInstall} ; do
        cp -a $i ${DESTDIR}${DRACUT_MODULE_DIR}
        cp -p ./config ${DESTDIR}${DRACUT_MODULE_DIR}/$i
        cp -p ./exitBreakpoint.sh ${DESTDIR}${DRACUT_MODULE_DIR}/$i
        cp -p ./tiocsti ${DESTDIR}${DRACUT_MODULE_DIR}/$i
        echo "dracut_install ${commandsToAdd}" >> ${DESTDIR}${DRACUT_MODULE_DIR}/$i/install
        echo "$i installé"
        echo "instmods ${devName}" >> ${DESTDIR}${DRACUT_MODULE_DIR}/$i/installkernel

    # Specifications d'installation suivant les modules
        case $i in
            89cryptssh)
                #
                # Gestion de l'arret de l'accès SSH suivant la version de CentOS
                # Sur CentOS 7 l'arret se fait automatiquement, on n'execute donc pas le script
                #
                if [[ $i == "89cryptssh" ]] ; then
                    if cat /etc/centos-release | grep -o "7.0" > /dev/null ; then
                        echo "Centos 7.0 detecté"
                        sed -i /'kill-dropbear.sh'/d ${DRACUT_MODULE_DIR}/$i/install
                    elif cat /etc/centos-release | grep -o "6.6" > /dev/null ; then
                        echo "Centos 6.6 detecté"
                    else
                        echo "Version de CentOS inconnue"
                        echo "Verifiez comment doit s'arreter l'accès SSH sur cet OS"
                        echo "Veillez a avoir accès a la console physique en cas de probleme lors du boot de l'OS"
                    fi
                fi
                #
                # On ne copie pas le hash du password root si la connexion par
                # mot de passe n'est pas autorisée
                #
                if ! ${allowPassword} ; then
                    sed -i /'\/etc\/shadow'/d ${DRACUT_MODULE_DIR}/89cryptssh/install
                fi

                ;;
            91python)
                . ./tools/installPython.sh
                ;;
        esac

    done
}
