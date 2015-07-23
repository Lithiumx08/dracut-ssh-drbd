

Intro
=====
Attention pour le snmp, le daemon se lance mais il n’a pas été testé

Le script "89dropbear/peak_console.sh" permet d'afficher la console physique
Le script "tiocsti" permet d'envoyer des commandes sur la console physique (un exemple est present dans exitBreakpoint.sh)

Suivant l'OS sur lequel on est, il faudra adapter le moment ou tuer l'accès SSH (kernel panic possible)
Le tuer trop tot peut engendrer un souci lors de la sortie des breakpoints
Un accès a la console physique est préférable pour l'experimentation
Sur certains OS l'accès est tué lors du boot du système, on peut alors supprimer le script (a ajouter dans install.sh)

Suivant l'OS on doit ajouter un temps entre chaque "exit" pour changer de breakpoint, on adapte alors exitBreakPoint.sh

Les cles d'authentification recuperées sont :
/root/.ssh/authorized_keys      (Edit in 89dropbear/install)

Tous les modules chargent le reseau si necessaire

Pour drbd, vous devez etre capable de l’installer et le faire fonctionner sans intiramfs sur une partition data
Ce module permet de repliquer la partition systeme via drbd toute la replication se fera en initramfs en secondaire
puis on le passe en primaire et on demarre le système au besoin
Certains problèmes peuvent arriver lors du demarrage car ce ne sera pas les fichiers avec les bons ID matériels (udev)
Il faudra alors probablement supprimer ces fichiers dans /sysroot en initramfs une fois la partition montée, cela resout 
généralement le problème (la modification est a effectuer dans 90drbd/boot.sh).


Installation
============
Master :

Requires : dracut-network gcc dropbear snmpd sshpass

Edit config File

make
make install

On redemarre
On ajoute .install au fichier initramfam.img (3eme ligne)
On execute /sbin/shrink.sh
On execute /sbin/boot.sh pour demarrer le serveur

Esclave :
On boot sur l'iso contenant le necessaire (principalement sshpass et rsync)
On recupere tools/slavePrepare.sh sur le master, et on l'execute
On reboot


Utilisation
===========

Pour sortir du break vous pouvez utiliser :
/sbin/boot.sh => permet de passer drbd en primaire puis monte le systeme dans sysroot et sort de l’initramfs
/sbin/boot.sh --help pour plus d'infos sur les possibilités du script
/sbin/exitBreakpoint.sh => sort de l’initramfs, attention vous devez avoir monté votre racine dans /sysroot/ sinon vous ne 
                            pourez pas sortir de l’initramfs
Si vous avez accès a la console physique tapez “exit” cela vous fera passer au prochain breakpoint
Sans console physique vous devez utiliser “tiocsti” pour envoyer des commandes sur la console physique il est donc
indispensable en SSH

Uninstall
=========

make uninstall

Nothing else

Common Problem
==============

La configuration fait des siennes apres reinstallation :
Verifier s'il ne reste pas un dossier de module qui serait inutile pour dracut

Fonctionnement interne a dracut
===============================

On break en mount :
Sur ce breakpoint, l'important est de monter la racine dans /sysroot
Si necessaire, il faut modifier /sysroot/dev/root s'il ne s'agit pas de la racine utilisée habituellement
Il faut aussi editer le fstab au cas où (/sysroot/etc/fstab) meme si je ne suis pas sur que ce soit indispensable
La partition /home n'est pas montée à ce moment
Si le /boot est monté, on obtient un crash kernel
Une fois le necessaire effectué, on peut quitter les breakpoints, il faut donc taper 2 fois "exit" sur la console physique

!!! A noter qu'on peut tout faire depuis ce breakpoint, car on dispose de la commande "mount" et "chroot"
!!! L'utilisation du reseau necessite cependant le package dracut-network sur centos 6


References/Credits
==================
This ssh dracut module is inspired by information found at the following URLs:
- http://roosbertl.blogspot.de/2012/12/centos6-disk-encryption-with-remote.html
- https://bitbucket.org/bmearns/dracut-crypt-wait
- https://github.com/rlwolfcastle/dracut-crypt-sshd
- https://github.com/tyll/dracut-cryptssh
- https://bugzilla.redhat.com/show_bug.cgi?id=524727
