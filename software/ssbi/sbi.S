.section .text.boot
.globl sbi_main

sbi_start:
	la a0, 0x92000000
	li a1, 0x8
	sw a1, 24(a0)
	sw a1, 28(a0)
	sw a1, 32(a0)
	sw a1, 36(a0)

	lui sp, %hi(_sp)
	add sp, sp, %lo(_sp)

	lui t0, %hi(isr_vector)
	add t0, t0, %lo(isr_vector)
	csrw mtvec, t0

	lui t0, %hi(_bss_start)
	add t0, t0, %lo(_bss_start)
	lui t1, %hi(_end)
	add t1, t1, %lo(_end)
bss_clear:
	sw x0, (t0)
	add t0, t0, 4
	blt t0, t1, bss_clear

#	la sp, 0x200ffffc
	jal sbi_main

.globl _exit
_exit:
	csrw 0x8b2, x0
	j _exit

# based on ultraembedded/riscv-linux-boot
.globl isr_vector
isr_vector:
    csrrw sp, mscratch, sp
    addi sp, sp, -(35*4)

    # Save registers
    sw x31, (4*34)(sp)
    sw x30, (4*33)(sp)
    sw x29, (4*32)(sp)
    sw x28, (4*31)(sp)
    sw x27, (4*30)(sp)
    sw x26, (4*29)(sp)
    sw x25, (4*28)(sp)
    sw x24, (4*27)(sp)
    sw x23, (4*26)(sp)
    sw x22, (4*25)(sp)
    sw x21, (4*24)(sp)
    sw x20, (4*23)(sp)
    sw x19, (4*22)(sp)
    sw x18, (4*21)(sp)
    sw x17, (4*20)(sp)
    sw x16, (4*19)(sp)
    sw x15, (4*18)(sp)
    sw x14, (4*17)(sp)
    sw x13, (4*16)(sp)
    sw x12, (4*15)(sp)
    sw x11, (4*14)(sp)
    sw x10, (4*13)(sp)
    sw x9,  (4*12)(sp)
    sw x8,  (4*11)(sp)
    sw x7,  (4*10)(sp)
    sw x6,  (4* 9)(sp)
    sw x5,  (4* 8)(sp)
    sw x4,  (4* 7)(sp)
    sw x3,  (4* 6)(sp)
    sw x2,  (4* 5)(sp) # SP
    sw x1,  (4* 4)(sp) # RA

    csrr s0, mcause
    sw s0,  (4* 2)(sp)

    csrr s0, mstatus
    sw s0,  (4* 1)(sp)

    csrr s0, mepc
    sw s0,  (4* 0)(sp)

    # Call ISR handler
    mv a0, sp
    jal exception_handler
    mv sp, a0

    # Restore registers
    lw s0,  (4* 0)(sp)
    csrw mepc, s0

    lw s0,  (4* 1)(sp)
    csrw mstatus, s0

    lw x1,  (4* 4)(sp)
    lw x3,  (4* 6)(sp)
    lw x4,  (4* 7)(sp)
    lw x5,  (4* 8)(sp)
    lw x6,  (4* 9)(sp)
    lw x7,  (4*10)(sp)
    lw x8,  (4*11)(sp)
    lw x9,  (4*12)(sp)
    lw x10, (4*13)(sp)
    lw x11, (4*14)(sp)
    lw x12, (4*15)(sp)
    lw x13, (4*16)(sp)
    lw x14, (4*17)(sp)
    lw x15, (4*18)(sp)
    lw x16, (4*19)(sp)
    lw x17, (4*20)(sp)
    lw x18, (4*21)(sp)
    lw x19, (4*22)(sp)
    lw x20, (4*23)(sp)
    lw x21, (4*24)(sp)
    lw x22, (4*25)(sp)
    lw x23, (4*26)(sp)
    lw x24, (4*27)(sp)
    lw x25, (4*28)(sp)
    lw x26, (4*29)(sp)
    lw x27, (4*30)(sp)
    lw x28, (4*31)(sp)
    lw x29, (4*32)(sp)
    lw x30, (4*33)(sp)
    lw x31, (4*34)(sp)

    addi sp, sp, (35*4)
    csrrw sp, mscratch, sp
    mret

