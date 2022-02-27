// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
.section .text
.globl _start
.globl uart_putchar

_start:
	#li a0, 0x92000000
	#li a1, 0x0
	#sw a1, 24(a0)
	#sw a1, 28(a0)
	#li a0, 'X'
	#la t2, 0x93000000
1:
    #lw t0, 8(t2)
    #beq t0, zero, 1b
    #sw a0, 0(t2) # do the real work
2:
    #lw t0, 8(t2)
    #beq t0, zero, 2b

	#li a0, 'O'
	#jal uart_putchar
	#li a0, 'K'
	#jal uart_putchar
	/* zero-initialize all registers */

	addi x1, zero, 0
	addi x2, zero, 0
	addi x3, zero, 0
	addi x4, zero, 0
	addi x5, zero, 0
	addi x6, zero, 0
	addi x7, zero, 0
	addi x8, zero, 0
	addi x9, zero, 0
	addi x10, zero, 0
	addi x11, zero, 0
	addi x12, zero, 0
	addi x13, zero, 0
	addi x14, zero, 0
	addi x15, zero, 0
	addi x16, zero, 0
	addi x17, zero, 0
	addi x18, zero, 0
	addi x19, zero, 0
	addi x20, zero, 0
	addi x21, zero, 0
	addi x22, zero, 0
	addi x23, zero, 0
	addi x24, zero, 0
	addi x25, zero, 0
	addi x26, zero, 0
	addi x27, zero, 0
	addi x28, zero, 0
	addi x29, zero, 0
	addi x30, zero, 0
	addi x31, zero, 0
#	j _start

#  define TEST(n) \
	.global n; \
	addi x1, zero, 1000; \
	jal zero,n; \
	.global n ## _ret; \
	n ## _ret:

	#picorv32_timer_insn(zero, x1); \

	TEST(lui)
	TEST(auipc)
	TEST(j)
	TEST(jal)
	TEST(jalr)

	TEST(beq)
	TEST(bne)
	TEST(blt)
	TEST(bge)
	TEST(bltu)
	TEST(bgeu)

	TEST(lb)
	TEST(lh)
	TEST(lw)
	TEST(lbu)
	TEST(lhu)

	TEST(sb)
	TEST(sh)
	TEST(sw)

	TEST(addi)
	TEST(slti) // also tests sltiu
	TEST(xori)
	TEST(ori)
	TEST(andi)
	TEST(slli)
	TEST(srli)
	TEST(srai)

	TEST(add)
	TEST(sub)
	TEST(sll)
	TEST(slt) // what is with sltu ?
	TEST(sltiu)
	TEST(xor)
	TEST(srl)
	TEST(sra)
	TEST(or)
	TEST(and)

	TEST(mulh)
	TEST(mulhsu)
	TEST(mulhu)
	TEST(mul)

	TEST(div)
	TEST(divu)
	TEST(rem)
	TEST(remu)

	TEST(csr)
	TEST(mcsr)
	TEST(amoadd_w)
	TEST(amoand_w)
	TEST(amoor_w)
	TEST(amoswap_w)
	TEST(amoxor_w)
	TEST(amomaxu_w)
	TEST(amomax_w)
	TEST(amominu_w)
	TEST(amomin_w)
	TEST(lrsc)
	# TEST(scall)

	TEST(simple)
_theend:
	j _start

# void uart_putchar(char c)
uart_putchar:
	la t2, 0x93000000
1:
    lw t0, 8(t2)
    beq t0, zero, 1b
    sw a0, 0(t2) # do the real work
2:
    lw t0, 8(t2)
    beq t0, zero, 2b
	ret
