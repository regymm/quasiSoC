#mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
#current_dir := $(patsubst %/,%,$(dir $(mkfile_path)))
TOP := cache_cpu
VERILOG := \
		   ../cache_cpu.v
			#../../../rtl/QuasiSoC/simple_ram.v \
			#../../../rtl/board-specific/squeakyboard/quasi_main.v \
			#../../../rtl/pCPU/register_file_bram.v \
			#../../../rtl/pCPU/riscv-multicyc.v \
			#../../../rtl/pCPU/register_file.v \
			#../../../rtl/pCPU/rv32m.v \
			#../../../rtl/pCPU/privilege.v \
			#../../../rtl/pCPU/alu.v \
			#../../../rtl/QuasiSoC/reset.v \
			#../../../rtl/QuasiSoC/interrupt/timer_interrupt.v \
			#../../../rtl/QuasiSoC/interrupt/interrupt_unit.v \
			#../../../rtl/QuasiSoC/ch375b/ch375b.v \
			#../../../rtl/QuasiSoC/debounce.v \
			#../../../rtl/QuasiSoC/ps2/ps2.v \
			#../../../rtl/QuasiSoC/ps2/ps2_driver.v \
			#../../../rtl/QuasiSoC/hdmi/attributemap.v \
			#../../../rtl/QuasiSoC/hdmi/hdmi_hw_fpga4fun.v \
			#../../../rtl/QuasiSoC/hdmi/console.v \
			#../../../rtl/QuasiSoC/hdmi/hdmi_mkrvidor4000.sv \
			#../../../rtl/QuasiSoC/hdmi/glyphmap.v \
			#../../../rtl/QuasiSoC/clocked_rom.v \
			#../../../rtl/QuasiSoC/w5500/w5500.v \
			#../../../rtl/QuasiSoC/psram/burst/memory_controller_basic.v \
			#../../../rtl/QuasiSoC/psram/burst/memory_controller_burst.v \
			#../../../rtl/QuasiSoC/psram/burst/psram_controller_qpi.v \
			#../../../rtl/QuasiSoC/psram/slow/memory_controller_slow.v \
			#../../../rtl/QuasiSoC/psram/slow/psram_controller_spi.v \
			#../../../rtl/QuasiSoC/sdcard/sd_controller.v \
			#../../../rtl/QuasiSoC/sdcard/sdcard.v \
			#../../../rtl/QuasiSoC/uart/uartreset.v \
			#../../../rtl/QuasiSoC/uart/uart.v \
			#../../../rtl/QuasiSoC/uart/baud_rate_gen.v \
			#../../../rtl/QuasiSoC/uart/serialboot.v \
			#../../../rtl/QuasiSoC/cache/cache_cpu.v \
			#../../../rtl/QuasiSoC/cache/cacheway.v \
			#../../../rtl/QuasiSoC/simple_dp_ram.v \
			#../../../rtl/QuasiSoC/arbitrator.v \
			#../../../rtl/QuasiSoC/simple_rom.v \
			#../../../rtl/QuasiSoC/gpio/gpio.v \
			#../../../rtl/QuasiSoC/mmapper.v \
			#../../../rtl/QuasiSoC/clk/clocking_xc7.v

BITSTREAM_DEVICE := zynq7
XDC := ../../../rtl/board-specific/squeakyboard/squeakyboard-symbi.xdc
#SDC := ../../../rtl/board-specific/squeakyboard/squeakyboard.sdc
BUILDDIR := build

PARTNAME := xc7z010clg400-1
DEVICE   := xc7z010_test
BOARD_BUILDDIR := ${BUILDDIR}

.DELETE_ON_ERROR:


#all: ${BOARD_BUILDDIR}/${TOP}.bit
all: ${BOARD_BUILDDIR}/${TOP}.bit

${BOARD_BUILDDIR}:
	mkdir -p ${BOARD_BUILDDIR}
	#ln -s ${MEM_INIT} ${BOARD_BUILDDIR}

${BOARD_BUILDDIR}/${TOP}.eblif: | ${BOARD_BUILDDIR}
	cd ${BOARD_BUILDDIR} && symbiflow_synth -t ${TOP} -v ${VERILOG} -d ${BITSTREAM_DEVICE} -p ${PARTNAME} -x ${XDC} 

${BOARD_BUILDDIR}/${TOP}.net: ${BOARD_BUILDDIR}/${TOP}.eblif
	cd ${BOARD_BUILDDIR} && symbiflow_pack -e ${TOP}.eblif -d ${DEVICE}
	#cd ${BOARD_BUILDDIR} && symbiflow_pack -e ${TOP}.eblif -d ${DEVICE} -s ${SDC}

${BOARD_BUILDDIR}/${TOP}.place: ${BOARD_BUILDDIR}/${TOP}.net
	cd ${BOARD_BUILDDIR} && symbiflow_place -e ${TOP}.eblif -d ${DEVICE} -n ${TOP}.net -P ${PARTNAME}
	#cd ${BOARD_BUILDDIR} && symbiflow_place -e ${TOP}.eblif -d ${DEVICE} -p ${PCF} -n ${TOP}.net -P ${PARTNAME} -s ${SDC} 2>&1 > /dev/null

${BOARD_BUILDDIR}/${TOP}.route: ${BOARD_BUILDDIR}/${TOP}.place
	cd ${BOARD_BUILDDIR} && symbiflow_route -e ${TOP}.eblif -d ${DEVICE}
	#cd ${BOARD_BUILDDIR} && symbiflow_route -e ${TOP}.eblif -d ${DEVICE} -s ${SDC} 2>&1 > /dev/null

${BOARD_BUILDDIR}/${TOP}.fasm: ${BOARD_BUILDDIR}/${TOP}.route
	cd ${BOARD_BUILDDIR} && symbiflow_write_fasm -e ${TOP}.eblif -d ${DEVICE}

${BOARD_BUILDDIR}/${TOP}.bit: ${BOARD_BUILDDIR}/${TOP}.fasm
	cd ${BOARD_BUILDDIR} && symbiflow_write_bitstream -d ${BITSTREAM_DEVICE} -f ${TOP}.fasm -p ${PARTNAME} -b ${TOP}.bit

clean:
	rm -rf ${BUILDDIR}

