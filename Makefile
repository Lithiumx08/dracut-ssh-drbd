# Verification de l'existence des applications necessaires ainsi que certains fichiers necessitant
# l'utilisation des applications en question
.cmd_ok:
	./checkApp.sh

build: .cmd_ok tiocsti

# Fichier necessaire pour envoyer des commandes sur la console reelle du serveur et non sur le TTY ouvert en SSH
tiocsti: tiocsti.c
	gcc -std=gnu99 -O2 -Wall -o tiocsti tiocsti.c

# Installation
install: build
	./install.sh

# Nettoyage des donnees créées lors de l'execution de make
clean:
	rm tiocsti .cmd_ok

# Desinstallation des modules
uninstall:
	./uninstall.sh
