/**
 * File              : uartbl.c
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.04.15
 * Last Modified Date: 2023.10.18
 */
#define false 0
#define true 1
#define MMUKERNEL
#define UNTETHERED

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

volatile int* sd_cache_base		= (int*) 0x96000000;
volatile int* sd_address		= (int*) 0x96001000;
volatile int* sd_do_read		= (int*) 0x96001004;
volatile int* sd_do_write		= (int*) 0x96001008;
volatile int* sd_ncd			= (int*) 0x96002000;
volatile int* sd_ready			= (int*) 0x96002010;
volatile int* sd_cache_dirty	= (int*) 0x96002014;

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

void sd_load(volatile int* memaddr, unsigned int offset_sec, unsigned int start_sec, unsigned int end_sec)
{
	unsigned int sector;
	for(sector = start_sec; sector < end_sec; sector++) {
		while(! *sd_ready);
		*sd_address = offset_sec + sector;
		*sd_do_read = 0x1;
		while(! *sd_ready);
		int i = 0;
		for(i = 0; i < 128; i++) {
			memaddr[i + (sector * 128)] = sd_cache_base[i];
		}
	}
}

// jumped from assembly to here
// read hexadecimal from UART and save to BOOT_ENTRY
void sd_uart_bl()
{
	*uart_rx_reset = 1;
	uart_putstr("KERNEL PANIC BOOT LOADER \r\n");
#ifdef MMUKERNEL
#ifndef UNTETHERED
	// somehow this doesn't work...
	uart_putstr("[kpbl] sbi from UART to 0x20001000... \r\n");
	*set_start_addr = 0x20001000;
	*start_dma = 1;

	uart_putstr("[kpbl] Any key... \r\n");
	*uart_rx_reset = 1;
	while(! *uart_rx_new);

	*uart_rx_reset = 1;
	uart_putstr("[kpbl] dtb from UART to 0x20100000... \r\n");
	*set_start_addr = 0x20100000;
	*start_dma = 1;

	uart_putstr("[kpbl] Any key... \r\n");
	*uart_rx_reset = 1;
	while(! *uart_rx_new);

	*uart_rx_reset = 1;
	uart_putstr("[kpbl] kernel from UART to 0x20400000... \r\n");
	*set_start_addr = 0x20400000;
	*start_dma = 1;
#else
	if (! *sd_ncd) {
		uart_putstr("[kpbl] sbi, dtb, kernel from sdcard... \r\n");
		// calc method: offset 4 MB -> sd_address 8192 sectors
		// on-SDcard offset: 16MB aka 32768 sectors
		unsigned int sd_img_sec_offset = 32768;
		// ~~we load 32 MB - 4KB or 65536 - 8 sector~~
		sd_load((volatile int*)0x20001000, sd_img_sec_offset + 8, 0, 16);
		sd_load((volatile int*)0x20100000, sd_img_sec_offset + 2048, 0, 16);
		sd_load((volatile int*)0x20400000, sd_img_sec_offset + 8192, 0, 47000); // kernel ~22MB
		/*sd_load((volatile int*)0x20001000, sd_img_sec_offset + 8, 0, 65536 - 8);*/
	}
#endif
#else
#ifndef UNTETHERED
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
#else
	if (! *sd_ncd) {
		uart_putstr("[kpbl] kernel from sdcard to 0x20001000... \r\n");
		int sector = 0;
		volatile int* addr = (int*) 0x20001000;
		// we load a solid 4 MB or 8192 sector, offset at 4 MB
		for(sector = 0; sector < 8192; sector++) {
			while(! *sd_ready);
			*sd_address = 8192 + sector;
			*sd_do_read = 0x1;
			while(! *sd_ready);
			int i = 0;
			for(i = 0; i < 128; i++) {
				addr[i + (sector * 128)] = sd_cache_base[i];
			}
		}
		uart_putstr("[kpbl] dtb from sdcard to 0x20700000... \r\n");
		addr = (int*) 0x20700000;
		// 1 MB at 8 MB offset this time
		for(sector = 0; sector < 2048; sector++) {
			while(! *sd_ready);
			*sd_address = 16384 + sector;
			*sd_do_read = 0x1;
			while(! *sd_ready);
			int i = 0;
			for(i = 0; i < 128; i++) {
				addr[i + (sector * 128)] = sd_cache_base[i];
			}
		}
	}
#endif
#endif

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
	// return, and asm will do the jump
}
