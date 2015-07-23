// gcc -std=gnu99 -O2 -Wall tiocsti.c -o tiocsti

// Le détail du fonctionnement de ce fichier vous sera expliqué quand je l'aurais moi meme compris ...

#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <stdio.h>
#include <termios.h>
#include <unistd.h>

void stuff(int fd, const char * str) {
	printf("stuff [%s]\n", str);
	for (; *str; ++str) {
		printf("(%c)", *str);
		int rv = ioctl(fd, TIOCSTI, str);
		if (rv < 0) perror("ioctl(TIOCSTI)");
	}
}

int main (int argc, const char * argv[]) {
	if (argc < 3) {
		printf("Usage: tiocsti /dev/ttyX text string\n");
		return 1;
	}

	int fd = open(argv[1], O_RDONLY);
	if (fd < 0) {
		perror("open");
		return 2;
	}

	for (int i = 2; i < argc; ++i) {
		if (i != 2) stuff(fd, " ");
		stuff(fd, argv[i]);
	}

	close(fd);
	return 0;
}

