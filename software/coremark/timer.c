/**
 * File              : timer.c
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.06.22
 * Last Modified Date: 2021.06.22
 */
#include "timer.h"
#include "stdint.h"
#include <stdio.h>
#include <stdlib.h>
volatile int* timer_ctrl = (int*) 0x9b000000;
/*volatile int* timel_addr = (int*) 0x9b000000;*/
/*volatile int* timeh_addr = (int*) 0x9b000004;*/
/*volatile int* timecmp_addr = (int*) 0x9b000008;*/
/*volatile int* time_irq_mode_addr = (int*) 0x9b00000c;*/

uint32_t get_timer_ticks()
{
	uint64_t timel = timer_ctrl[0];
	uint64_t timeh = timer_ctrl[1];
	uint64_t result = timel + (timeh << 32);
	/*return result;*/
	return timer_ctrl[0];
}
