#include "mmio_basic.h"
volatile int* uart_tx			= (int*) 0x93000000;
volatile int* uart_tx_done		= (int*) 0x93000008;
volatile int* uart_rx_reset		= (int*) 0x93000004;
volatile int* uart_rx_new		= (int*) 0x93000004;
volatile int* uart_rx_data		= (int*) 0x93000000;

volatile int* psram_base		= (int*) 0x20000000;

volatile int* distram_base		= (int*) 0x10000000;

volatile int* video_base		= (int*) 0x94000000;

volatile int* sd_cache_base		= (int*) 0x96000000;
volatile int* sd_address		= (int*) 0x96001000;
volatile int* sd_do_read		= (int*) 0x96001004;
volatile int* sd_do_write		= (int*) 0x96001008;
volatile int* sd_ncd			= (int*) 0x96002000;
volatile int* sd_ready			= (int*) 0x96002010;
volatile int* sd_cache_dirty	= (int*) 0x96002014;

volatile int* gpio_ctrl			= (int*) 0x92000000;

volatile int* interrupt_ctrl	= (int*) 0x98000000;

volatile int* uart_dma_ctrl		= (int*) 0x99000000;

int video_x = 0;
int video_y = 0;

char uart_getchar()
{
	/**uart_rx_reset = 1;*/
	while(! *uart_rx_new);
	char c = *uart_rx_data;
	*uart_rx_reset = 1;
	return c;
	/*return *uart_rx_data;*/
}
void uart_putchar(char c)
{
	if (c == '\n') uart_putchar('\r');
	while(! *uart_tx_done);
	*uart_tx = c;
	while(! *uart_tx_done);
}
void hdmi_putchar(char c)
{
	if (c == '\r') video_x = 0;
	else if (c == '\n') {
		if (video_y == 29) video_y = 0;
		else video_y++;
	}
	else {
		video_base[video_y * 80 + video_x] = c + 0x0100;
		if (video_x == 79)  {
			video_x = 0;
			if (video_y == 29) video_y = 0;
			else video_y++;
		}
		else video_x++;
	}
}

void uart_putstr(const char* str)
{
	int n = 0;
	while(str[n]) uart_putchar(str[n++]);
}

