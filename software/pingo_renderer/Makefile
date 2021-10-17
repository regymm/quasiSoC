#RISCV	=	/opt/riscv32ima/bin/riscv32-unknown-linux-gnu-
RISCVDIR=	/opt/riscv32i
RISCV	=	riscv32-unknown-elf-
AS		=	$(RISCV)as
ASFLAGS	=	-march=rv32im -mabi=ilp32
LD 		=	$(RISCV)ld
#LDFLAGS	=	-m elf32lriscv --nostdlib
LDFLAGS	=	-m elf32lriscv
CC		=	$(RISCV)gcc
CPP		=	$(RISCV)g++
CC_L_F	=	-march=rv32i -mabi=ilp32 -nostdlib -mstrict-align -O0 -static
CFLAGS	=	-march=rv32im -mabi=ilp32 -mstrict-align -O0 -static
CPPFLAGS=	$(CFLAGS) -nostdlib
OBJCOPY	=	$(RISCV)objcopy

all: sdboot.bin

%.bin: %.elf
	$(OBJCOPY) -O binary $*.elf $*.bin
	python3 ../binpatch.py $*.bin $*.elf

sdboot.elf: 
	(cd pingo; bash manualmake.sh; cd ..) && $(CC) $(CC_L_F) -fPIC -g -lc -lgcc ../newlib/crt0.S ../newlib/syscall.c sdboot.S sdboot.c pingo/*.o -o $@ -fPIE -pie -T linker_sdboot.ld  -lm -lc -lgcc


clean:
	-rm -f *.elf
	-rm -f *.bin
	-rm -f *.o
