#include "basic.h"

void c_start()
{
	uart_putstr("[bootrom_sim]c_start\n\r");
	uart_putstr("[bootrom_sim]xfer ctrl to 0x20001000\n\r\n\r");
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
	asm("li a0, 0;" ::: "a0" );
	asm("la a1, 0x20700000;" ::: "a1" );
	asm("la t0, 0x20001000; jr t0;" ::: "t0" );
}

