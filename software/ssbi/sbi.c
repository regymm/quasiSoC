/**
 * File              : sbi.c
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2023.07.30
 * Last Modified Date: 2023.07.30
 */
#include "stdint.h"

volatile int* uart_tx			= (int*) 0x93000000;
volatile int* uart_tx_done		= (int*) 0x93000008;
volatile int* uart_rx_reset		= (int*) 0x93000004;
volatile int* uart_rx_new		= (int*) 0x93000004;
volatile int* uart_rx_data		= (int*) 0x93000000;

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
		*(--num_str) = digits[(int)n % 16];
	}
	while ((n /= 16) > 0);
	while (*num_str)
		uart_putchar(*num_str++);
}

extern void _exit(int);

// exception

#define REG_RA                         1
#define REG_SP                         2
#define REG_ARG0                       10
#define REG_RET                        REG_ARG0
#define NUM_GP_REG                     32
#define NUM_CSR_REG                    3

#define CAUSE_MISALIGNED_FETCH         0
#define CAUSE_FAULT_FETCH              1
#define CAUSE_ILLEGAL_INSTRUCTION      2
#define CAUSE_BREAKPOINT               3
#define CAUSE_MISALIGNED_LOAD          4
#define CAUSE_FAULT_LOAD               5
#define CAUSE_MISALIGNED_STORE         6
#define CAUSE_FAULT_STORE              7
#define CAUSE_ECALL_U                  8
#define CAUSE_ECALL_S                  9
#define CAUSE_ECALL_M                  11
#define CAUSE_PAGE_FAULT_INST          12
#define CAUSE_PAGE_FAULT_LOAD          13
#define CAUSE_PAGE_FAULT_STORE         15
#define CAUSE_INTERRUPT                (1 << 31)

#define CAUSE_MAX_EXC      (CAUSE_PAGE_FAULT_STORE + 1)

// CSR

#define SR_SIE          (1 << 1)
#define SR_MIE          (1 << 3)
#define SR_SPIE         (1 << 5)
#define SR_MPIE         (1 << 7)

#define IRQ_S_SOFT       1
#define IRQ_M_SOFT       3
#define IRQ_S_TIMER      5
#define IRQ_M_TIMER      7
#define IRQ_S_EXT        9
#define IRQ_M_EXT        11

#define SR_IP_MSIP      (1 << IRQ_M_SOFT)
#define SR_IP_MTIP      (1 << IRQ_M_TIMER)
#define SR_IP_MEIP      (1 << IRQ_M_EXT)
#define SR_IP_SSIP      (1 << IRQ_S_SOFT)
#define SR_IP_STIP      (1 << IRQ_S_TIMER)
#define SR_IP_SEIP      (1 << IRQ_S_EXT)

#define MSTATUS_SIE  0x00000002
#define MSTATUS_MIE  0x00000008
#define MSTATUS_SPIE 0x00000020
#define MSTATUS_MPIE 0x00000080
#define MSTATUS_SPP  0x00000100
#define MSTATUS_MPP  0x00001800
#define MSTATUS_MPRV 0x00020000
#define MSTATUS_SUM  0x00040000
#define MSTATUS_MXR  0x00080000

#define csr_read(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

#define csr_write(reg, val) ({ \
  asm volatile ("csrw " #reg ", %0" :: "rK"(val)); })

#define csr_set(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })

#define csr_clear(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })

#define csr_swap(reg, val) ({ \
    unsigned long __v = (unsigned long)(val); \
    asm volatile ("csrrw %0, " #reg ", %1" : "=r" (__v) : "rK" (__v) : "memory"); \
    __v; })

// SBI

#define SBI_SET_TIMER 0
#define SBI_CONSOLE_PUTCHAR 1
#define SBI_CONSOLE_GETCHAR 2
#define SBI_CLEAR_IPI 3
#define SBI_SEND_IPI 4
#define SBI_REMOTE_FENCE_I 5
#define SBI_REMOTE_SFENCE_VMA 6
#define SBI_REMOTE_SFENCE_VMA_ASID 7
#define SBI_SHUTDOWN 8

