

Intro
=====

Le script "89cryptssh/peak_console.sh" permet d'afficher la console physique
Le script "tiocsti" permet d'envoyer des commandes sur la console physique (un exemple est present dans exitBreakpoint.sh)

Suivant l'OS sur lequel on est, il faudra adapter le moment ou tuer l'accès SSH
Sur certains OS l'accès est tué lors du boot du système, on peut alors supprimer le script (a ajouter dans install.sh)

Suivant l'OS on doit ajouter un temps entre chaque "exit" pour changer de breakpoint, on adapte alors exitBreakPoint.sh

Les cles d'authentification recuperées sont :
/root/.ssh/authorized_keys      (Edit in 89cryptssh/install)

Architecture
============

/-|---tiocsti.c             (tiocsti not compiled)
  |---tiocsti               (initramfs script /sbin/ ; send cmd to physical prompt ; NOT FOUND BEFORE >MAKE<)
  |---exitbreakpoint.sh     (initramfs script /sbin/ ; exit from mount breakpoint and load OS)
  |---checkApp.sh           (Pre-install => check apps and create RSA key)
  |---install.sh            (Install script ; can edit sshkill on this file ; instmods devName here)
  |---uninstall.sh          (Delete all these modules on DRACUT_MODULE_DIR => config)
  |---Makefile              (Only Makefile)
  |---README.txt            (Maybe you already found it ...)
  |---config                (only config ; initram => /etc/config)
  |
  |---89cryptssh-|---check              (dracut file check)
  .              |---installkernel      (dracut install kernel mods)
  .              |---install            (dracut install)
  .              |---peak_console.sh    (initramfs script /sbin/ ; dump and get physical prompt)
  .              |---dropbear-load.sh   (hook script run SSH access)
  .              |---killdropbear.sh    (hook script to kill dropbear ; DO NOT EDIT, check /install.sh for changes)
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

Requires : dracut-network gcc dropbear


Add to boot cmdline :
rdbreak=mount
or
rd.break=mount


Edit config file


make
make install

Uninstall
=========

make uninstall

Delete module dir  for :
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
