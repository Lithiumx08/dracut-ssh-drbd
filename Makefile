# Verification de l'existence des applications necessaires ainsi que certains fichiers necessitant
# l'utilisation des applications en question
.cmd_ok:
	./checkApp.sh

.pythonFiles:
	./pythonPaths.sh

build: .cmd_ok tiocsti .pythonFiles

# Fichier necessaire pour envoyer des commandes sur la console reelle du serveur et non sur le TTY ouvert en SSH
tiocsti: tiocsti.c
	gcc -std=gnu99 -O2 -Wall -o tiocsti tiocsti.c

# Installation
install: build
	./install.sh

# Nettoyage des donnees créées lors de l'execution de make
clean:
	rm tiocsti .cmd_ok .pythonFiles

# Desinstallation des modules
uninstall:
	./tools/uninstall.sh

# Mise a jour du DRBD, et des modules deja insallés
# La mise a jour s'effectue grace au fichier /etc/dracut-celeo/config
#upgrade: build
#	./tools/upgrade.sh
