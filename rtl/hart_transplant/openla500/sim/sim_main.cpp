#include "Vquasi_main_sim.h"
#include "verilated_vcd_c.h"
#include "verilated.h"
#include "fcntl.h"
#include "termios.h"
#include "unistd.h"
#include <iostream>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <SDL2/SDL.h>

int main (int argc, char* argv[])
{
	Verilated::commandArgs(argc, argv);
	Vquasi_main_sim *top = new Vquasi_main_sim;
	
	// Check if --trace flag is present
	bool enable_trace = false;
	for (int arg_i = 1; arg_i < argc; arg_i++) {
		if (strcmp(argv[arg_i], "--trace") == 0) {
			enable_trace = true;
			break;
		}
	}
	
	// Setup VCD tracing if enabled
	VerilatedVcdC *tfp = nullptr;
	if (enable_trace) {
		Verilated::traceEverOn(true);
		tfp = new VerilatedVcdC;
		top->trace(tfp, 99);
		tfp->open("sim.vcd");
	}

	int timeout = 3600;
	if (argc >= 2) {
		for (int arg_i = 1; arg_i < argc; arg_i++) {
			if (strcmp(argv[arg_i], "--trace") != 0) {
				timeout = atoi(argv[arg_i]);
				break;
			}
		}
	}

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
		if (tfp) {
			tfp->dump(Verilated::time());
			Verilated::timeInc(2.5);
		}
		top->sysclk = 1;
		top->eval();
		if (tfp) {
			tfp->dump(Verilated::time());
			Verilated::timeInc(2.5);
		}
		time_t now = time(0);
		unsigned long now_sec = (unsigned long) now;
		if (now_sec - start_sec > timeout)
			break;
	}
	if (tfp) {
		tfp->close();
		delete tfp;
	}
	delete top;
	return 0;
}
