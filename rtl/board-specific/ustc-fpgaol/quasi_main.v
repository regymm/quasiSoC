/**
 * File              : quasi_main.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.11.25
 * Last Modified Date: 2021.12.31
 */
`timescale 1ns / 1ps
// pComputer main block design
`include "quasi.vh"

module quasi_main 
	#(
		parameter CLOCK_FREQ = 62500000,
		parameter BAUD_RATE_UART = 115200, // may misbehave if modified
		parameter BAUD_RATE_CH375 = 9600,
		//parameter TIMER_COUNTER = 4000 // for debugging
		parameter TIMER_COUNTER = 1000000
	)
    (
        input sysclk,
        
        input [1:0]sw,
        input [1:0]btn,
        output [3:0]led,

        input uart_rx,
        output uart_tx,
		input rts,
		output cts,
		output rts_led,
		output uart_tx_led,
		output uart_rx_led
    );

	assign cts = 0;
	assign rts_led = rts;
	assign uart_tx_led = uart_tx;
	assign uart_rx_led = uart_rx;

    wire clk_main;
	wire clk_mem;
	wire clk_2x;
    wire clk_hdmi_25;
    wire clk_hdmi_250;
	clock_wizard clock_wizard_inst(
		.clk_in1(sysclk),
		.clk_main(clk_main),
		.clk_mem(clk_mem),
		.clk_hdmi_25(clk_hdmi_25),
		.clk_hdmi_250(clk_hdmi_250),
		.clk_hdmi_50(clk_2x)
	);
	//clocking_xc7 clocking_xc7_inst (
		//.clk_50(sysclk),
		//.clk1_62d5(clk_main),
		//.clk2_125(clk_mem),
		//.clk3_25(clk_hdmi_25),
		//.clk4_250(clk_hdmi_250),
		//.clk5_50(clk_2x)
	//);


    wire [1:0]sw_d;
    debounce #(.N(2)) debounce_inst_0(
        .clk(clk_main),
        .i_btn(sw),
        .o_state(sw_d)
    );

    wire [1:0]btn_d;
    debounce #(.N(2)) debounce_inst_1(
        .clk(clk_main),
        .i_btn(btn),
        .o_state(btn_d)
    );

	// backup serial pins
	wire uart_rx_in = uart_rx;

    // reset signal
	wire manual_rst = sw_d[0];
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
		.INIT("/home/petergu/MyHome/quasiSoC/firmware/bootrom/result_bootrom.dat")
	) bootrom(
		.clk(clk_main),
        .a(bootm_a),
		.rd(bootm_rd),
        .spo(bootm_spo),
		.ready(bootm_ready)
	);

    
    // distributed ram 4096*32
    wire [31:0]distm_a;
    wire [31:0]distm_d;
    wire distm_we;
	wire distm_rd;
    wire [31:0]distm_spo;
	wire distm_ready;
	simple_ram #(
		.WIDTH(32),
		.DEPTH(12),
		.INIT("/home/petergu/MyHome/quasiSoC/rtl/null.dat")
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
        .rx(uart_rx_in),

        .a(uart_a),
        .d(uart_d),
        .we(uart_we),
        .spo(uart_spo), 

        .irq(irq_uart),

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

    // sdcard
    wire [15:0]sd_a;
    wire [31:0]sd_d;
    wire sd_we;
    wire [31:0]sd_spo;

    wire irq_sd;
`ifdef SDCARD_EN
    sdcard sdcard_inst(
        .clk(clk_main),
        .rst(rst_sdcard),

        .a(sd_a),
        .d(sd_d),
        .we(sd_we),
        .spo(sd_spo),

        .sd_dat0(sd_dat0),
        .sd_ncd(sd_ncd),
        .sd_dat1(sd_dat1),
        .sd_dat2(sd_dat2),
        .sd_dat3(sd_dat3),
        .sd_cmd(sd_cmd),
        .sd_sck(sd_sck),

        .irq(irq_sd) // nc
    );
`else
	assign sd_spo = {7'b0, 1'b1, 24'b0}; // indicate SD not deteced
	assign irq_sd = 0;
	assign sd_dat1 = 1'bZ;
	assign sd_dat2 = 1'bZ;
	assign sd_dat3 = 1'bZ;
	assign sd_cmd = 1'bZ;
	assign sd_sck = 1'bZ;
`endif

	// CH375b
	wire [2:0]usb_a;
	wire [31:0]usb_d;
	wire usb_we;
	wire [31:0]usb_spo;
	wire irq_usb;
`ifdef CH375B_EN
	ch375b #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE_CH375)
	) ch375b_inst
	(
		.clk(clk_main),
		.rst(rst_usb),

		.a(usb_a),
		.d(usb_d),
		.we(usb_we),
		.spo(usb_spo),

		.irq(irq_usb),

		.ch375_tx(ch375_tx),
		.ch375_rx(ch375_rx),
		.ch375_nint(ch375_nint)
	);
