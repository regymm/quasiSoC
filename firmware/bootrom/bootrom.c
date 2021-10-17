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
	for(i = 0; i < 64; i++) psram_base[i] = i;
	for(i = 0; i < 30; i++);
	for(i = 0 + 0x4000; i < 64 + 0x4000; i++) psram_base[i] = i;
	for(i = 0; i < 30; i++);
	int j = psram_base[10];
	uart_putstr("[bootrom]c_start\n\r");

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
			}
		}
		uart_putstr("[bootrom]xfer ctrl to 0x20000000\n\r\n\r");
		asm("li t0, 0x20000000; jr t0;" ::: "t0" );
	}
	else {
		uart_putstr("[bootrom]sdcard not found. boot from UART.\r\n");
		// clear 0x20000000 to 0x20001000
		int i;
		for(i = 0; i < 1024; i++) psram_base[i] = 0;
		*(uart_dma_ctrl + 1) = 0x20001000;
		*(uart_dma_ctrl + 2) = 1; // wait here
		uart_putstr("[bootrom]xfer ctrl to 0x20001000\n\r\n\r");
		asm("li t0, 0x20001000; jr t0;" ::: "t0" );
	}
}