#define SBI_ECALL(__num, __a0, __a1, __a2)                                    \
	({                                                                    \
		register unsigned long a0 asm("a0") = (unsigned long)(__a0);  \
		register unsigned long a1 asm("a1") = (unsigned long)(__a1);  \
		register unsigned long a2 asm("a2") = (unsigned long)(__a2);  \
		register unsigned long a7 asm("a7") = (unsigned long)(__num); \
		asm volatile("ecall"                                          \
			     : "+r"(a0)                                       \
			     : "r"(a1), "r"(a2), "r"(a7)                      \
			     : "memory");                                     \
		a0;                                                           \
	})

#define SBI_ECALL_0(__num) SBI_ECALL(__num, 0, 0, 0)
#define SBI_ECALL_1(__num, __a0) SBI_ECALL(__num, __a0, 0, 0)
#define SBI_ECALL_2(__num, __a0, __a1) SBI_ECALL(__num, __a0, __a1, 0)

#define sbi_putchar(c) SBI_ECALL_1(SBI_CONSOLE_PUTCHAR, (c))
#define sbi_shutdown() SBI_ECALL_0(SBI_SHUTDOWN)

/*struct irq_context* exception_handler(struct irq_context* ctx);*/

struct irq_context
{
    uint32_t pc;
    uint32_t status;
    uint32_t cause;
    uint32_t reg[NUM_GP_REG];
};

typedef struct irq_context* (*fp_exception) (struct irq_context* ctx);
typedef struct irq_context* (*fp_irq) (struct irq_context* ctx);
typedef struct irq_context* (*fp_syscall) (struct irq_context* ctx);

static fp_exception _exception_table[CAUSE_MAX_EXC];
static fp_irq _irq_handler = 0;

void exception_set_irq_handler(fp_irq handler)
{
	_irq_handler = handler;
}
// unused, just use exception_set_handler instead
/*void exception_set_syscall_handler(fp_syscall handler)*/
/*{*/
	/*_exception_table[CAUSE_ECALL_U] = handler;*/
	/*_exception_table[CAUSE_ECALL_S] = handler;*/
	/*_exception_table[CAUSE_ECALL_M] = handler;*/
/*}*/
void exception_set_handler(int cause, fp_exception handler)
{
	_exception_table[cause] = handler;
}

struct irq_context* exception_handler(struct irq_context* ctx)
{
	/*uart_putstr("[SBI] ISR\r\n");*/
	// External interrupt
	if (ctx->cause & CAUSE_INTERRUPT) {
		if (_irq_handler) ctx = _irq_handler(ctx);
		else {
			uart_putstr("[SBI] Unhandled IRQ: ");
			uart_puthex(ctx->cause);
			uart_putstr("\n\r");
		} 
	}
	// Exception
	else {
		/*uart_putstr("[SBI] Exception ");*/
		/*uart_puthex(ctx->cause);*/
		/*uart_putstr(" at pc: ");*/
		/*uart_puthex(ctx->pc);*/
		/*uart_putstr("\r\n");*/
		switch (ctx->cause) {
			case CAUSE_ECALL_U:
			case CAUSE_ECALL_S:
			case CAUSE_ECALL_M:
				ctx->pc += 4;
				// due to some hack, the pc~mepc won't be restored. 
				csr_write(mepc, csr_read(mepc)+4);
				break;
		}

		if (ctx->cause < CAUSE_MAX_EXC && _exception_table[ctx->cause])
			ctx = _exception_table[ctx->cause](ctx);
		else {
			switch (ctx->cause) {
				case CAUSE_PAGE_FAULT_INST:
				case CAUSE_PAGE_FAULT_STORE:
				case CAUSE_PAGE_FAULT_LOAD:
					;
					/*uart_putstr("[SBI] Halted on page fault\r\n");*/
					/*unsigned int* memstart = (void*) 0x210000ee;*/
					/*unsigned int memcount = 0x100;*/
					/*for (unsigned int i = 0; i < memcount; i++) {*/
						/*uart_puthex((unsigned int)memstart + i);*/
						/*uart_putstr(": ");*/
						/*uart_puthex(*(memstart + i));*/
						/*uart_putstr("\r\n");*/
					/*}*/
					/*while(1);*/
					/*uart_putstr("[SBI] Forwarded instruction page fault to S-mode.\r\n");*/
					unsigned long mepc_val = csr_read(mepc);
					unsigned long stvec_val = csr_read(stvec);
					unsigned long mstatus_val = csr_read(mstatus);
					unsigned long mcause_val = ctx->cause;
					unsigned long mstatus_mpp = mstatus_val & MSTATUS_MPP;
					unsigned long mstatus_sie = mstatus_val & MSTATUS_SIE;

					// SPP <= S/U
					mstatus_val &= ~MSTATUS_SPP | (mstatus_mpp & 0x800 ? MSTATUS_SPP : 0);
					// SIE <= 0
					mstatus_val &= ~MSTATUS_SIE;
					// SPIE <= SIE
					mstatus_val &= ~MSTATUS_SPIE | (mstatus_sie ? MSTATUS_SPIE : 0);
					// sepc <= mepc
					csr_write(sepc, mepc_val);
					// mepc <= stvec
					csr_write(mepc, stvec_val);
					// scause <= mcause
					csr_write(scause, mcause_val);
					csr_write(mstatus, mstatus_val);
					break;
				default:
					uart_putstr("[SBI] ERROR: Unhandled exception ");
					uart_puthex(ctx->cause);
					uart_putstr(" at PC: ");
					uart_puthex(ctx->pc);
					uart_putstr("\r\n");
					break;
			}

		}
		/*if (ctx->cause == CAUSE_PAGE_FAULT_INST){*/
		/*}*/
		/*else {*/
			/*[>_exit(-1);<]*/
		/*}*/
	}
	/*uart_putstr("EXCEPTION RET\r\n");*/
	return ctx;
}

