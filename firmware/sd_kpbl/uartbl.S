.section .text.boot

# C functions
.globl sd_uart_bl
.globl BOOT_ENTRY

.equ BOOT_ENTRY, 0x20001000

# entry point, at 0x20000000
sd_start:
	# turn off all the LEDs
	la a0, 0x92000000
	li a1, 1
	sw a1, 24(a0)
	sw a1, 28(a0)
	sw a1, 32(a0)
	sw a1, 36(a0)

	# setup stack
	la sp, 0x20000ffc
	# read code from UART to memory
	jal sd_uart_bl

	# prepare kernel a0 and a1
	li a0, 0
	la a1, 0x20700000

	# jump to the code. uartbl finished. 
	la t0, BOOT_ENTRY
	jr t0

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
