/**
 * File              : sdboot.c
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 202x.xx.xx
 * Last Modified Date: 2021.10.17
 */
#include "stdio.h"

volatile int* uart_tx			= (int*) 0x93000000;
volatile int* uart_tx_done		= (int*) 0x93000008;
volatile int* uart_rx_reset		= (int*) 0x93000004;
volatile int* uart_rx_new		= (int*) 0x93000004;
volatile int* uart_rx_data		= (int*) 0x93000000;

volatile int* video_base		= (int*) 0x94000000;
int video_x;
int video_y;

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

void hardware_init()
{
	uart_putstr("Hardware init...\r\n");
	*uart_rx_reset = 1;
	video_x = 0;
	video_y = 0;
}

#include "pingo/sftrdr_main.h"
void software_renderer()
{
	volatile int* video_light_mode;
	/*video_light_mode = (void *)0x94040000;*/
	/**video_light_mode = 0xffffffff;*/
	video_light_mode = (void *)0x94020000;
	*video_light_mode = 0xffffffff;
	sftrdr_main();
}

void hdmi_test()
{
	int i = 0;
	int k = 0x0100;
	int j;
	for(j = 0; j < 19200; j++) video_base[j] = 0x0;
	video_base[19218] = 0x03e01c1f;
	video_base[0] = 0x03e01c1f;
	video_base[10000] = 0x03e01c1f;
	int base_color_arr[] = {0x00, 0x03, 0xe0, 0x1c, 0x1f, 0xe3, 0xfc, 0xff};
	/*printf("%u\r\n", timer_ctrl[0]);*/
	/*while(1)*/
	for(i = 0; i < 240; i++) {
		for(j = 0; j < 80; j++) {
			int base_color_idx = i / (240/8);
			int clr = (j < 40 ? base_color_arr[base_color_idx] : i*2+j*4);
			/*int clr = (j < 40 ? base_color_arr[base_color_idx] : i%2 ? 0xff : 0xff);*/
			clr = clr % 0x100;
			video_base[i*80+j] = clr + (clr<<8) + (clr<<16) + (clr<<24);
			/*video_base[i*80+j] = clr + (0) + (clr<<16) + (0);*/
		}
	}
	for(i = 0; i < 240; i++) {
		for(j = 0; j < 80; j++) {
			int clr = (i+j)%2 ? 0x1c : 0xe3;
		}
	}
	/*printf("%u\r\n", timer_ctrl[0]);*/
	/*while(1);*/
}

void memory_test_halt()
{
	uart_putstr("Memory test failed!!\r\n");
	while(1);
}
void memory_test()
{
	/*int c = uart_getchar();*/
	int mem_start = 0x20100000;
	int i;
	for(i = 0; i < 0x4000; i+=4) {
		int* addr_to_test = (int *)(mem_start + i);
		*addr_to_test = i;
	}
	for(i = 0; i < 0x4000; i+=4) {
		int* addr_to_test = (int *)(mem_start + i);
		int readback = *addr_to_test;
		if (readback != i) {
			void (*dumm)(void) = 0x99990000;
			dumm();
			memory_test();
		}
	}
	uart_putstr("Memory test passed\r\n");
}

// jumped from assembly to here
void sd_c_start()
{
	uart_putstr("[sdcard]sd_c_start\r\n");
	memory_test();
	hardware_init();
	hdmi_test();
	software_renderer();

	int i;
	while(1){
		for(i = 1; i < 100000; i++);
		uart_putchar('.');
	}
}
