#include <stdio.h>
#include <stdlib.h>
#include "coremark.h"
#include "timer.h"

// aclint timer 10MHz
#define CPU_FREQ_HZ 10000000

#if VALIDATION_RUN
	volatile ee_s32 seed1_volatile=0x3415;
	volatile ee_s32 seed2_volatile=0x3415;
	volatile ee_s32 seed3_volatile=0x66;
#endif

#if PERFORMANCE_RUN
	volatile ee_s32 seed1_volatile=0x0;
	volatile ee_s32 seed2_volatile=0x0;
	volatile ee_s32 seed3_volatile=0x66;
#endif

#if PROFILE_RUN
	volatile ee_s32 seed1_volatile=0x8;
	volatile ee_s32 seed2_volatile=0x8;
	volatile ee_s32 seed3_volatile=0x8;
#endif

volatile ee_s32 seed4_volatile=ITERATIONS;
volatile ee_s32 seed5_volatile=0;

static CORE_TICKS t0, t1;

void start_time(void)
{
	t0 = get_timer_ticks();
	printf("t0: %u\r\n", t0);
  /*t0 = get_cycle_value();*/
}

void stop_time(void)
{
	t1 = get_timer_ticks();
	printf("t1: %u\r\n", t1);
  /*t1 = get_cycle_value();*/
}

CORE_TICKS get_time(void)
{
  return t1 - t0;
}

secs_ret time_in_secs(CORE_TICKS ticks)
{
  // scale timer down to avoid uint64_t -> double conversion in RV32
  int scale = 256;
  uint32_t delta = ticks / scale;
  uint32_t freq = CPU_FREQ_HZ / scale;
  return delta / (double)freq;
}

void portable_init(core_portable *p, int *argc, char *argv[])
{
	printf("portable init\r\n");
	/*volatile int* c_en = (int*)0x7fffff00;*/
	/**c_en = 1;*/
	/*printf("cache up\r\n");*/
}
