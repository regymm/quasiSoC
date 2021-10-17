/**
 * File              : pcpu_main.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.11.25
 * Last Modified Date: 2021.01.03
 */
`timescale 1ns / 1ps
// pComputer main block design
`include "pCPU.vh"
 
module pcpu_main 
	#(
		parameter CLOCK_FREQ = 62500000,
		parameter BAUD_RATE_UART = 921600,
		parameter TIMER_COUNTER = 10000000
	)
    (
        input clk1,
        
        input [0:0]btn,
        output [1:0]led,
		  
		  input uart_rx,
		  output uart_tx
    );



    wire clk_main;
    wire clk_locked;
    clock_wizard clock_wizard_inst(
        .clk_in1(clk1),
        .clk_main(clk_main),
		  .locked(clk_locked)
    );


    wire [1:0]sw_d;
    debounce #(.N(2)) debounce_inst_0(
        .clk(clk_main),
        .i_btn(sw),
        .o_state(sw_d)
    );

    wire [1:0]btn_d;
    debounce #(.N(2)) debounce_inst_1(
        .clk(clk_main),
        .i_btn({1'b0, ~btn}), // reverse due to board condition
        .o_state(btn_d)
    );


    // reset signal
	wire manual_rst = btn_d[0];
	// assign led[0] = rst;
	// assign led[1] = clk_locked;
    (*mark_debug = "true"*) wire rst = manual_rst | uart_rst;

	// reset module
	wire [31:0]rst_d = 0;
	wire rst_we = 0;
	wire rst_gpio;
	wire rst_uart;
	wire rst_sdcard;
	wire rst_video;
	wire rst_usb;
	wire rst_psram;
	wire rst_interrupt;
	wire rst_sb;
	wire rst_timer;
	wire rst_mmu;
	reset reset_unit(
		.clk(clk_main),
		.rst_globl(rst),
		.d(rst_d),
		.we(rst_we),

		.rst_gpio(rst_gpio),
		.rst_uart(rst_uart),
		.rst_sdcard(rst_sdcard),
		.rst_video(rst_video),
		.rst_usb(rst_usb),
		.rst_psram(rst_psram),
		.rst_interrupt(rst_interrupt),
		.rst_sb(rst_sb),
		.rst_timer(rst_timer),
		.rst_mmu(rst_mmu)
	);


    // bootrom 1024*32
    wire [9:0]bootm_a;
	wire bootm_rd;
    wire [31:0]bootm_spo;
	wire bootm_ready;
	clocked_rom #(
		.WIDTH(32),
		.DEPTH(10),
		.INIT("/home/petergu/MyHome/pComputer/pseudOS/coe/result_bootrom.dat")
	) bootrom(
		.clk(clk_main),
        .a(bootm_a),
		.rd(bootm_rd),
        .spo(bootm_spo),
		.ready(bootm_ready)
	);

    
    // distributed ram 4096*32
    wire [11:0]distm_a;
    wire [31:0]distm_d;
    wire distm_we;
	wire distm_rd;
    wire [31:0]distm_spo;
	wire distm_ready;
	simple_ram #(
		.WIDTH(32),
		.DEPTH(12)
		//.INIT("/home/petergu/MyHome/pComputer/pseudOS/coe/result_zeros.dat")
	) distram (
        .clk(clk_main),
        .a(distm_a),
        .d(distm_d),
        .we(distm_we),
		.rd(distm_rd),
        .spo(distm_spo),
		.ready(distm_ready)
    );

    
    // gpio
    wire [3:0]gpio_a;
    wire [31:0]gpio_d;
    wire gpio_we;
    wire [31:0]gpio_spo;
	wire irq_gpio;
`ifdef GPIO_EN
    gpio gpio_inst(
        .clk(clk_main),
        .rst(rst_gpio),

        .a(gpio_a),
        .d(gpio_d),
        .we(gpio_we),
        .spo(gpio_spo),

        .btn(btn_d),
        .sw(sw_d),
        .led(led),

		.irq(irq_gpio)
    );
`else
	assign gpio_spo = 0;
	assign led = 4'b0;
	assign irq_gpio = 0;
