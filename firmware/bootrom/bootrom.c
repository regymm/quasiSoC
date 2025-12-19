#include "basic.h"
#define N 100

void c_start()
{
	/*while(!*w5500_ready);*/
	/**w5500_setaddr = 0xabcd;*/
	/**w5500_setctrl = 0x48;*/
	/**w5500_setdata = 0x12345678;*/
	/**w5500_setxfrlen = 2;*/
	/**w5500_issue = 1;*/

	/*int (*a)[N] = 0x2020f580, (*b)[N] = 0x2041eb00, (*c)[N] = 0x25b8d800;  */
	/*int i, j, k;  */
	/*for (i = 0; i < N; i++) {  */
		/*for (j = 0; j < N; j++) {  */
			/*a[i][j] = i+j;  */
			/*b[i][j] = i+j;  */
		/*}  */
	/*}  */
	/*for (i = 0; i < N; i++) {  */
		/*for (k = 0; k < N; k++) {  */
			/*for (j = 0; j < N; j++) {  */
				/*c[i][j] += a[i][k] * b[k][j];  */
			/*}  */
  
		/*}  */
	/*}  */

	int i;
	/*for(i = 0; i < 64; i++) psram_base[i] = i;*/
	/*for(i = 0; i < 30; i++);*/
	/*for(i = 0 + 0x4000; i < 64 + 0x4000; i++) psram_base[i] = i;*/
	/*for(i = 0; i < 30; i++);*/
	int j;
	/*j = psram_base[10];*/
	uart_putchar('a');
	uart_putchar('b');
	uart_putchar('c');
	uart_putchar('d');
	uart_putstr("e");
	uart_putstr("1234567890");
	uart_putstr("[bootrom]c_start\n\r");
	/*while(1);*/

	volatile int* distram_base = (int*) 0x10000000;
	volatile int* bootrom_base = (int*) 0xf0000000;
	/*uart_putstr("[bootrom]bootrom\n\r");*/
	/*for(i = 0; i < 64; i++) {*/
		/*int x = bootrom_base[i];*/
		/*int j;*/
		/*char c[8];*/
		/*for(j = 0; j < 8; j++) {*/
			/*c[j] = (x >> (4*j)) & 0xF;*/
		/*}*/
		/*for(j = 7; j >=0; j--) {*/
			/*if (c[j] < 10) uart_putchar(c[j] + '0');*/
			/*if (c[j] >= 10) uart_putchar(c[j] - 10 + 'A');*/
		/*}*/
		/*uart_putchar('\n');*/
		/*uart_putchar('\r');*/
	/*}*/
	/*uart_putchar(uart_getchar());*/
	/*uart_putchar(uart_getchar());*/
	for (i = 0; i < 512; i++) {
		distram_base[i] = bootrom_base[i];
		psram_base[i] = bootrom_base[i];
	}
	/*uart_putstr("[bootrom]distram\n\r");*/
	/*for(i = 0; i < 64; i++) {*/
		/*int x = distram_base[i];*/
		/*int j;*/
		/*char c[8];*/
		/*for(j = 0; j < 8; j++) {*/
			/*c[j] = (x >> (4*j)) & 0xF;*/
		/*}*/
		/*for(j = 7; j >=0; j--) {*/
			/*if (c[j] < 10) uart_putchar(c[j] + '0');*/
			/*if (c[j] >= 10) uart_putchar(c[j] - 10 + 'A');*/
		/*}*/
		/*uart_putchar('\n');*/
		/*uart_putchar('\r');*/
	/*}*/
	uart_putstr("[bootrom]mainmem accessed\n\r");
	for(i = 0; i < 64; i++) {
		int x = psram_base[i];
		int j;
		char c[8];
		for(j = 0; j < 8; j++) {
			c[j] = (x >> (4*j)) & 0xF;
		}
		for(j = 7; j >=0; j--) {
			if (c[j] < 10) uart_putchar(c[j] + '0');
			if (c[j] >= 10) uart_putchar(c[j] - 10 + 'A');
		}
		uart_putchar('\n');
		uart_putchar('\r');
	}

	if (! *sd_ncd) {
		uart_putstr("[bootrom]load from sdcard\n\r");
		int sector = 0;
		for(sector = 0; sector < 500; sector++) {
			while(! *sd_ready);
			*sd_address = sector;
			*sd_do_read = 0x1;
			while(! *sd_ready);
			int i = 0;
			/*int data;*/
			for(i = 0; i < 128; i++) {
				psram_base[i + (sector * 128)] = sd_cache_base[i];
				/*data = psram_base[i];*/
				/*int x = sd_cache_base[i];*/
				/*int j;*/
				/*char c[8];*/
				/*for(j = 0; j < 8; j++) {*/
					/*c[j] = (x >> (4*j)) & 0xF;*/
				/*}*/
				/*for(j = 7; j >=0; j--) {*/
					/*if (c[j] < 10) uart_putchar(c[j] + '0');*/
					/*if (c[j] >= 10) uart_putchar(c[j] - 10 + 'A');*/
				/*}*/
				/*uart_putchar('\n');*/
				/*uart_putchar('\r');*/
			}
			/*uart_putchar('\n');*/
			/*uart_putchar('\r');*/
		}
		uart_putstr("[bootrom]xfer ctrl to 0x20000000\n\r\n\r");
		asm("li t0, 0x20000000; jr t0;" ::: "t0" );
	}
	else {
		uart_putstr("[bootrom]sdcard not found. boot from UART.\r\n");
		// clear 0x20000000 to 0x20001000
		int i;
		/*for(i = 0; i < 10; i++) {*/
			/*char c = uart_getchar();*/
			/*uart_putchar((c >> 8) + '0');*/
			/*uart_putchar((c & 0xF) + '0');*/
			/*uart_putchar(c);*/
		/*}*/
		for(i = 0; i < 1024; i++) psram_base[i] = 0;
		*(uart_dma_ctrl + 1) = 0x20001000;
		*(uart_dma_ctrl + 2) = 1; // wait here
		for(i = 0; i < 16; i++) {
			int x = psram_base[1024 + i];
			int j;
			char c[8];
			for(j = 0; j < 8; j++) {
				c[j] = (x >> (4*j)) & 0xF;
			}
			for(j = 7; j >=0; j--) {
				if (c[j] < 10) uart_putchar(c[j] + '0');
				if (c[j] >= 10) uart_putchar(c[j] - 10 + 'A');
			}
			uart_putchar('\n');
			uart_putchar('\r');
		}
		uart_putstr("[bootrom]xfer ctrl to 0x20001000\n\r\n\r");
		asm("li t0, 0x20001000; jr t0;" ::: "t0" );
	}
}

