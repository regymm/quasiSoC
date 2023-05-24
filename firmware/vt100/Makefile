TOOLCHAIN_PREFIX=riscv32-unknown-elf-

all: vt100.dat

vt100.elf: vt100.S vt100.c link.ld
	$(TOOLCHAIN_PREFIX)gcc -nostartfiles -nostdlib -march=rv32i -mabi=ilp32 -Tlink.ld -ovt100.elf vt100.S vt100.c -lgcc -Os
%.bin: %.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
%.dat: %.bin
	xxd -c 4 -p $< > $@
	#python3 makehex.py $< 1024 > $@ # use 512 for mininum

clean:
	rm -f *.elf *.bin *.hex *.dat
