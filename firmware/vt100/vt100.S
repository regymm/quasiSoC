.globl _start
.globl cpld_write_cmd
.globl cpld_is_ready
.globl rx_has_new
.globl rx_val
.globl rx_next
.globl led
.globl c_start


_start:
#	li s0, 0
#	li s1, 0
#	li s2, 0
#	li s3, 0
#	li s4, 0
#	li s5, 0
#	li s6, 0
#	li s7, 0
#	li s8, 0
#	li s9, 0
#	li s10, 0
#	li s11, 0
#	li x11, 0
#	li x12, 0
#	li x13, 0
#	li x14, 0
#	li x15, 0
#	li x16, 0
#	li x17, 0
#	li x18, 0
#	li x19, 0
#	li x20, 0
#	li x21, 0
#	li x22, 0
#	li x23, 0
#	li x24, 0
#	li x25, 0
#	li x26, 0
#	li x27, 0
#	li x28, 0
#	li x29, 0
#	li x30, 0
#	li x31, 0
	li sp, 0x4FEC # stack
	j c_start

cpld_write_cmd:
	ret
	li t0, 0xf000
	slli a0, a0, 8
	andi a1, a1, 0xFF
	add a0, a0, a1
	sw a0, (t0)
	sw a0, (t0)
#	sw a0, (t0)
#	sw a0, (t0)
	ret
# including old rx_to_queue, rx_has_new
#cpld_wait_safe:
#	addi sp, sp, -16
#	sw ra, 12(sp)
#	jal rx_to_queue
#	ret
cpld_is_ready:
#	li t0, 0xf000
#	lw a0, (t0)
	ret
rx_has_new:
	li t0, 0x8000
	lw a0, (t0)
	srli a0, a0, 8
	ret
rx_val:
	li t0, 0x8000
	lw a0, (t0)
	andi a0, a0, 0xFF
	ret
rx_next:
	li t0, 0x8000
	sw zero, (t0)
	ret
#led:
#	li t0, 0xe000
#	sw a0, (t0)
#	ret
