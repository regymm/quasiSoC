#RISCV	=	/opt/riscv32ima/bin/riscv32-unknown-linux-gnu-
RISCVDIR=	/opt/riscv32i
RISCV	=	riscv32-unknown-elf-
AS		=	$(RISCV)as
ASFLAGS	=	-march=rv32ima -mabi=ilp32
LD 		=	$(RISCV)ld
#LDFLAGS	=	-m elf32lriscv --nostdlib
LDFLAGS	=	-m elf32lriscv
CC		=	$(RISCV)gcc
CPP		=	$(RISCV)g++
CC_L_F	=	-march=rv32i -mabi=ilp32 -nostdlib -mstrict-align -O0 -static
CFLAGS	=	-march=rv32ima -mabi=ilp32 -mstrict-align -O0 -static
CPPFLAGS=	$(CFLAGS) -nostdlib
OBJCOPY	=	$(RISCV)objcopy
READELF	=	$(RISCV)readelf

all: sd_uartbl/uartbl.bin bootrom/bootrom.dat sd_kpbl/kpbl.bin

bootrom/bootrom.dat: bootrom/bootrom.bin
	xxd -c 4 -p bootrom/bootrom.bin > bootrom/result_bootrom.dat

%.bin: %.elf
	$(OBJCOPY) -O binary $*.elf $*.bin
	python3 ../software/binpatch.py $*.bin $*.elf

%.o: %.S
	$(AS) $(ASFLAGS) $*.S -o $*.o

%.c_o: %.c
	$(CC) -c $(CFLAGS) $*.c -o $*.c_o

bootrom/bootrom.elf: bootrom/bootrom.o bootrom/bootrom.c_o bootrom/basic.c_o
	$(LD) $(LDFLAGS) $^ -o $@ --script bootrom/linker_bootrom.ld

sd_uartbl/uartbl.elf: sd_uartbl/uartbl.o sd_uartbl/uartbl.c_o
	$(LD) $(LDFLAGS) $^ -o $@ --script sd_uartbl/linker_uartbl.ld

sd_kpbl/kpbl.elf: sd_kpbl/uartbl.o sd_kpbl/uartbl.c_o
	$(LD) $(LDFLAGS) $^ -o $@ --script sd_uartbl/linker_uartbl.ld

clean:
	-rm -f *.elf
	-rm -f *.bin
	-rm -f bootrom/*.dat
	-rm -f *.o
	-rm -f *.c_o
	-rm -f sd_uartbl/*.o
	-rm -f sd_uartbl/*.c_o
	-rm -f sd_uartbl/*.elf
	-rm -f sd_uartbl/*.bin
	-rm -f bootrom/*.o
	-rm -f bootrom/*.c_o
	-rm -f bootrom/*.elf
	-rm -f bootrom/*.bin
	-rm -f sd_kpbl/*.o
	-rm -f sd_kpbl/*.c_o
	-rm -f sd_kpbl/*.elf
	-rm -f sd_kpbl/*.bin
