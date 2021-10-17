.section .text.boot

# C functions
.globl sd_c_start

# ASM functions
.globl isr_asm
.globl csrr_mstatus
.globl csrw_mstatus
.globl csrr_mie
.globl csrw_mie
.globl csrr_mtvec
.globl csrw_mtvec
.globl csrr_mcause
.globl csrw_mcause
.globl csrr_mscratch
.globl csrw_mscratch
.globl csrr_mepc
.globl csrw_mepc

.globl syscall_asm

.globl crit_enter
.globl crit_leave

.globl sd_test_asm

.equ REGS_SAVE_ADDR, 0x10000000

# entry point
sd_start:
	la a0, 0x92000000
	li a1, 0
	sw a1, 24(a0)
	sw a1, 28(a0)
	sw a1, 32(a0)
	sw a1, 36(a0)

	# kernel stack at 1MB
	la sp, 0x200ffffc
	j sd_c_start
	# never here
	j end
end:
	la a0, 0x92000000
	li a1, 1
	#sw a1, 24(a0)
	sw a1, 28(a0)
	#sw a1, 32(a0)
	sw a1, 36(a0)
	j end

