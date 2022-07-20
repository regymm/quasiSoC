RISCV_ARCH := rv32im
RISCV_ABI := ilp32
RISCV_MCMODEL := medlow
C_SRCS := \
	core_list_join.c \
	core_main.c \
	core_matrix.c \
	core_state.c \
	core_util.c \
	core_portme.c
CFLAGS := -O2 -fno-common -funroll-loops -finline-functions --param max-inline-insns-auto=20 -falign-functions=4 -falign-jumps=4 -falign-loops=4

all:
	riscv32-unknown-elf-gcc $(CFLAGS) -march=rv32i -mabi=ilp32 -mcmodel=medlow -nostdlib sdboot.S newlib/crt0.S newlib/syscall.c mmio_basic.c timer.c $(C_SRCS) -o coremark.elf -T linker.ld -lc -lgcc
	riscv32-unknown-elf-objcopy -O binary coremark.elf coremark.bin

clean:
	-rm coremark.bin coremark.elf

