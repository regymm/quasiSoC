.section .text
.globl _start
.globl c_start

_start:
	la a0, foo
	lr.w a4, (a0)
	addi a0, a0, 0
	sc.w a4, a4, (a0)
#	j _start
# AXI4 DDR2
#	la a0, 0x20000084
#	li a1, 0x12345678
#	sw a1, 0(a0)
#	lw t0, 0(a0)
#	sw zero, 0(a0)

# AXI GPIO tests
#	la a0, 0x92000000
#	li a1, 0xffffffff
#	sw a1, 0(a0)
#	lw t0, 0(a0)
#	sw zero, 0(a0)


##	la a0, 0x97000000
##	li a1, 1
##	sw a1, 0(a0)
##	la a0, 0x93000000
##	sw a1, 0(a0)
#
##	la a0, 0x20000aa8
##	li a1, 0x12345678
##	sw a1, (a0)
##	lw t0, (a0)
##	j _start
#	j interrupt_tests
#interrupt_tests: 
	la a0, 0x92000000
	li a1, 0xffffffff
	sw a1, 24(a0)
	sw a1, 28(a0)
# some timer test
	la a0, 0x9b000000
	lw a1, 0(a0)
	lw a2, 0(a0)
	lw a1, 0(a0)
	lw a2, 0(a0)
##	# timer only
##	la a0, 0x98000000
##	li a1, 0x6 # 0b110
##	sw a1, 0(a0)
##	# setup mtvec
##	la t0, interrupt_handler
##	csrw mtvec, t0
##	# setup mstatus
##	li t0, 0x00000088
##	csrw mstatus, t0
##	li t0, 0x00000888
##	csrw mie, t0
	j main_tests
main_tests:
	li t0, 0x00
	;csrc mstatus, t0
	# amo
	li t0, 0x12
	la t1, 0x10000000
	li t2, 0x34
	li t3, 0xabcd
	li t4, 0x98
	sw t4, (t1)
	lr.w t4, (t1)
	addi t4, t4, 1
	sc.w t4, t4, (t1)
	amoadd.w t3, t2, (t1)
	#sc.w t3, t1, (t2)
	li t4, 0xffffffff
	lw t4, (t1)

##	j main_tests
#	li t0, 0
#	li t1, 127
#	bge t1, t0, _start
#	li t0, 0x20000000
#	jr t0
#	# arithmetic tests

	li t0, 0x0000ff00
	slli t0, t0, 0x10
	srai t0, t0, 0x10
	li t1, 0xffffff00
	bne t1, t0, fail

	li t0, 20
	li t1, 6
	div t2, t0, t1
	li a0, 3
	bne t2, a0, fail
	li t0, -20
	li t1, 6
	div t2, t0, t1
	li a0, -3
	bne t2, a0, fail
	li t0, 20
	li t1, -6
	div t2, t0, t1
	li a0, -3
	bne t2, a0, fail
	li t0, -20
	li t1, -6
	div t2, t0, t1
	li a0, 3
	bne t2, a0, fail

	li t0, -1<<31
	li t1, 2
	div t2, t0, t1

	li t0, -1<<31
	li t1, 1
	div t2, t0, t1
	li a0, -1<<31
	bne t2, a0, fail

##m_ok:
##	j m_ok
##
#
#
	li t2, 23
	addi t3, zero, 4
	addi t2, t2, 5
	add t4, t2, t3
	sub t5, t2, t3
	beq t5, t2, fail
	ori t6, zero, 1
	bne t6, t5, cont1
	j fail
