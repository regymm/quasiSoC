# varaibles are exported
CC		=	$(RISCV)gcc
CC_L_F	=	-march=rv32i -mabi=ilp32 -O0 -fPIC -g

test: test.c
	$(CC) $(CC_L_F) $^ -o $@ -fPIE -T linker_user.ld -nostdlib

#test: test.c test2.c
	#$(CC) $(CC_L_F) $^ -o $@ -fPIE -Ttext=0x20000000

clean:
	-rm -rf test