`endif


    // uart
    wire [2:0]uart_a;
    wire [31:0]uart_d;
    wire uart_we;
    wire [31:0]uart_spo;
	wire [7:0]sb_rxdata;
	wire sb_rxnew;
    wire irq_uart;
`ifdef UART_EN
	uart #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE_UART)
	) uart_inst (
        .clk(clk_main),
		`ifdef UART_RST_EN
			// avoid UART reset dead lock
			.rst(manual_rst),
		`else
			.rst(rst_uart),
		`endif

        .tx(uart_tx),
        .rx(uart_rx),

        .a(uart_a),
        .d(uart_d),
        .we(uart_we),
        .spo(uart_spo), 

        .irq(irq_uart),

		.override(sb_uart_override),
		.rxnew(sb_rxnew),
		.rxdata(sb_rxdata)
    );
`else
	assign uart_spo = 0;
	assign uart_tx = 1;
	assign irq_uart = 0;
`endif

	// uart reset
	wire uart_rst;
`ifdef UART_RST_EN
	uartreset uartreset_inst(
		.clk(clk_main),

		.uart_data(sb_rxdata),
		.uart_ready(sb_rxnew),

		.uart_rst(uart_rst)
	);
`else
	assign uart_rst = 0;
`endif

	assign sd_spo = 0;
	assign irq_sd = 0;


	assign usb_spo = 0;


	wire [31:0]mainm_a;
	wire [31:0]mainm_d;
	wire mainm_we;
	wire mainm_rd;
	wire [31:0]mainm_spo;
	wire mainm_ready;
	wire mainm_irq;
	wire sb_mem_override;
	wire [31:0]sb_mem_a;
	wire [31:0]sb_mem_d;
	wire sb_mem_we;
`ifdef PSRAM_EN
	memory_controller memory_controller_inst
	(
		.clk(clk_main),
		.clk_mem(clk_mem),
		.rst(rst_psram),

		.a(mainm_a),
		.d(mainm_d),
		.we(mainm_we),
		.rd(mainm_rd),
		.spo(mainm_spo),
		.ready(mainm_ready), 

		.override(sb_mem_override),
		.a2(sb_mem_a),
		.d2(sb_mem_d),
		.we2(sb_mem_we),

		.irq(mainm_irq),

		.psram_ce(psram_ce), 
		.psram_mosi(psram_mosi), 
		.psram_miso(psram_miso), 
		.psram_sio2(psram_sio2), 
		.psram_sio3(psram_sio3),
		.psram_sclk(psram_sclk)
	);
`else
`endif

	// serial boot
	wire [2:0]sb_a;
	wire [31:0]sb_d;
	wire sb_we;
`ifdef SERIALBOOT_EN
	serialboot serialboot_inst(
		.clk(clk_main),
		.rst(rst_sb),

		.a(sb_a),
		.d(sb_d),
		.we(sb_we),
		.ready(sb_ready),

		.uart_override(sb_uart_override),
		.uart_data(sb_rxdata),
		.uart_ready(sb_rxnew),

		.mem_override(sb_mem_override),
		.mem_a(sb_mem_a),
		.mem_d(sb_mem_d),
		.mem_we(sb_mem_we),
		.mem_ready(1'b1)
	);
`else
	assign sb_uart_override = 0;
	assign sb_mem_override = 0;
	assign sb_ready = 1;
`endif

	assign video_spo = 0;
	assign ps2_irq = 0;

    // interrupt unit
    wire cpu_eip;
    wire cpu_eip_istimer;
    wire cpu_eip_reply;

    wire [2:0]int_a;
    wire [31:0]int_d;
    wire int_we;
    wire [31:0]int_spo;
`ifdef IRQ_EN
    // timer interrupt
    wire irq_timer;
    timer #(.TIMER_COUNTER(TIMER_COUNTER)) timer_inst(
        .clk(clk_main),
        .rst(rst_timer),
        .irq(irq_timer)
    );

    interrupt_unit interrupt_unit_inst(
        .clk(clk_main),
        .rst(rst_interrupt),

        .interrupt(cpu_eip),
		.int_istimer(cpu_eip_istimer),
        .int_reply(cpu_eip_reply),

        .i_timer(irq_timer),
        .i_uart(irq_uart),
        .i_gpio(irq_gpio),

        .a(int_a),
        .d(int_d),
        .we(int_we),
        .spo(int_spo)
    );
`else
	assign cpu_eip = 0;
	assign cpu_eip_istimer = 0;
	assign int_spo = 0;
`endif

    // cpu-multi-cycle
    wire [31:0]spo;
    wire ready;
    wire [31:0]a;
    wire [31:0]d;
    wire we;
    wire rd;
	riscv_multicyc riscv_multicyc_inst(
		.clk(clk_main),
		.rst(rst),

		.eip(cpu_eip),
		.eip_istimer(cpu_eip_istimer),
		.eip_reply(cpu_eip_reply),

		.spo(spo),
		.ready(ready),
		.a(a),
		.d(d),
		.we(we),
		.rd(rd)
	);


    // MMU
    wire virq;
    wire [31:0]pspo;
    wire pready;
    wire pirq;
    wire [31:0]pa;
    wire [31:0]pd;
    wire pwe;
    wire prd;
`ifdef MMU_EN
    mmu mmu_inst(
        .clk(clk_main),
        .rst(rst_mmu),

        .ring(ring),

        .va(a),
        .vd(d),
        .vwe(we),
        .vrd(rd),
        .vspo(spo),
        .vready(ready),
        .virq(virq), // nc

        .pspo(pspo),
        .pready(pready),
        .pa(pa),
        .pd(pd),
        .pwe(pwe),
        .prd(prd)
    );
`else
	assign virq = 0;
	assign pa = a;
	assign pd = d;
	assign pwe = we;
	assign prd = rd;
	assign spo = pspo;
	assign ready = pready;
`endif

    // memory mapper
    mmapper mmapper_inst(
        .a(pa),
        .d(pd),
        .we(pwe),
        .rd(prd),
        .spo(pspo),
        .ready(pready),

        .bootm_a(bootm_a),
		.bootm_rd(bootm_rd),
        .bootm_spo(bootm_spo),
		.bootm_ready(bootm_ready),

        .distm_a(distm_a),
        .distm_d(distm_d),
        .distm_we(distm_we),
		.distm_rd(distm_rd),
        .distm_spo(distm_spo),
		.distm_ready(distm_ready),

		.mainm_a(mainm_a),
		.mainm_d(mainm_d),
		.mainm_we(mainm_we),
		.mainm_rd(mainm_rd),
		.mainm_spo(mainm_spo),
		.mainm_ready(mainm_ready),

        .sd_spo(sd_spo),
        .sd_a(sd_a),
        .sd_d(sd_d),
        .sd_we(sd_we),

        .usb_spo(usb_spo),
        .usb_a(usb_a),
        .usb_d(usb_d),
        .usb_we(usb_we),

        .gpio_spo(gpio_spo),
        .gpio_a(gpio_a),
        .gpio_d(gpio_d),
        .gpio_we(gpio_we),

        .uart_spo(uart_spo),
        .uart_a(uart_a),
        .uart_d(uart_d),
        .uart_we(uart_we),

        .video_spo(video_spo),
        .video_a(video_a),
        .video_d(video_d),
        .video_we(video_we),

        .int_spo(int_spo),
        .int_a(int_a),
        .int_d(int_d),
        .int_we(int_we),

        .sb_spo(sb_spo),
        .sb_a(sb_a),
        .sb_d(sb_d),
        .sb_we(sb_we),
		.sb_ready(sb_ready),

		.ps2_spo(ps2_spo),

        .irq(pirq)
    );
endmodule
