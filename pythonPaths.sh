#!/bin/bash

. config

echo $modToInstall | grep 91python 2>&1 > /dev/null
if [ $? -eq 1 ] ; then 
    touch .pythonFiles
    exit 0
fi

# Limite de sous-dossiers
limitRecurs=10

# La liste des prochains dossiers a analyser
nextContent=''

# Liste des fichiers a copier ; ajout des données au fur et a mesure de l'analyse des dossiers
filesToCopy=''

# Liste des dossiers a créer ; ajout des données au fur et a mesure de l'analyse des dossiers
dirToCreate=''

# On réécris les variables pour etre sur d'avoir les / a la fin
PYTHON_PATHS2=''
for i in $PYTHON_PATHS ; do
    PYTHON_PATHS2="$PYTHON_PATHS2 $i/"
done
PYTHON_PATHS=$PYTHON_PATHS2
unset PYTHON_PATHS2


# FOnction scannant les dossiers/fichiers présents dans PYTHON_PATHS
function installRecurs () {
    # La liste des dossiers a analyser lors de la prochaine boucle
    local funContent=""
    # Si le script vient d'etre lancé, on utilise la variable PYTHON_PATHS comme liste de dossiers
    if [ $1 -eq 1 ] ; then
        for i in $PYTHON_PATHS ; do
            # La liste des fichiers/dossiers dans le repertoire analysé
            local content=`ls -1 ${i}`
            for j in $content ; do
                # Si c'est un fichier on l'ajoute a la liste des fichiers a créer
                if [ -f $i$j ] ; then 
                    filesToCopy="$filesToCopy $i$j"
                # Si c'est un dossier on l'ajoute a la liste des dossiers a analyser par la suite
                elif [ -d $i$j ] ; then
                    local funContent="$funContent $i$j/"
#                    echo "$i$j est un dossier"
                fi
            done
        done
        # On copie la liste des dossiers a analyser dans la variable adéquate
        nextContent="$funContent"
    # Dès que la boucle est executée une fois on travaille sans la variable PYTHON_PATHS car
    # on cherche a savoir ce qu'il y a dans les sous-dossiers de la variable
    # On utilise donc le retour du if dans $nextContent
    else
        # On verifie qu'il y a des chemins a analyser
        if [ -z "$nextContent" ] ; then
            echo "Plus de sous-dossiers a analyser"
            break
        else
    #        echo $nextContent
            for i in $nextContent ; do
                local content=`ls -1 ${i}`
                for j in $content ; do
                    if [ -f $i$j ] ; then 
                        filesToCopy="$filesToCopy $i$j"
                    elif [ -d $i$j ] ; then
                        local funContent="$funContent $i$j/"
    #                    echo "$i$j est un dossier"
                    fi
                done
            done
            nextContent=''
            nextContent="$funContent"
        fi
    fi
    dirToCreate="$dirToCreate $funContent"

}

# On execute la recherche tant que la limite de recursion n'est pas atteinte
for i in $(seq 1 ${limitRecurs}); do
    installRecurs $i
done

echo "inst_dir /usr/include/" >> .pythonFiles

for i in $PYTHON_PATHS ; do
    echo "inst_dir $i" >> .pythonFiles
done

for i in $dirToCreate ; do
    echo "inst_dir $i" >> .pythonFiles
done

for i in $filesToCopy ; do
    echo "inst_simple $i $i" >> .pythonFiles
done


