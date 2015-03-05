

Intro
=====
Attention pour le snmp, le daemon se lance mais il n’a pas été testé

Le script "89cryptssh/peak_console.sh" permet d'afficher la console physique
Le script "tiocsti" permet d'envoyer des commandes sur la console physique (un exemple est present dans exitBreakpoint.sh)

Suivant l'OS sur lequel on est, il faudra adapter le moment ou tuer l'accès SSH
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
généralement le problème.

Architecture
============

/-|---tiocsti.c             (tiocsti not compiled)
  |---tiocsti               (initramfs script /sbin/ ; send cmd to physical prompt ; NOT FOUND BEFORE >MAKE<)
  |---exitbreakpoint.sh     (initramfs script /sbin/ ; exit from mount breakpoint and load OS)
  |---checkApp.sh           (Pre-install => check apps and create RSA key)
  |---install.sh            (Install script ; can edit sshkill on this file ; instmods devName here)
  |---uninstall.sh          (Delete all these modules on DRACUT_MODULE_DIR => config)
  |---Makefile              (Only Makefile)
  |---README.md             (Maybe you already found it ...)
  |---config                (only config ; initram => /etc/config)
  |
  |---88snmp-|---check              (dracut file check)
  .          |---installkernel      (dracut install kernel mods)
  .          |---install            (dracut install)
  .          |---snmp-load.sh       (load snmp daemon)
  |
  |---89cryptssh-|---check              (dracut file check)
  .              |---installkernel      (dracut install kernel mods)
  .              |---install            (dracut install)
  .              |---peak_console.sh    (initramfs script /sbin/ ; dump and get physical prompt)
  .              |---dropbear-load.sh   (hook script run SSH access)
  .              |---killdropbear.sh    (hook script to kill dropbear ; DO NOT EDIT TAKE CARE WITH KERNEL CRASH)
  .              |---bash_profile       (bash profile for root in initramfs)
  .              |---passwd             (only for root)
  .              |---shells             (only shells file)
  .
  |---90drbd-|---check              (dracut file check)
  .          |---installkernel      (dracut install kernel mods)
  .          |---install            (dracut install)
  .          |---enableDrbd.sh      (hook script enable drbd pre-mount)
  .          |---boot.sh            (initramfs script /sbin/ ; drbd primary and mount on sysroot ; and next ; exitBreakpoint.sh )
  |
  |____________________________________________________________________________________________________

Installation
============

Requires : dracut-network gcc dropbear snmpd

make
make install

Utilisation
===========

On edite le fichier de configuration

On ajoute a la ligne de boot de grub :
rdbreak=mount
or
rd.break=mount
Cela varie suivant la version de dracut en fonction.
Pour CentOS 6 utilisez la 1ere ligne, pour CentOS 7 la 2eme.

Pour sortir du break vous pouvez utiliser :
/sbin/boot.sh => permet de passer drbd en primaire puis monte le systeme dans sysroot et sort de l’initramfs
/sbin/exitBreakpoint.sh => sort de l’initramfs, attention vous devez avoir monté votre racine dans /sysroot/ sinon vous ne 
                            pourez pas sortir de l’initramfs
Si vous avez accès a la console physique tapez “exit” cela vous fera passer au prochain breakpoint
Sans console physique vous devez utiliser “tiocsti” pour envoyer des commandes sur la console physique il est donc
indispensable en SSH

Uninstall
=========

make uninstall

Delete module dir  for :
88snmp/
89cryptssh/
90drbd/

Nothing else

References/Credits
==================
This ssh dracut module is inspired by information found at the following URLs:
- http://roosbertl.blogspot.de/2012/12/centos6-disk-encryption-with-remote.html
- https://bitbucket.org/bmearns/dracut-crypt-wait
- https://github.com/rlwolfcastle/dracut-crypt-sshd
- https://github.com/tyll/dracut-cryptssh
- https://bugzilla.redhat.com/show_bug.cgi?id=524727
