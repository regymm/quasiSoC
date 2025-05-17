#!/bin/bash
set -e

#echo -e "\033[37mPreparing boot loader...\033[0m"
#make -C ../firmware
#make -C ../software/ssbi

#if [[ "$1" == "" ]]; then
	#echo -e "\033[31mRun without payload.\033[0m"
#else
	#if [[ "$1" == "mmukernel" ]]; then
		#echo -e "\033[37mPreparing for MMU-Linux kernel...\033[0m"
		#if [ ! -f $2 ]; then
			#echo "Kernel $2 not found!"
			#exit 1
		#fi
		#if [ ! -f $3 ]; then
			#echo "Device tree $3 not found!"
			#exit 1
		#fi
		#if [ ! -f $4 ]; then
			#echo "SBI $4 not found!"
			#exit 1
		#fi
		#rm -f /tmp/meminit
		#touch /tmp/meminit
		#truncate -s 4K /tmp/meminit
		#cat $4 >> /tmp/meminit
		#truncate -s 1M /tmp/meminit
		#cat $3 >> /tmp/meminit
		#truncate -s 4M /tmp/meminit
		#cat $2 >> /tmp/meminit
		###truncate -s 8391168 /tmp/meminit
		###cat "/home/petergu/quasiSoC/software/tests_S/firmware/firmware.bin">> /tmp/meminit
		#truncate -s 32M /tmp/meminit
		##dd if="/home/petergu/quasiSoC/software/tests_S/firmware/firmware.bin" of=/tmp/meminit bs=512 seek=16389 conv=notrunc
		#xxd -p -c 4 /tmp/meminit > /tmp/meminit.dat
		#timeout=$5
	#elif [[ "$1" == "kernel" ]]; then
		#echo -e "\033[37mPreparing for Linux kernel...\033[0m"
		#if [ ! -f $2 ]; then
			#echo "Kernel $2 not found!"
			#exit 1
		#fi
		#if [ ! -f $3 ]; then
			#echo "Device tree $3 not found!"
			#exit 1
		#fi
		#rm -f /tmp/meminit
		#touch /tmp/meminit
		#truncate -s 4K /tmp/meminit
		#cat $2 >> /tmp/meminit
		#truncate -s 7168K /tmp/meminit
		#cat $3 >> /tmp/meminit
		#truncate -s 8M /tmp/meminit
		#xxd -p -c 4 /tmp/meminit > /tmp/meminit.dat
		#timeout=$4
	#else
		#echo -e "\033[37mPreparing payload...\033[0m"
		#rm -f /tmp/meminit
		#touch /tmp/meminit
		#truncate -s 4K /tmp/meminit
		#cat $1 >> /tmp/meminit
		#truncate -s 8M /tmp/meminit
		#xxd -p -c 4 /tmp/meminit > /tmp/meminit.dat
		#timeout=$2
	#fi
#fi

echo -e "\033[37mCompiling...\033[0m"
rm -rf obj_dir
#verilator --binary -j 0 -DSIMULATION --top-module top_simu \
	#iv_simu.v \
verilator -j 0 -O3 -DSIMULATION -DINTERACTIVE_SIM --top-module quasi_main \
	--no-timing \
	-Wno-width -Wno-pinmissing -Wno-implicit -Wno-caseincomplete -Wno-stmtdly -Wno-infiniteloop \
    -Wno-timescalemod \
    -GSIMULATION=1 -GINTERACTIVE_SIM=1 -GBAUD_RATE_UART=50000000 \
    -y ../../../../rtl/hart_transplant/openla500/open-la500 \
    -y ../../../../rtl/hart_transplant/openla500 \
    -cc \
    ../../../../rtl/hart_transplant/openla500/open-la500/csr.h \
    ../../../../rtl/hart_transplant/openla500/open-la500/mycpu.h \
    ../../../../rtl/hart_transplant/openla500/open-la500/addr_trans.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/alu.v \
    ../../../../rtl/hart_transplant/openla500/axi2axilite.v \
    ../../../../rtl/hart_transplant/openla500/axi_addr.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/axi_bridge.v \
    ../../../../rtl/hart_transplant/openla500/axil2mm.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/btb.v \
    ../../../../rtl/quasisoc/clocked_rom.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/csr.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/dcache.v \
    ../../../../rtl/quasisoc/debounce.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/div.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/exe_stage.v \
    ../../../../rtl/quasisoc/gpio/gpio.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/icache.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/id_stage.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/if_stage.v \
    ../../../../rtl/hart_transplant/openla500/loonghighmapper.v \
    ../../../../rtl/hart_transplant/openla500/loonglowmapper.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/mem_stage.v \
    ../../../../rtl/hart_transplant/openla500/mmcm_50_sim.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/mul.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/mycpu_top.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/perf_counter.v \
    ../../../../rtl/hart_transplant/openla500/ram_way.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/regfile.v \
    ../../../../rtl/hart_transplant/openla500/sfifo.v \
    ../../../../rtl/quasisoc/simple_ram.v \
    ../../../../rtl/hart_transplant/openla500/skidbuffer.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/tlb_entry.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/tools.v \
    ../../../../rtl/quasisoc/uart/uart16550.v \
    ../../../../rtl/quasisoc/uart/uartreset.v \
    ../../../../rtl/hart_transplant/openla500/open-la500/wb_stage.v \
    ../../../../rtl/hart_transplant/openla500/quasi_loong_main.v \
    ../../../../rtl/quasisoc/bus/arbitrator.v \
    ../../../../rtl/quasisoc/uart/serialboot.v \
	--exe sim_main.cpp 
make -j16 OPT_FAST="-O3 -march=native" -C obj_dir -f Vquasi_main.mk  Vquasi_main

#iverilog -DSIMULATION -I./ \
	#iv_simu.v \
	#../rtl/pcpu/alu.v \
	#../rtl/pcpu/mmu.v \
	#../rtl/pcpu/privilege.v \
	#../rtl/pcpu/register_file.v \
	#../rtl/pcpu/riscv-multicyc.v \
	#../rtl/pcpu/rv32a.v \
	#../rtl/pcpu/rv32m.v \
	#../rtl/board-specific/nexys-video/quasi_main.v \
	#../rtl/quasisoc/simple_ram.v \
	#../rtl/quasisoc/debounce.v \
	#../rtl/quasisoc/clocked_rom.v \
	#../rtl/quasisoc/bus/arbitrator.v \
	#../rtl/quasisoc/bus/highmapper.v \
	#../rtl/quasisoc/bus/lowmapper.v \
	#../rtl/quasisoc/gpio/gpio.v \
	#../rtl/quasisoc/interrupt/aclint.v \
	#../rtl/quasisoc/interrupt/interrupt_unit.v \
	#../rtl/quasisoc/uart/serialboot.v \
	#../rtl/quasisoc/fifo.v \
	#../rtl/quasisoc/uart/uartnew.v \
	#../rtl/quasisoc/uart/uartreset.v


echo -e "\033[37mLaunching simulation...\033[0m"
#vvp -n a.out
obj_dir/Vquasi_main $timeout

echo -e "\033[37mFinished.\033[0m"
