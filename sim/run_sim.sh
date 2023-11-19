#!/bin/bash
set -e

echo -e "\033[37mPreparing boot loader...\033[0m"
make -C ../firmware

if [[ "$1" == "" ]]; then
	echo -e "\033[31mRun without payload.\033[0m"
else
	if [[ "$1" == "mmukernel" ]]; then
		echo -e "\033[37mPreparing for MMU-Linux kernel...\033[0m"
		rm -f /tmp/meminit
		touch /tmp/meminit
		truncate -s 4K /tmp/meminit
		cat $4 >> /tmp/meminit
		truncate -s 1M /tmp/meminit
		cat $3 >> /tmp/meminit
		truncate -s 4M /tmp/meminit
		cat $2 >> /tmp/meminit
		##truncate -s 8391168 /tmp/meminit
		##cat "/home/petergu/quasiSoC/software/tests_S/firmware/firmware.bin">> /tmp/meminit
		truncate -s 32M /tmp/meminit
		#dd if="/home/petergu/quasiSoC/software/tests_S/firmware/firmware.bin" of=/tmp/meminit bs=512 seek=16389 conv=notrunc
		xxd -p -c 4 /tmp/meminit > /tmp/meminit.dat
		ls;
	elif [[ "$1" == "kernel" ]]; then
		echo -e "\033[37mPreparing for Linux kernel...\033[0m"
		rm -f /tmp/meminit
		touch /tmp/meminit
		truncate -s 4K /tmp/meminit
		cat $2 >> /tmp/meminit
		truncate -s 7168K /tmp/meminit
		cat $3 >> /tmp/meminit
		truncate -s 8M /tmp/meminit
		xxd -p -c 4 /tmp/meminit > /tmp/meminit.dat
	else
		echo -e "\033[37mPreparing payload...\033[0m"
		rm -f /tmp/meminit
		touch /tmp/meminit
		truncate -s 4K /tmp/meminit
		cat $1 >> /tmp/meminit
		truncate -s 8M /tmp/meminit
		xxd -p -c 4 /tmp/meminit > /tmp/meminit.dat
	fi
fi

echo -e "\033[37mCompiling...\033[0m"
rm -rf obj_dir
#verilator --binary -j 0 -DSIMULATION --top-module top_simu \
	#iv_simu.v \
verilator -j 0 -DSIMULATION -DINTERACTIVE_SIM --top-module quasi_main \
	--no-timing \
	-Wno-width -Wno-pinmissing -Wno-implicit -Wno-caseincomplete -Wno-stmtdly -Wno-infiniteloop \
	-I../rtl/board-specific/nexys-video/ \
	--cc \
	../rtl/pcpu/alu.v \
	../rtl/pcpu/mmu.v \
	../rtl/pcpu/privilege.v \
	../rtl/pcpu/register_file.v \
	../rtl/pcpu/riscv-multicyc.v \
	../rtl/pcpu/rv32a.v \
	../rtl/pcpu/rv32m.v \
	../rtl/board-specific/nexys-video/quasi_main.v \
	../rtl/quasisoc/simple_ram.v \
	../rtl/quasisoc/debounce.v \
	../rtl/quasisoc/clocked_rom.v \
	../rtl/quasisoc/bus/arbitrator.v \
	../rtl/quasisoc/bus/highmapper.v \
	../rtl/quasisoc/bus/lowmapper.v \
	../rtl/quasisoc/gpio/gpio.v \
	../rtl/quasisoc/interrupt/aclint.v \
	../rtl/quasisoc/interrupt/interrupt_unit.v \
	../rtl/quasisoc/uart/serialboot.v \
	../rtl/quasisoc/fifo.v \
	../rtl/quasisoc/uart/uartsim.v \
	../rtl/quasisoc/uart/uartreset.v \
	--exe sim_main.cpp 
make -C obj_dir -f Vquasi_main.mk  Vquasi_main

iverilog -DSIMULATION -I../rtl/board-specific/nexys-video/ \
	iv_simu.v \
	../rtl/pcpu/alu.v \
	../rtl/pcpu/mmu.v \
	../rtl/pcpu/privilege.v \
	../rtl/pcpu/register_file.v \
	../rtl/pcpu/riscv-multicyc.v \
	../rtl/pcpu/rv32a.v \
	../rtl/pcpu/rv32m.v \
	../rtl/board-specific/nexys-video/quasi_main.v \
	../rtl/quasisoc/simple_ram.v \
	../rtl/quasisoc/debounce.v \
	../rtl/quasisoc/clocked_rom.v \
	../rtl/quasisoc/bus/arbitrator.v \
	../rtl/quasisoc/bus/highmapper.v \
	../rtl/quasisoc/bus/lowmapper.v \
	../rtl/quasisoc/gpio/gpio.v \
	../rtl/quasisoc/interrupt/aclint.v \
	../rtl/quasisoc/interrupt/interrupt_unit.v \
	../rtl/quasisoc/uart/serialboot.v \
	../rtl/quasisoc/fifo.v \
	../rtl/quasisoc/uart/uartnew.v \
	../rtl/quasisoc/uart/uartreset.v


echo -e "\033[37mLaunching simulation...\033[0m"
#vvp -n a.out
obj_dir/Vquasi_main

echo -e "\033[37mFinished.\033[0m"