struct irq_context* sbi_syscall(struct irq_context* ctx)
{
	uint32_t a0    = ctx->reg[REG_ARG0 + 0];
	uint32_t a1    = ctx->reg[REG_ARG0 + 1];
	uint32_t a2    = ctx->reg[REG_ARG0 + 2];
	uint32_t which = ctx->reg[REG_ARG0 + 7];

	switch (which) {
		case SBI_SHUTDOWN:
			uart_putstr("[SBI] Shutdown. \r\n");
			_exit(0);
			break;
		case SBI_CONSOLE_PUTCHAR:
			/*uart_putchar('(');*/
			/*uart_puthex(a0);*/
			/*uart_putstr(")");*/
			uart_putchar(a0);
			break;
		case SBI_CONSOLE_GETCHAR:
			ctx->reg[REG_ARG0] = -1;
			break;
		case SBI_SET_TIMER:
			/*set_mtimecmp(a0);*/
			/*csr_set(mie, SR_IP_MTIP);*/
			/*csr_clear(sip, SR_IP_STIP);*/
			break;
		case SBI_REMOTE_FENCE_I:
		case SBI_REMOTE_SFENCE_VMA:
			break;
		default:
			uart_putstr("[SBI] Unhandled syscall: ");
			uart_puthex(which);
			uart_putstr("\r\n");
			_exit(-1);
			break;
	}
	return ctx;
}

struct irq_context* irq_callback (struct irq_context* ctx)
{
	uint32_t cause = ctx->cause & 0xF;

	if (cause == IRQ_M_TIMER) {
		// pass to supervisor
	}
	else {
		// we don't have any other IRQs in the whole system
		// this should never happen
		uart_putstr("[SBI] Unhandled IRQ: ");
		uart_puthex(cause);
		uart_putstr("\r\n");
		_exit(-1);
	}
	return ctx;
}

#define MSTATUS_MPP_SHIFT   11
#define PRV_S 1
#define PRV_M 3

extern uint32_t _sp;

void sbi_main()
{
	uart_putstr("[SBI] Simple SBI for QuasiSoC\r\n");

	volatile void* kernel_entry_addr = (void*) 0x20400000;
	volatile void* kernel_dtb_addr = (void*) 0x20100000;
	/*int* mem_test_addr = (void*) 0x21888208;*/
	/**mem_test_addr = 0x12345678;*/
	/*uart_putstr("MEM:");*/
	/*uart_puthex(*mem_test_addr);*/

	exception_set_handler(CAUSE_ECALL_S, sbi_syscall);
	exception_set_irq_handler(irq_callback);
	csr_write(mie, 1 << IRQ_M_TIMER);
	csr_write(mstatus, (PRV_S << MSTATUS_MPP_SHIFT) | SR_MPIE);
	csr_write(mepc, kernel_entry_addr);
	csr_write(mscratch, &_sp);

	register uintptr_t a0 asm ("a0") = 0;
	register uintptr_t a1 asm ("a1") = kernel_dtb_addr;
	asm volatile ("mret" :: "r" (a0), "r" (a1));

	while (1);
}
