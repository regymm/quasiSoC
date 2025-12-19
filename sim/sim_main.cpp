#include "Vquasi_main.h"
#include "verilated_vcd_c.h"
#include "verilated.h"
#include "fcntl.h"
#include "termios.h"
#include "unistd.h"
#include <iostream>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <csignal>
#include <SDL2/SDL.h>

#define SDCARD_SIM

#ifdef SDCARD_SIM
#include "sdspisim.h"
#endif
// Global pointers for signal handler cleanup
static VerilatedVcdC *g_tfp = nullptr;
static Vquasi_main *g_top = nullptr;
static struct termios g_orig_termios;

void cleanup_and_exit(int signum) {
	fprintf(stderr, "\nCaught signal %d, cleaning up...\n", signum);
	
	// Close VCD trace file
	if (g_tfp) {
        g_tfp->dump(Verilated::time());
		g_tfp->close();
		fprintf(stderr, "VCD trace file closed.\n");
	}
	
	// Restore terminal settings
	tcsetattr(STDIN_FILENO, TCSAFLUSH, &g_orig_termios);
	
	exit(signum == SIGINT ? 0 : 1);
}

int main (int argc, char* argv[])
{
	Verilated::commandArgs(argc, argv);
	Vquasi_main *top = new Vquasi_main;
	g_top = top;
	
	// Save original terminal settings for restoration
	tcgetattr(STDIN_FILENO, &g_orig_termios);
	
	// Install signal handlers for cleanup
	signal(SIGABRT, cleanup_and_exit);  // Catch assert() failures
	signal(SIGINT, cleanup_and_exit);   // Catch Ctrl+C
	signal(SIGSEGV, cleanup_and_exit);  // Catch segfaults
	
	// Initialize the SD card simulation model
	SDSPISIM *sdcard = new SDSPISIM(true);  // Set to true for debug output
	
	// Check if --trace flag is present
	bool enable_trace = false;
	const char *sdcard_image = "sdcard.img";
	for (int arg_i = 1; arg_i < argc; arg_i++) {
		if (strcmp(argv[arg_i], "--trace") == 0) {
			enable_trace = true;
		} else if (strncmp(argv[arg_i], "--sdcard=", 9) == 0) {
			sdcard_image = argv[arg_i] + 9;
		}
	}
	
	// Load SD card image
	sdcard->load(sdcard_image);
	printf("Loaded SD card image: %s\n", sdcard_image);
	
	// Setup VCD tracing if enabled
	VerilatedVcdC *tfp = nullptr;
	if (enable_trace) {
		Verilated::traceEverOn(true);
		tfp = new VerilatedVcdC;
		g_tfp = tfp;  // Set global pointer for signal handler
		top->trace(tfp, 99);
		tfp->open("verilator.vcd");
	}

	int timeout = 3600;
	if (argc >= 2) {
		for (int arg_i = 1; arg_i < argc; arg_i++) {
			if (strcmp(argv[arg_i], "--trace") != 0 &&
			    strncmp(argv[arg_i], "--sdcard=", 9) != 0) {
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
        // miso: from host to card
		top->sd_dat0 = (*sdcard)(
			top->sd_dat3,  // csn: Chip select
			top->sd_sck,   // sck: SPI clock
			top->sd_cmd    // mosi: Data from FPGA to SD card
		);
		
		top->sysclk = 0;
		top->eval();
		// if (tfp) {
		// 	tfp->dump(Verilated::time());
		// 	Verilated::timeInc(5);
		// }
		top->sysclk = 1;
		top->eval();
		if (tfp) {
			tfp->dump(Verilated::time());
			Verilated::timeInc(10);
		}
		time_t now = time(0);
		unsigned long now_sec = (unsigned long) now;
		if (now_sec - start_sec > timeout)
			break;
	}
	top->final();
	// Normal cleanup
	if (tfp) {
		tfp->close();
		g_tfp = nullptr;
		delete tfp;
	}
	
	// Restore terminal settings
	tcsetattr(STDIN_FILENO, TCSAFLUSH, &g_orig_termios);
	
	delete sdcard;
	delete top;
	return 0;
}
