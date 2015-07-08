

Intro
=====
Attention pour le snmp, le daemon se lance mais il n’a pas été testé

Le script "89cryptssh/peak_console.sh" permet d'afficher la console physique
Le script "tiocsti" permet d'envoyer des commandes sur la console physique (un exemple est present dans exitBreakpoint.sh)

Suivant l'OS sur lequel on est, il faudra adapter le moment ou tuer l'accès SSH (kernel panic possible)
Le tuer trop tot peut engendrer un souci lors de la sortie des breakpoints
Un accès a la console physique est préférable pour l'experimentation
Sur certains OS l'accès est tué lors du boot du système, on peut alors supprimer le script (a ajouter dans install.sh)

Suivant l'OS on doit ajouter un temps entre chaque "exit" pour changer de breakpoint, on adapte alors exitBreakPoint.sh

Les cles d'authentification recuperées sont :
/root/.ssh/authorized_keys      (Edit in 89cryptssh/install)

Tous les modules chargent le reseau si necessaire

Pour drbd, vous devez etre capable de l’installer et le faire fonctionner sans intiramfs sur une partition data
Ce module permet de repliquer la partition systeme via drbd toute la replication se fera en initramfs en secondaire
puis on le passe en primaire et on demarre le système au besoin
Certains problèmes peuvent arriver lors du demarrage car ce ne sera pas les fichiers avec les bons ID matériels (udev)
Il faudra alors probablement supprimer ces fichiers dans /sysroot en initramfs une fois la partition montée, cela resout 
généralement le problème (la modificatio est a effectuer dans 90drbd/boot.sh).


Installation
============
Master :

Requires : dracut-network gcc dropbear snmpd sshpass

Eviter d'utiliser python pour le moment son installation est degeulasse

Edit config File

make
make install

Dans /boot/grub/menu.lst on ajoute rdbreak=mount
On redemarre
On ajoute .install au fichier initramfam.img (3eme ligne)
On execute /sbin/shrink.sh
On execute boot.sh pour demarrer le serveur

Esclave :
On boot sur l'iso contenant le necessaire (principalement sshpass et rsync)
On recupere tools/slavePrepare.sh
On reboot


Utilisation
===========

On ajoute a la ligne de boot de grub :
rdbreak=mount
or
rd.break=mount
Cela varie suivant la version de dracut en fonction.
Pour CentOS 6 utilisez la 1ere ligne, pour CentOS 7 la 2eme.

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

References/Credits
==================
This ssh dracut module is inspired by information found at the following URLs:
- http://roosbertl.blogspot.de/2012/12/centos6-disk-encryption-with-remote.html
- https://bitbucket.org/bmearns/dracut-crypt-wait
- https://github.com/rlwolfcastle/dracut-crypt-sshd
- https://github.com/tyll/dracut-cryptssh
- https://bugzilla.redhat.com/show_bug.cgi?id=524727
