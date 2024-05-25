/**
 * File              : uartbl.c
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.04.15
 * Last Modified Date: 2023.10.18
 */
#define false 0
#define true 1

/*extern volatile int* BOOT_ENTRY;*/
/*volatile int* BOOT_ENTRY2 = (int*) 0x10001000;*/
volatile int* set_start_addr = (int*) 0x99000004;
volatile int* start_dma = (int*) 0x99000008;

volatile int* uart_tx			= (int*) 0x93000000;
volatile int* uart_tx_done		= (int*) 0x93000008;
volatile int* uart_rx_reset		= (int*) 0x93000004;
volatile int* uart_rx_new		= (int*) 0x93000004;
volatile int* uart_rx_data		= (int*) 0x93000000;

volatile int* cache_enable		= (int*) 0x7fffff00;

volatile int* pspi_base			= (int*) 0x96000000;

void uart_putchar(char c)
{
	while(! *uart_tx_done);
	*uart_tx = c;
	while(! *uart_tx_done);
}
void uart_putstr(const char* str)
{
	int n = 0;
	while(str[n]) uart_putchar(str[n++]);
}
void uart_puthex(unsigned int n)
{
	char* num_str;
	char outbuf[32];
	const char digits[] = "0123456789abcdef";
	num_str = &outbuf[sizeof(outbuf) - 1];
	*num_str = 0;
	do {
		*(--num_str) = digits[(unsigned int)n % 16];
	}
	while ((n /= 16) > 0);
	while (*num_str)
		uart_putchar(*num_str++);
}

// jumped from assembly to here
void fpgaolbl()
{
	*uart_rx_reset = 1;
	uart_putstr("[bootrom]FPGAOL BOOT LOADER \r\n");
	uart_putstr("[bootrom]Try accessing main memory (Artix DDR)... : ");
	volatile int* ddr_addr = (volatile int*)0x20000000;
	uart_puthex(*ddr_addr);
	uart_putstr("\r\nWrite... ");
	*ddr_addr = 0x12345678;
	uart_putstr("Readback... ");
	uart_puthex(*ddr_addr);
	uart_putstr(" Done.\r\n");
	uart_putstr("[bootrom]Try accessing upstream storage (ZYNQ DDR)... : ");
	volatile int* up_stream_addr = (volatile int*)0xe0000000;
	int first = *up_stream_addr;
	uart_puthex(first);
	uart_putstr("\r\nWrite... ");
	*up_stream_addr = 0xdeadbeef;
	uart_putstr("Readback... ");
	uart_puthex(*up_stream_addr);
	*up_stream_addr = first;
	uart_putstr(" Done.\r\n");

	/*uart_putstr("[bootrom]Input number to select boot mode: \r\n");*/
	/*uart_putstr("Upstream storage: 0xe0000000, main memory: 0x20000000, default control transfer address: 0x20001000 \r\n");*/
	/*uart_putstr("0. Copy 256 KB from upstream storage to main memory\r\n");*/
	/*uart_putstr("1. Copy 1 MB from upstream storage to main memory\r\n");*/
	/*uart_putstr("2. Copy 8 MB from upstream storage to main memory (No MMU Linux)\r\n");*/
	/*uart_putstr("3. Directly transfer control to 0xe0000000 \r\n");*/
	/*uart_putstr("4. Directy transfer control to 0xe0001000 \r\n");*/
	/*uart_putstr("5. Copy 256 KB 0xe0001000 to 0x20001000, 256 KB 0xe0100000 to 0x20100000, 32 MB 0xe0400000 to 0x20400000 (MMU Linux)\r\n");*/

	uart_putstr("[bootrom]Load 8MB from upstream storage to main memory... : ");
	int icnt = 8*1024*1024/4;
	for (int i = 0; i < icnt; i++) {
		if ((i & 0xFFFFF) == 0) {
			uart_puthex(i);
			uart_putstr("/");
			uart_puthex(icnt);
			uart_putstr("\r\n");
		}
		ddr_addr[i] = up_stream_addr[i];
	}
	uart_putstr("Loaded. \r\n");

	/*uart_putstr("[kpbl] enable cache (if cache even exists)... \r\n");*/
	/**cache_enable = 1;*/
	/*uart_putstr("[kpbl] cache is up. \r\n");*/

	/*volatile int* psram_test1 = (int*) 0x20039a74;*/
	/*volatile int* psram_test2 = (int*) 0x20210a44;*/
	/*volatile int* psram_test3 = (int*) 0x200034c4;*/
	/*int c;*/
	/*c = *psram_test1;*/
	/*uart_putchar('0' + c%0x10);*/
	/*uart_putchar('0' + (c>>4)%0x10);*/
	/*uart_putchar('\r');*/
	/*uart_putchar('\n');*/
	/*c = *psram_test2;*/
	/*uart_putchar('0' + c%0x10);*/
	/*uart_putchar('0' + (c>>4)%0x10);*/
	/*uart_putchar('\r');*/
	/*uart_putchar('\n');*/
	/*c = *psram_test3;*/
	/*uart_putchar('0' + c%0x10);*/
	/*uart_putchar('0' + (c>>4)%0x10);*/
	/*uart_putchar('\r');*/
	/*uart_putchar('\n');*/
	// return, and asm will do the jump
	uart_putstr("[bootrom]Jump to 0x20001000... \r\n");
}
