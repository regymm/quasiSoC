#include "Vquasi_main.h"
#include "verilated.h"
#include "fcntl.h"
#include "termios.h"
#include "unistd.h"
#include <iostream>
#include <cstdio>
#include <ctime>
#include <SDL2/SDL.h>

int main (int argc, char* argv[])
{
	Verilated::commandArgs(argc, argv);
	Vquasi_main *top = new Vquasi_main;

	int timeout = 3600;
	if (argc == 2)
		timeout = atoi(argv[1]);

	int i = 0;
	int j = 0;
	top->sw = 1;

	char buf;
	fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
	struct termios raw;
	tcgetattr(STDIN_FILENO, &raw);
	raw.c_lflag &= ~(ECHO | ICANON);
	tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);

	time_t start = time(0);
	unsigned long start_sec = (unsigned long) start;
	while(1) {
		if (top->uart_rxsim_en == 1) top->uart_rxsim_en = 0;
		if (j == 20) {
			j = 0;
			int input = read(0, &buf, 1);
			if (input > 0) {
				//printf("You said: %c\n", buf);
				top->uart_rxsim_en = 1;
				top->uart_rxsim_data = buf;
			}
		}
		else j++;

		if (i < 100) {
			i++;
		}
		if (i == 100) {
			top->sw = 0;
		}
		top->sysclk = 0;
		top->eval();
		top->sysclk = 1;
		top->eval();
		time_t now = time(0);
		unsigned long now_sec = (unsigned long) now;
		if (now_sec - start_sec > timeout)
			break;
	}
	top->final();
	delete top;
	return 0;
}
