/**
 * File              : uartbl.c
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.04.15
 * Last Modified Date: 2021.04.15
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

// jumped from assembly to here
// read hexadecimal from UART and save to BOOT_ENTRY
void sd_uart_bl()
{
	*uart_rx_reset = 1;
	uart_putstr("KERNEL PANIC BOOT LOADER \r\n");

	uart_putstr("[kpbl] kernel from UART to 0x20001000... \r\n");
	*set_start_addr = 0x20001000;
	*start_dma = 1;

	uart_putstr("[kpbl] Any key... \r\n");
	*uart_rx_reset = 1;
	while(! *uart_rx_new);

	*uart_rx_reset = 1;
	uart_putstr("[kpbl] dtb from UART to 0x20700000... \r\n");
	*set_start_addr = 0x20700000;
	*start_dma = 1;

	uart_putstr("[kpbl] enable cache... \r\n");
	*cache_enable = 1;
	uart_putstr("[kpbl] cache is up. \r\n");

	volatile int* psram_test1 = (int*) 0x20039a74;
	volatile int* psram_test2 = (int*) 0x20210a44;
	volatile int* psram_test3 = (int*) 0x200034c4;
	int c;
	c = *psram_test1;
	uart_putchar('0' + c%0x10);
	uart_putchar('0' + (c>>4)%0x10);
	uart_putchar('\r');
	uart_putchar('\n');
	c = *psram_test2;
	uart_putchar('0' + c%0x10);
	uart_putchar('0' + (c>>4)%0x10);
	uart_putchar('\r');
	uart_putchar('\n');
	c = *psram_test3;
	uart_putchar('0' + c%0x10);
	uart_putchar('0' + (c>>4)%0x10);
	uart_putchar('\r');
	uart_putchar('\n');




	/*int i = -1;*/
	/*int k = 0;*/
	/*char c;*/
	/*int inst[8];*/
	/*unsigned int inst_bin;*/

	/*while (1) {*/
		/*c = uart_getchar();*/
		/*[>uart_putchar(c);<]*/
		/*if (c >= '0' && c <= '9') inst[k] = (c - '0');*/
		/*else if (c >= 'a' && c <= 'f') inst[k] = (c - 'a' + 0xa);*/
		/*else if (c >= 'A' && c <= 'F') inst[k] = (c - 'A' + 0xa);*/
		/*else if (c == '\r' || c == '\n' || c == ' ') k--; // skip end of line*/
		/*else {*/
			/*uart_putstr("[uartbl]illegal input or end\r\n"); // illegal aka stop*/
			/*uart_putchar((c >> 4)+ 48);*/
			/*uart_putchar((c - ((c >> 4) << 4)) + 48);*/
			/*uart_putstr("\r\n");*/
			/*uart_putchar(i / 10000+ 48);*/
			/*uart_putchar((i % 10000) / 1000 + 48);*/
			/*uart_putchar((i % 1000) / 100 + 48);*/
			/*uart_putchar((i % 100) / 10 + 48);*/
			/*uart_putchar((i % 10) / 1 + 48);*/
			/*break;*/
		/*}*/

		/*switch(k) {*/
			/*case 0: */
				/*inst_bin = inst[k] << 4;*/
				/*break;*/
			/*case 1:*/
				/*inst_bin += inst[k];*/
				/*break;*/
			/*case 2:*/
				/*inst_bin += inst[k] << 12;*/
				/*break;*/
			/*case 3:*/
				/*inst_bin += inst[k] << 8;*/
				/*break;*/
			/*case 4:*/
				/*inst_bin += inst[k] << 20;*/
				/*break;*/
			/*case 5:*/
				/*inst_bin += inst[k] << 16;*/
				/*break;*/
			/*case 6:*/
				/*inst_bin += inst[k] << 28;*/
				/*i++;*/
				/*break;*/
			/*case 7:*/
				/*[>inst_bin += inst[k] << 24;<]*/
				/*BOOT_ENTRY2[i] = inst_bin + (inst[k] << 24);*/
				/*k = -1;*/
				/*break;*/
			/*default:*/
				/*break;*/
		/*}*/
		/*k++;*/


	/*}*/

	/*uart_putstr("[uartbl] reading finished. jump ... \r\n");*/

	// return, and asm will do the jump
}
