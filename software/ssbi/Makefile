all:
	riscv32-unknown-elf-gcc $(CFLAGS) -march=rv32ima -mabi=ilp32 -mstrict-align -O0 -static -nostdlib sbi.S sbi.c -o sbi.elf -T linker.ld -lc -lgcc
	riscv32-unknown-elf-objcopy -O binary sbi.elf sbi.bin

clean:
	-rm sbi.elf sbi.bin