`else
	assign usb_spo = 0;
	assign ch375_rx = 1;
`endif

	wire mainm_burst_en_m;
	wire [7:0]mainm_burst_length_m;
	wire [31:0]mainm_a_m;
	wire [31:0]mainm_d_m;
	wire mainm_we_m;
	wire mainm_rd_m;
	wire [31:0]mainm_spo_m;
	wire mainm_ready_m;
	wire mainm_irq;
`ifdef PSRAM_EN
	`ifdef CACHE_EN
	memory_controller_burst memory_controller_inst
	//memory_controller memory_controller_inst
	(
		.clk(clk_main),
		.clk_mem(clk_mem),
		.rst(rst_psram),

		.burst_en(mainm_burst_en_m),
		.burst_length(mainm_burst_length_m),

		.a(mainm_a_m),
		.d(mainm_d_m),
		.we(mainm_we_m),
		.rd(mainm_rd_m),
		.spo(mainm_spo_m),
		.ready(mainm_ready_m), 

		.irq(mainm_irq),

		.psram_ce(psram_ce), 
		.psram_mosi(psram_mosi), 
		.psram_miso(psram_miso), 
		.psram_sio2(psram_sio2), 
		.psram_sio3(psram_sio3),
		.psram_sclk(psram_sclk)
	);
	`else
	memory_controller_basic memory_controller_inst
	(
		.clk(clk_main),
		.clk_mem(clk_mem),
		.rst(rst_psram),

		.a(mainm_a_m),
		.d(mainm_d_m),
		.we(mainm_we_m),
		.rd(mainm_rd_m),
		.spo(mainm_spo_m),
		.ready(mainm_ready_m), 

		.irq(mainm_irq),

		.psram_ce(psram_ce), 
		.psram_mosi(psram_mosi), 
		.psram_miso(psram_miso), 
		.psram_sio2(psram_sio2), 
		.psram_sio3(psram_sio3),
		.psram_sclk(psram_sclk)
	);
	`endif
`else
	// 2**16 * 32 256KB
	// need manual patching: 1024x 00000000 before xxd -p firmware.bin
	simple_ram #(
		.WIDTH(32),
		.DEPTH(16),
		.INIT("/home/petergu/MyHome/src/micropython/ports/fpgaol/firmware.txt")
	) distram_mainm (
        .clk(clk_main),
        .a({2'b0, mainm_a_m[31:2]}),
        .d(mainm_d_m),
        .we(mainm_we_m),
		.rd(mainm_rd_m),
        .spo(mainm_spo_m),
		.ready(mainm_ready_m)
    );
`endif

	// serial boot
	wire [2:0]sb_a;
	wire [31:0]sb_d;
	wire sb_we;
	wire sb_ready;
	wire mainm_burst_en_c;
	wire [7:0]mainm_burst_length_c;
	wire [31:0]mainm_a_c;
	wire [31:0]mainm_d_c;
	wire mainm_we_c;
	wire mainm_rd_c;
	wire [31:0]mainm_spo_c;
	wire mainm_ready_c;
`ifdef SERIALBOOT_EN
	serialboot serialboot_inst(
		.clk(clk_main),
		.rst(rst_sb),

		.a(sb_a),
		.d(sb_d),
		.we(sb_we),
		.ready(sb_ready),

		.burst_en_mem(mainm_burst_en_m),
		.burst_length_mem(mainm_burst_length_m),
		.a_mem(mainm_a_m),
		.d_mem(mainm_d_m),
		.we_mem(mainm_we_m),
		.rd_mem(mainm_rd_m),
		.spo_mem(mainm_spo_m),
		.ready_mem(mainm_ready_m),

		.burst_en_cpu(mainm_burst_en_c),
		.burst_length_cpu(mainm_burst_length_c),
		.a_cpu(mainm_a_c),
		.d_cpu(mainm_d_c),
		.we_cpu(mainm_we_c),
		.rd_cpu(mainm_rd_c),
		.spo_cpu(mainm_spo_c),
		.ready_cpu(mainm_ready_c),

		.uart_data(sb_rxdata),
		.uart_ready(sb_rxnew)
	);
`else
	assign sb_ready = 1;
	assign a_mem = mainm_a_c;
	assign d_mem = mainm_d_c;
	assign we_mem = mainm_we_c;
	assign spo_mem = mainm_spo_c;
	assign rd_mem = mainm_rd_c;
	assign ready_mem = mainm_ready_c;
`endif

	wire [31:0]cache_a;
	wire [31:0]cache_d;
	wire cache_we;
	wire cache_rd;
	wire [31:0]cache_spo;
	wire cache_ready;
`ifdef CACHE_EN
	cache_cpu
	//#(
		//.WAYS(1),
		//.WAY_LINES(128),
		//.WAY_WORDS_PER_BLOCK(32),
		//.WAY_TAG_LENGTH(32)
	//)
	cache_cpu_inst(
		.clk(clk_main),
		.rst(rst_mmu), // TODO: add a real reset

		.a(cache_a),
		.d(cache_d),
		.we(cache_we),
		.rd(cache_rd),
		.spo(cache_spo),
		.ready(cache_ready),

		.burst_en(mainm_burst_en_c),
		.burst_length(mainm_burst_length_c),
		.lowmem_a(mainm_a_c),
		.lowmem_d(mainm_d_c),
		.lowmem_we(mainm_we_c),
		.lowmem_rd(mainm_rd_c),
		.lowmem_spo(mainm_spo_c),
		.lowmem_ready(mainm_ready_c)

		// hit & miss
	);