cont1:
	li a0, 1
	li a1, 2
	xor a3, a0, a1
	li a4, 3
	bne a3, a4, fail

	li a0, 0xf
	li a1, 0xfe
	and a3, a0, a1
	li a4, 0xe
	bne a3, a4, fail

	li a0, 2
	li a1, 3
	slt a3, a0, a1
	li a4, 1
	bne a3, a4, fail

	li a0, -2
	li a1, 2
	slt a3, a0, a1
	li a4, 1
	bne a3, a4, fail
	sltu a3, a0, a1
	beq a3, a4, fail

	li a0, 0xf0000000
	li a1, 3
	sll a3, a0, a1
	li a4, 0x80000000
	bne a3, a4, fail

	li a0, 0xf0000000
	li a1, 4
	srl a3, a0, a1
	li a4, 0x0f000000
	bne a3, a4, fail
	sra a3, a0, a1
	li a4, 0xff000000
	bne a3, a4, fail

	# jump test
	jal func_dummy

	# load store tests
	#fence
	li a1, 0xabcdf2f4
	la a0, 0x10000000
	sw zero, 0(a0)
	sw zero, 4(a0)
	sw zero, 8(a0)
	sw a1, 0(a0)
	sh a1, 4(a0)
	sb a1, 8(a0)
	lw a3, 0(a0)
	li a4, 0xabcdf2f4
	bne a3, a4, fail
	lw a3, 4(a0)
	li a4, 0x0000f2f4
	bne a3, a4, fail
	lw a3, 8(a0)
	li a4, 0x000000f4
	bne a3, a4, fail

	#fence
	lhu a3, 2(a0)
	li a4, 0x0000abcd
	bne a3, a4, fail
	lbu a3, 1(a0)
	li a4, 0x000000f2
	bne a3, a4, fail
	lbu a3, 2(a0)
	li a4, 0x000000cd
	bne a3, a4, fail
	lbu a3, 3(a0)
	li a4, 0x000000ab
	bne a3, a4, fail

	#fence
	li a3, 0xdc
	sb a3, 1(a0)
	lbu a3, 1(a0)
	li a4, 0xdc
	bne a3, a4, fail

	#fence
	lhu a3, 0(a0)
	li a4, 0x0000dcf4
	bne a3, a4, fail
	lbu a3, 0(a0)
	li a4, 0x000000f4
	bne a3, a4, fail
	lh a3, 0(a0)
	li a4, 0xffffdcf4
	bne a3, a4, fail
	lb a3, 0(a0)
	li a4, 0xfffffff4
	beq a3, a4, cont2
	j fail
cont2:
	# RV32M tests
	li a0, 0xabcd1234
	li a1, 0x7777ffff
	mul a3, a0, a1
	mulh a4, a0, a1
	mulhsu a5, a0, a1
	mulhu a6, a0, a1
	li s3, 0x0892edcc
	li s4, 0xd8b4db97
	li s5, 0xd8b4db97
	li s6, 0x502cdb96
	bne a3, s3, fail
	bne a4, s4, fail
	bne a5, s5, fail
	bne a6, s6, fail

	li a0, 0xcbcd1234
	li a1, 0x1777ffff
	div a3, a0, a1
	divu a4, a0, a1
	rem a5, a0, a1
	remu a6, a0, a1
	li s3, 0xfffffffe
	li s4, 0x00000008
	li s5, 0xfabd1232
	li s6, 0x100d123c
	bne a3, s3, fail
	bne a4, s4, fail
	bne a5, s5, fail
	bne a6, s6, fail
#
##	la a0, 0x92000000
##	li a1, 0
##	sw a1, 24(a0)
#
	la a0, 0x20000aa8
	li a1, 0x12345678
	sw a1, 0(a0)
	li a1, 0x44448888
	sw a1, 4(a0)
	lw a2, 0(a0)
	lw a3, 4(a0)
	lw a4, 8(a0)
	lw a5, 12(a0)
#

#	li a0, 'O'
#	jal uart_putchar_simple
#	li a0, 'K'
#	jal uart_putchar_simple
#	li a0, '\n'
#	jal uart_putchar_simple
#	li a0, '\r'
#	jal uart_putchar_simple
	j end
end:
	nop
	nop
	nop
	nop
	# TODO: better temporary stack ?
	la sp, 0x200ffffc
	# For sake of kernel, prepare registers
	li a0, 0
	la a1, 0x20700000
	j c_start
	j real_end
	nop
	nop
	nop
	nop
	li a0, '\n'
	jal uart_putchar_simple
	li a0, 'E'
	jal uart_putchar_simple
	li a0, 'X'
	jal uart_putchar_simple
	li a0, 'I'
	jal uart_putchar_simple
	li a0, 'T'
	jal uart_putchar_simple
real_end:
	j real_end
fail:
	j fail

interrupt_handler:
	nop
	nop
	nop
	nop
	nop
	mret

func_dummy:
	nop
	nop
	ret
	nop
	j fail


# void uart_putchar(char c)
uart_putchar_simple:
    #lw t2, uart_addr
	la t2, 0x93000000
1:
    lw t0, 8(t2)
    beq t0, zero, 1b
    sw a0, 0(t2) # do the real work
2:
    lw t0, 8(t2)
    beq t0, zero, 2b
	ret

.section .data
    uart_addr: .word 0x93000000
foo: .word 0
