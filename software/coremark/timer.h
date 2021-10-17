/**
 * File              : timer.h
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.06.22
 * Last Modified Date: 2021.06.22
 */
#ifndef TIMER_H
#define TIMER_H
extern volatile int* timer_ctrl;
#include "stdint.h"
uint32_t get_timer_ticks();
#endif