`else
	//assign mainm_burst_en_c = 1;
	//assign mainm_burst_length_c = 1;
	assign mainm_a_c = cache_a;
	assign mainm_d_c = cache_d;
	assign mainm_we_c = cache_we;
	assign mainm_rd_c = cache_rd;
	assign cache_spo = mainm_spo_c;
	assign cache_ready = mainm_ready_c;
`endif


    // video
    wire [31:0]video_a;
    wire [31:0]video_d;
    wire video_we;
    wire [31:0]video_spo;
`ifdef VIDEO_EN
	//hdmi_demo hdmi_demo_inst(
		//.clk(clk),
		//.rst(rst),

		//.a(video_a),
		//.d(video_d),
		//.we(video_we),
		//.spo(video_spo),

		//.clk_pix(clk_hdmi_25),
		//.clk_tmds(clk_hdmi_250),
		//.TMDSp(TMDSp),
		//.TMDSn(TMDSn),
		//.TMDSp_clock(TMDSp_clock),
		//.TMDSn_clock(TMDSn_clock)
	//);
	mkrvidor4000_top mkrvidor4000_top_inst(
		.clk(clk_main),
		.clk_pix(clk_hdmi_25),
		.clk_tmds(clk_hdmi_250),
		.clk_2x(clk_2x),
		.rst(rst_video),

		.a(video_a),
		.d(video_d),
		.we(video_we),
		.spo(video_spo),

		.TMDSp(TMDSp),
		.TMDSn(TMDSn),
		.TMDSp_clock(TMDSp_clock),
		.TMDSn_clock(TMDSn_clock)
	);
`else
	assign video_spo = 0;
	//OBUFDS OBUFDS_red(
		//.I(0),
		//.O(TMDSp[2]),
		//.OB(TMDSn[2])
	//);
	//OBUFDS OBUFDS_green(
		//.I(0),
		//.O(TMDSp[1]),
		//.OB(TMDSn[1])
	//);
	//OBUFDS OBUFDS_blue(
		//.I(0),
		//.O(TMDSp[0]),
		//.OB(TMDSn[0])
	//);
	//OBUFDS OBUFDS_clock(
		//.I(0),
		//.O(TMDSp_clock),
		//.OB(TMDSn_clock)
	//);
`endif

	wire [31:0]ps2_spo;
	wire irq_ps2;
`ifdef PS2_EN
	ps2 ps2_inst(
		.clk(clk_main),
		.rst(rst),
		.spo(ps2_spo),
		.kclk(ps2_clk),
		.kdata(ps2_data),
		.irq(irq_ps2)
	);
`else
	assign irq_ps2 = 0;
`endif

	wire [31:0]eth_a;
	wire [31:0]eth_d;
	wire eth_we;
	wire [31:0]eth_spo;
	wire irq_eth;
`ifdef ETH_EN
	w5500_fdm w5500_fdm_inst(
		.clk(clk_main),
		.rst(rst),
		.a(eth_a),
		.d(eth_d),
		.we(eth_we),
		.spo(eth_spo),

		.intn(eth_intn),
		.rstn(eth_rstn),
		.sclk(eth_sclk),
		.scsn(eth_scsn),
		.mosi(eth_mosi),
		.miso(eth_miso),

		.irq(irq_eth)
	);
`else
	assign eth_spo = 0;
	assign irq_eth = 0;
`endif

    // interrupt unit
    wire cpu_eip;
    wire cpu_eip_istimer;
    wire cpu_eip_reply;

	wire [2:0]timer_a;
	wire [31:0]timer_d;
	wire timer_we;
	wire [31:0]timer_spo;

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
        .irq(irq_timer),

		.a(timer_a),
		.d(timer_d),
		.we(timer_we),
		.spo(timer_spo)
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
		.i_ps2(irq_ps2),

        .a(int_a),
        .d(int_d),
        .we(int_we),
        .spo(int_spo)
    );
`else
	assign cpu_eip = 0;
	assign cpu_eip_istimer = 0;
	assign int_spo = 0;
	assign timer_spo = 0;
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
		.eip_reply(cpu_eip_reply),

		.tip(irq_timer_pending),

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

		.cache_a(cache_a),
		.cache_d(cache_d),
		.cache_we(cache_we),
		.cache_rd(cache_rd),
		.cache_spo(cache_spo),
		.cache_ready(cache_ready),

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

		.t_a(timer_a),
		.t_d(timer_d),
		.t_we(timer_we),
		.t_spo(timer_spo),

		.eth_a(eth_a),
		.eth_d(eth_d),
		.eth_we(eth_we),
		.eth_spo(eth_spo),

        .irq(pirq)
    );
endmodule
