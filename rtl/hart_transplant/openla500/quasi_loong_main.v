// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm

`timescale 1ns / 1ps
`include "quasi.vh"

module quasi_main 
	#(
		parameter SIMULATION = 0,
		parameter INTERACTIVE_SIM = 0,
		parameter CLOCK_FREQ = 50000000,
		parameter BAUD_RATE_UART = 115200,
		parameter BAUD_RATE_UART2 = 115200,
		parameter TLBNUM = 16
	)
    (
        input sysclk,
        
        input [1:0]sw,
        input [1:0]btn,
        output [3:0]led,

        input uart_rx,
        output uart_tx,
	`ifdef INTERACTIVE_SIM
		input uart_rxsim_en,
		input [7:0]uart_rxsim_data,
	`endif

		input uart_rx_2,
		output uart_tx_2,

        input sd_ncd,
        input sd_dat0,
        output sd_dat1,
        output sd_dat2,
        output sd_dat3,
        output sd_cmd,
        output sd_sck,

        output [2:0]TMDSp,
        output [2:0]TMDSn,
        output TMDSp_clock,
        output TMDSn_clock,

        inout [15:0]       ddr3_dq,
        inout [1:0]        ddr3_dqs_n,
        inout [1:0]        ddr3_dqs_p,
        output [14:0]     ddr3_addr,
        output [2:0]        ddr3_ba,
        output            ddr3_ras_n,
        output            ddr3_cas_n,
        output            ddr3_we_n,
        output            ddr3_reset_n,
        output [0:0]       ddr3_ck_p,
        output [0:0]       ddr3_ck_n,
        output [0:0]       ddr3_cke,
        output [1:0]     ddr3_dm,
        output [0:0]       ddr3_odt
    );
	// bus/memory wires
	// CPU(0) host
	wire req0;
	wire gnt0;
	wire hrd0;
    wire [31:0]a0;
    wire [31:0]d0;
    wire [3:0]web0;
    wire rd0;
    wire [31:0]spo0;
    wire ready0;
	// (1) host
	wire req1;
	wire gnt1;
	wire [31:0]a1;
	wire [31:0]d1;
	wire [3:0]web1;
	wire rd1;
	wire [31:0]spo1;
	wire ready1;
	// arb output(bottleneck)
    wire [31:0]a;
    wire [31:0]d;
    wire [3:0]web;
    wire rd;
    wire [31:0]spo;
    wire ready;
	// MMIO
	wire [31:0]mmio_a;
	wire [31:0]mmio_d;
	wire [3:0]mmio_web;
	wire mmio_rd;
	wire [31:0]mmio_spo;
	wire mmio_ready;
	// main memory
	wire [31:0]mem_a;
	wire [31:0]mem_d;
	wire [3:0]mem_web;
	wire mem_rd;
	wire [31:0]mem_spo;
	wire mem_ready;
	// physical memory
	wire mainm_burst_en;
	wire [7:0]mainm_burst_length;
	wire [31:0]mainm_a;
	wire [31:0]mainm_d;
	wire [3:0]mainm_web;
	wire mainm_rd;
	wire [31:0]mainm_spo;
	wire mainm_ready;

    wire clk_main;
	wire clk_mem;
	wire clk_2x;
    wire clk_hdmi_25;
    wire clk_hdmi_250;
	wire clk_ref;
// `ifndef SIMULATION
	mmcm_50_to_50 mmcm_50_to_50_inst(
        .resetn(1'b1),
		.clk_in1(sysclk),
		.clk_out1(clk_main),
        .locked()
		//.clk_mem(clk_mem),
		//.clk_hdmi_25(clk_hdmi_25),
		//.clk_hdmi_250(clk_hdmi_250),
		//.clk_hdmi_50(clk_2x),
		//.clk_ref(clk_ref)
	);
// `else
// 	assign clk_main = sysclk;
// `endif

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

    // reset signal
	wire manual_rst = sw_d[0];
	wire ui_clk_sync_rst;
	wire ddr_calib_complete;
    (*mark_debug = "true"*) wire rst = manual_rst | uart_rst | ui_clk_sync_rst;

    // bootrom 1024*32
	// TODO: 2 LSB problem: mmapper or here?
    wire [9:0]bootm_a;
	wire bootm_rd;
    wire [31:0]bootm_spo;
	wire bootm_ready;
	clocked_rom #(
		.WIDTH(32),
		.DEPTH(10),
//`ifndef SIMULATION
		.INIT("/home/petergu/quasiSoC/rtl/hart_transplant/openla500/firmware/start.dat")
//`else
		//.INIT("../firmware/bootrom/bootrom_sim.dat")
//`endif
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
		.INIT("/dev/null")
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
    wire gpio_rd;
    wire [31:0]gpio_spo;
	wire gpio_ready;
	wire irq_gpio;
`ifdef GPIO_EN
	gpio gpio_inst(
		.clk(clk_main),
		.rst(rst),

		.a(gpio_a),
		.d(gpio_d),
		.we(gpio_we),
		.spo(gpio_spo),

		.btn(btn_d),
		.sw(sw_d),
		.led(led),

		.irq(irq_gpio)
	);
	assign gpio_ready = 1;
`else
	assign gpio_spo = 0;
	assign gpio_ready = 1;
	assign led = 4'b0;
	assign irq_gpio = 0;
`endif


    // uart
    wire [2:0]uart_a;
    wire [31:0]uart_d;
    wire uart_we;
    wire uart_rd;
    wire [31:0]uart_spo;
    wire uart_ready;
	wire [7:0]sb_rxdata;
	wire sb_rxnew;
    wire irq_uart;
`ifdef UART_EN
	uart16550 #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.RESET_BAUD_RATE(BAUD_RATE_UART),
		.LENDIAN(1),
        //.FIFODEPTH(32),
		.SIM(SIMULATION)
	) uart_inst (
        .clk(clk_main),
		`ifdef UART_RST_EN
			// avoid UART reset dead lock
			.rst(manual_rst),
		`else
			.rst(rst),
		`endif

        .a(uart_a),
        .d(uart_d),
        .we(uart_we),
        .spo(uart_spo), 
		.rd(uart_rd),
		.ready(uart_ready),

        .tx(uart_tx),
        .rx(uart_rx),
        .irq(irq_uart),
	
	`ifdef INTERACTIVE_SIM
		.rxsim_en(uart_rxsim_en),
		.rxsim_data(uart_rxsim_data),
	`else
		.rxsim_en(0),
		.rxsim_data(0),
	`endif

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
        .rst(rst),

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

	// serial boot
	wire [2:0]sb_a;
	wire [31:0]sb_d;
	wire sb_we;
	wire sb_ready;
`ifdef SERIALBOOT_EN
	serialboot serialboot_inst(
		.clk(clk_main),
		.rst(rst),

		.s_a(sb_a),
		.s_d(sb_d),
		.s_we(sb_we),
		.s_ready(sb_ready),

		.m_req(req1),
		.m_gnt(gnt1),
		.m_a(a1),
		.m_d(d1),
		.m_we(we1),
		.m_rd(rd1),
		.m_spo(spo1),
		.m_ready(ready1),

		.uart_data(sb_rxdata),
		.uart_ready(sb_rxnew)
	);
`else
	assign req1 = 0;
	assign sb_ready = 1;
`endif

    // video
    wire [31:0]video_a;
    wire [31:0]video_d;
    wire video_we;
    wire [31:0]video_spo;
`ifdef VIDEO_EN
	mkrvidor4000_top mkrvidor4000_top_inst(
		.clk(clk_main),
		.clk_pix(clk_hdmi_25),
		.clk_tmds(clk_hdmi_250),
		.clk_2x(clk_2x),
		.rst(rst),

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
	`ifndef SIMULATION
		OBUFDS OBUFDS_red(
			.I(0),
			.O(TMDSp[2]),
			.OB(TMDSn[2])
		);
		OBUFDS OBUFDS_green(
			.I(0),
			.O(TMDSp[1]),
			.OB(TMDSn[1])
		);
		OBUFDS OBUFDS_blue(
			.I(0),
			.O(TMDSp[0]),
			.OB(TMDSn[0])
		);
		OBUFDS OBUFDS_clock(
			.I(0),
			.O(TMDSp_clock),
			.OB(TMDSn_clock)
		);
	`endif
	`ifdef LCD_EN
	lcd_ili9486 lcd_ili9486_inst(
		.clk(clk_main),
		.rst(rst),
		.a(video_a),
		.d(video_d),
		.we(video_we),
		.spo(video_spo),
		.lcd_d(lcd_d),
		.rd(lcd_rd),
		.wr(lcd_wr),
		.rs(lcd_rs),
		.cs(lcd_cs),
		.lcd_rst(lcd_rst)
	);
	`else
		assign video_spo = 0;
	`endif
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
		.rst(rst),

		.a(mem_a),
		.d(mem_d),
		.we(mem_we),
		.rd(mem_rd),
		.spo(mem_spo),
		.ready(mem_ready),

		.burst_en(mainm_burst_en),
		.burst_length(mainm_burst_length),
		.lowmem_a(mainm_a),
		.lowmem_d(mainm_d),
		.lowmem_we(mainm_web),
		.lowmem_rd(mainm_rd),
		.lowmem_spo(mainm_spo),
		.lowmem_ready(mainm_ready)
	);
`else
	assign mainm_burst_en = 1;
	assign mainm_burst_length = 1;
	assign mainm_a = mem_a;
	assign mainm_d = mem_d;
	assign mainm_web = mem_web;
	assign mainm_rd = mem_rd;
	assign mem_spo = mainm_spo;
	assign mem_ready = mainm_ready;
`endif

`ifdef PSRAM_EN
	`ifdef CACHE_EN
	memory_controller_burst memory_controller_inst
	//memory_controller memory_controller_inst
		(
		.clk(clk_main),
		.clk_mem(clk_ref),
		.rst(rst),

		.burst_en(mainm_burst_en),
		.burst_length(mainm_burst_length),

		.a(mainm_a),
		.d(mainm_d),
		.we(mainm_we),
		.rd(mainm_rd),
		.spo(mainm_spo),
		.ready(mainm_ready), 

		//.irq(mainm_irq),

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
		.rst(rst),

		.a(mainm_a),
		.d(mainm_d),
		.we(mainm_we),
		.rd(mainm_rd),
		.spo(mainm_spo),
		.ready(mainm_ready), 

		//.irq(mainm_irq),

		.psram_ce(psram_ce), 
		.psram_mosi(psram_mosi), 
		.psram_miso(psram_miso), 
		.psram_sio2(psram_sio2), 
		.psram_sio3(psram_sio3),
		.psram_sclk(psram_sclk)
	);
	`endif
`else
`ifdef DDR_EN
	// 1-bit wires are left implicitly declared
	wire [3:0]ddr_axi_awid;
	wire [28:0]ddr_axi_awaddr;
	wire [7:0]ddr_axi_awlen;
	wire [2:0]ddr_axi_awsize;
	wire [1:0]ddr_axi_awburst;
	wire [1:0]ddr_axi_awlock;
	wire [3:0]ddr_axi_awcache;
	wire [2:0]ddr_axi_awprot;
	wire [3:0]ddr_axi_awqos;
	wire [3:0]ddr_axi_wid;
	wire [31:0]ddr_axi_wdata;
	wire [3:0]ddr_axi_wstrb;
	wire [3:0]ddr_axi_bid;
	wire [1:0]ddr_axi_bresp;
	wire [3:0]ddr_axi_arid;
	wire [28:0]ddr_axi_araddr;
	wire [7:0]ddr_axi_arlen;
	wire [2:0]ddr_axi_arsize;
	wire [1:0]ddr_axi_arburst;
	wire [1:0]ddr_axi_arlock;
	wire [3:0]ddr_axi_arcache;
	wire [2:0]ddr_axi_arprot;
	wire [3:0]ddr_axi_arqos;
	wire [3:0]ddr_axi_rid;
	wire [31:0]ddr_axi_rdata;
	wire [1:0]ddr_axi_rresp;
	mm2axi4 #(
		.AXI4_IDLEN(4),
		.AXI4_ADDRLEN(28),
		.AXI4_DATALEN(32)
	) mm2axi4_ddr
	(
		.clk(clk_main),
		.rst(rst),

		.a(mainm_a),
		.d(mainm_d),
		.we(mainm_we),
		.rd(mainm_rd),
		.spo(mainm_spo),
		.ready(mainm_ready), 

		.m_axi_awid(ddr_axi_awid),
		.m_axi_awaddr(ddr_axi_awaddr),
		.m_axi_awlen(ddr_axi_awlen),
		.m_axi_awsize(ddr_axi_awsize),
		.m_axi_awburst(ddr_axi_awburst),
		.m_axi_awlock(ddr_axi_awlock),
		.m_axi_awcache(ddr_axi_awcache),
		.m_axi_awprot(ddr_axi_awprot),
		.m_axi_awqos(ddr_axi_awqos),
		.m_axi_awvalid(ddr_axi_awvalid),
		.m_axi_awready(ddr_axi_awready),

		.m_axi_wid(ddr_axi_wid),
		.m_axi_wdata(ddr_axi_wdata),
		.m_axi_wstrb(ddr_axi_wstrb),
		.m_axi_wlast(ddr_axi_wlast),
		.m_axi_wvalid(ddr_axi_wvalid),
		.m_axi_wready(ddr_axi_wready),

		.m_axi_bid(ddr_axi_bid),
		.m_axi_bready(ddr_axi_bready),
		.m_axi_bresp(ddr_axi_bresp),
		.m_axi_bvalid(ddr_axi_bvalid),

		.m_axi_arid(ddr_axi_arid),
		.m_axi_araddr(ddr_axi_araddr),
		.m_axi_arlen(ddr_axi_arlen),
		.m_axi_arsize(ddr_axi_arsize),
		.m_axi_arburst(ddr_axi_arburst),
		.m_axi_arlock(ddr_axi_arlock),
		.m_axi_arcache(ddr_axi_arcache),
		.m_axi_arprot(ddr_axi_arprot),
		.m_axi_arqos(ddr_axi_arqos),
		.m_axi_arvalid(ddr_axi_arvalid),
		.m_axi_arready(ddr_axi_arready),

		.m_axi_rid(ddr_axi_rid),
		.m_axi_rdata(ddr_axi_rdata),
		.m_axi_rready(ddr_axi_rready),
		.m_axi_rresp(ddr_axi_rresp),
		.m_axi_rlast(ddr_axi_rlast),
		.m_axi_rvalid(ddr_axi_rvalid),

		.irq(mainm_irq)
	);

	// TODO: proper reset!
	reg rst_ddr_auto = 0;
	reg [13:0]rst_ddr_auto_cnt = 0;
	always @ (posedge clk_mem) begin
		rst_ddr_auto_cnt <= rst_ddr_auto_cnt + 1;
		if (rst_ddr_auto_cnt == 2000) rst_ddr_auto <= 1;
	end

	mig_ddr3 mig_ddr3_inst(
		.ddr3_addr                      (ddr3_addr),
		.ddr3_ba                        (ddr3_ba),
		.ddr3_cas_n                     (ddr3_cas_n),
		.ddr3_ck_n                      (ddr3_ck_n),
		.ddr3_ck_p                      (ddr3_ck_p),
		.ddr3_cke                       (ddr3_cke),
		.ddr3_ras_n                     (ddr3_ras_n),
		.ddr3_reset_n                   (ddr3_reset_n),
		.ddr3_we_n                      (ddr3_we_n),
		.ddr3_dq                        (ddr3_dq),
		.ddr3_dqs_n                     (ddr3_dqs_n),
		.ddr3_dqs_p                     (ddr3_dqs_p),
		.init_calib_complete            (init_calib_complete),
		.ddr3_dm                        (ddr3_dm),
		.ddr3_odt                       (ddr3_odt),

		.sys_clk_i(clk_mem),
		.clk_ref_i(clk_ref),
		.ui_clk(clk_main),
		.ui_clk_sync_rst(ui_clk_sync_rst),
		.aresetn(!rst),
		.app_sr_req(0),
		.app_ref_req(0),
		.app_zq_req(0),

		.s_axi_awid(ddr_axi_awid),
		.s_axi_awaddr(ddr_axi_awaddr),
		.s_axi_awlen(ddr_axi_awlen),
		.s_axi_awsize(ddr_axi_awsize),
		.s_axi_awburst(ddr_axi_awburst),
		.s_axi_awlock(ddr_axi_awlock),
		.s_axi_awcache(ddr_axi_awcache),
		.s_axi_awprot(ddr_axi_awprot),
		.s_axi_awqos(ddr_axi_awqos),
		.s_axi_awvalid(ddr_axi_awvalid),
		.s_axi_awready(ddr_axi_awready),

		.s_axi_wdata(ddr_axi_wdata),
		.s_axi_wstrb(ddr_axi_wstrb),
		.s_axi_wlast(ddr_axi_wlast),
		.s_axi_wvalid(ddr_axi_wvalid),
		.s_axi_wready(ddr_axi_wready),

		.s_axi_bready(ddr_axi_bready),
		.s_axi_bid(ddr_axi_bid),
		.s_axi_bresp(ddr_axi_bresp),
		.s_axi_bvalid(ddr_axi_bvalid),

		.s_axi_arid(ddr_axi_arid),
		.s_axi_araddr(ddr_axi_araddr),
		.s_axi_arlen(ddr_axi_arlen),
		.s_axi_arsize(ddr_axi_arsize),
		.s_axi_arburst(ddr_axi_arburst),
		.s_axi_arlock(ddr_axi_arlock),
		.s_axi_arcache(ddr_axi_arcache),
		.s_axi_arprot(ddr_axi_arprot),
		.s_axi_arqos(ddr_axi_arqos),
		.s_axi_arvalid(ddr_axi_arvalid),
		.s_axi_arready(ddr_axi_arready),

		.s_axi_rready(ddr_axi_rready),
		.s_axi_rid(ddr_axi_rid),
		.s_axi_rdata(ddr_axi_rdata),
		.s_axi_rresp(ddr_axi_rresp),
		.s_axi_rlast(ddr_axi_rlast),
		.s_axi_rvalid(ddr_axi_rvalid),

		.sys_rst(rst_ddr_auto)
	);
`else
	assign ui_clk_sync_rst = 0;
	generate if (SIMULATION) begin
		// 2**27 * 32 64MB
		simple_ram #(
			.WIDTH(32),
			.DEPTH(27),
			.WEB(1),
			.INIT("/home/petergu/quasiSoC/rtl/hart_transplant/openla500/firmware/meminit.dat")
		) distram_mainm_sim (
			.clk(clk_main),
			.a({2'b0, mainm_a[31:2]}),
			.d(mainm_d),
			// .we(mainm_we),
			.web(mainm_web),
			.rd(mainm_rd),
			.spo(mainm_spo),
			.ready(mainm_ready)
		);
	end
	else begin
		// 2**14 * 32 64KB -- no external memory at all, use a small block ram as main memory
		simple_ram #(
			.WIDTH(32),
			.DEPTH(14),
			.WEB(1),
			.INIT("/dev/null")
		) distram_mainm_noextmem (
			.clk(clk_main),
			.a({2'b0, mainm_a[31:2]}),
			.d(mainm_d),
			// .we(mainm_we),
			.web(mainm_web),
			.rd(mainm_rd),
			.spo(mainm_spo),
			.ready(mainm_ready)
		);
	end
	endgenerate
		//wire [31:0]mainm_spo_l;
		//wire [31:0]mainm_spo_h;
		//wire mainm_ready_l;
		//wire mainm_ready_h;
		//assign mainm_spo = mainm_a[27] ? mainm_spo_h : mainm_spo_l;
		//assign mainm_ready = mainm_a[27] ? mainm_ready_h : mainm_ready_l;
		//// 2**27 * 32 64MB
		//simple_ram #(
			//.WIDTH(32),
			//.DEPTH(27),
			//.INIT("/tmp/meminit.dat")
		//) distram_mainm (
			//.clk(clk_main),
			//.a({2'b0, mainm_a[31:2]}),
			//.d(mainm_d),
			//.we(mainm_a[27] ? 1'b0 : mainm_we),
			//.rd(mainm_a[27] ? 1'b0 : mainm_rd),
			//.spo(mainm_spo_l),
			//.ready(mainm_ready_l)
		//);
		//// 2**27 * 32 64MB
		//simple_ram #(
			//.WIDTH(32),
			//.DEPTH(27),
			//.INIT("/tmp/meminit.dat")
		//) distram_mainmh (
			//.clk(clk_main),
			//.a({2'b0, mainm_a[31:2]}),
			//.d(mainm_d),
			//.we(mainm_a[27] ? mainm_we : 1'b0),
			//.rd(mainm_a[27] ? mainm_rd : 1'b0),
			//.spo(mainm_spo_h),
			//.ready(mainm_ready_h)
		//);
`endif
`endif

	// arbitrator, 0: cpu, 1: serialboot
	// arbitrator arb_inst (
	// 	.clk(clk_main),
	// 	.rst(rst),

	// 	.req0(req0),
	// 	.gnt0(gnt0),
	// 	.hrd0(hrd0),
	// 	.a0(a0),
	// 	.d0(d0),
	// 	.we0(we0),
	// 	.rd0(rd0),
	// 	.spo0(spo0),
	// 	.ready0(ready0),

	// 	.req1(req1),
	// 	.gnt1(gnt1),
	// 	.a1(a1),
	// 	.d1(d1),
	// 	.we1(we1),
	// 	.rd1(rd1),
	// 	.spo1(spo1),
	// 	.ready1(ready1),

	// 	.req2(0),

	// 	.req3(0),

	// 	.a(a),
	// 	.d(d),
	// 	.we(we),
	// 	.rd(rd),
	// 	.spo(spo),
	// 	.ready(ready)
	// );

	// loongson openla500
	wire [7:0]cpu_intrpt;
	// AXI4
	wire [3:0]arid;
	wire [31:0]araddr;
	wire [7:0]arlen;
	wire [2:0]arsize;
	wire [1:0]arburst;
	wire [1:0]arlock;
	wire [3:0]arcache;
	wire [2:0]arprot;
	wire arvalid;
	wire arready;
	wire [3:0]rid;
	wire [31:0]rdata;
	wire [1:0]rresp;
	wire rlast;
	wire rvalid;
	wire rready;
	wire [3:0]awid;
	wire [31:0]awaddr;
	wire [7:0]awlen;
	wire [2:0]awsize;
	wire [1:0]awburst;
	wire [1:0]awlock;
	wire [3:0]awcache;
	wire [2:0]awprot;
	wire awvalid;
	wire awready;
	wire [3:0]wid;
	wire [31:0]wdata;
	wire [3:0]wstrb;
	wire wlast;
	wire wvalid;
	wire wready;
	wire [3:0]bid;
	wire [1:0]bresp;
	wire bvalid;
	wire bready;
	// AXI-lite
	wire [31:0]m_axi_awaddr;
	wire [2:0]m_axi_awprot;
	wire m_axi_awvalid;
	wire m_axi_awready;
	wire [31:0]m_axi_wdata;
	wire [3:0]m_axi_wstrb;
	wire m_axi_wvalid;
	wire m_axi_wready;
	wire [1:0]m_axi_bresp;
	wire m_axi_bvalid;
	wire m_axi_bready;
	wire [31:0]m_axi_araddr;
	wire [2:0]m_axi_arprot;
	wire m_axi_arvalid;
	wire m_axi_arready;
	wire m_axi_rvalid;
	wire m_axi_rready;
	wire [31:0]m_axi_rdata;
	wire [1:0]m_axi_rresp;
	// interrupt mapping, specify in device tree
	assign cpu_intrpt = {6'b0, irq_uart, 1'b0};
	// BRAM-like bus
	core_top #(.TLBNUM(TLBNUM)) core_top_inst (
		.aclk(clk_main),
		.aresetn(~rst),
		.intrpt(cpu_intrpt),
		.arid(arid),
		.araddr(araddr),
		.arlen(arlen),
		.arsize(arsize),
		.arburst(arburst),
		.arlock(arlock),
		.arcache(arcache),
		.arprot(arprot),
		.arvalid(arvalid),
		.arready(arready),
		.rid(rid),
		.rdata(rdata),
		.rresp(rresp),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),
		.awid(awid),
		.awaddr(awaddr),
		.awlen(awlen),
		.awsize(awsize),
		.awburst(awburst),
		.awlock(awlock),
		.awcache(awcache),
		.awprot(awprot),
		.awvalid(awvalid),
		.awready(awready),
		.wid(wid),
		.wdata(wdata),
		.wstrb(wstrb),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		.bid(bid),
		.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready),
		.break_point(1'b0),
		.infor_flag(1'b0),
		.reg_num(5'b0),
		.ws_valid(),
		.rf_rdata(),
		.debug0_wb_pc(),
		.debug0_wb_rf_wen(),
		.debug0_wb_rf_wnum(),
		.debug0_wb_rf_wdata(),
		.debug0_wb_inst()
	);
	// soc_axi_sram_bridge #(
	// 	.BUS_WIDTH(32),
	// 	.DATA_WIDTH(32),
	// 	.CPU_WIDTH(32)
	// ) soc_axi_sram_bridge_inst(
	// 	.aclk(clk_main),
	// 	.aresetn(~rst),
	// 	.ram_raddr(a0),
	// 	.ram_rdata(32'h001503c6),
	// 	.ram_ren(rd0),
	// 	.ram_waddr(a0),
	// 	.ram_wdata(d0),
	// 	.ram_wen(we0),
	// 	.m_araddr(araddr),
	// 	.m_arburst(arburst),
	// 	.m_arcache(arcache),
	// 	.m_arid(arid),
	// 	.m_arlen(arlen),
	// 	.m_arlock(arlock),
	// 	.m_arprot(arprot),
	// 	.m_arready(arready),
	// 	.m_arsize(arsize),
	// 	.m_arvalid(arvalid),
	// 	.m_awaddr(awaddr),
	// 	.m_awburst(awburst),
	// 	.m_awcache(awcache),
	// 	.m_awid(awid),
	// 	.m_awlen(awlen),
	// 	.m_awlock(awlock),
	// 	.m_awprot(awprot),
	// 	.m_awready(awready),
	// 	.m_awsize(awsize),
	// 	.m_awvalid(awvalid),
	// 	.m_bid(bid),
	// 	.m_bready(bready),
	// 	.m_bresp(bresp),
	// 	.m_bvalid(bvalid),
	// 	.m_rdata(rdata),
	// 	.m_rid(rid),
	// 	.m_rlast(rlast),
	// 	.m_rready(rready),
	// 	.m_rresp(rresp),
	// 	.m_rvalid(rvalid),
	// 	.m_wdata(wdata),
	// 	.m_wstrb(wstrb),
	// 	.m_wlast(wlast),
	// 	.m_wvalid(wvalid),
	// 	.m_wready(wready),
	// 	.m_wid(wid)
	// );

	axi2axilite #(
		.C_AXI_ID_WIDTH(4),
		.C_AXI_DATA_WIDTH(32),
		.C_AXI_ADDR_WIDTH(32),
		.OPT_WRITES(1),
		.OPT_READS(1),
		.OPT_LOWPOWER(0),
		.LGFIFO(4)
	) axi2axilite_inst(
		.S_AXI_ACLK(clk_main),
		.S_AXI_ARESETN(~rst),
		.S_AXI_AWVALID(awvalid),
		.S_AXI_AWREADY(awready),
		.S_AXI_AWID(awid),
		.S_AXI_AWADDR(awaddr),
		.S_AXI_AWLEN(awlen),
		.S_AXI_AWSIZE(awsize),
		.S_AXI_AWBURST(awburst),
		.S_AXI_AWLOCK(awlock),
		.S_AXI_AWCACHE(awcache),
		.S_AXI_AWPROT(awprot),
		.S_AXI_AWQOS(),
		.S_AXI_WVALID(wvalid),
		.S_AXI_WREADY(wready),
		.S_AXI_WDATA(wdata),
		.S_AXI_WSTRB(wstrb),
		.S_AXI_WLAST(wlast),
		.S_AXI_BREADY(bready),
		.S_AXI_BVALID(bvalid),
		.S_AXI_BID(bid),
		.S_AXI_BRESP(bresp),
		.S_AXI_ARVALID(arvalid),
		.S_AXI_ARREADY(arready),
		.S_AXI_ARID(arid),
		.S_AXI_ARADDR(araddr),
		.S_AXI_ARLEN(arlen),
		.S_AXI_ARSIZE(arsize),
		.S_AXI_ARBURST(arburst),
		.S_AXI_ARLOCK(arlock),
		.S_AXI_ARCACHE(arcache),
		.S_AXI_ARPROT(arprot),
		.S_AXI_ARQOS(),
		.S_AXI_RVALID(rvalid),
		.S_AXI_RREADY(rready),
		.S_AXI_RID(rid),
		.S_AXI_RDATA(rdata),
		.S_AXI_RRESP(rresp),
		.S_AXI_RLAST(rlast),
		.M_AXI_AWADDR(m_axi_awaddr),
		.M_AXI_AWPROT(m_axi_awprot),
		.M_AXI_AWVALID(m_axi_awvalid),
		.M_AXI_AWREADY(m_axi_awready),
		.M_AXI_WDATA(m_axi_wdata),
		.M_AXI_WSTRB(m_axi_wstrb),
		.M_AXI_WVALID(m_axi_wvalid),
		.M_AXI_WREADY(m_axi_wready),
		.M_AXI_BRESP(m_axi_bresp),
		.M_AXI_BVALID(m_axi_bvalid),
		.M_AXI_BREADY(m_axi_bready),
		.M_AXI_ARADDR(m_axi_araddr),
		.M_AXI_ARPROT(m_axi_arprot),
		.M_AXI_ARVALID(m_axi_arvalid),
		.M_AXI_ARREADY(m_axi_arready),
		.M_AXI_RVALID(m_axi_rvalid),
		.M_AXI_RREADY(m_axi_rready),
		.M_AXI_RDATA(m_axi_rdata),
		.M_AXI_RRESP(m_axi_rresp)
	);
	axil2mm axil2mm_inst(
		.s_axi_clk(clk_main),
		.s_axi_aresetn(~rst),
		.s_axi_awaddr(m_axi_awaddr),
		.s_axi_awvalid(m_axi_awvalid),
		.s_axi_awready(m_axi_awready),
		.s_axi_wdata(m_axi_wdata),
		.s_axi_wstrb(m_axi_wstrb),
		.s_axi_wvalid(m_axi_wvalid),
		.s_axi_wready(m_axi_wready),
		.s_axi_bresp(m_axi_bresp),
		.s_axi_bvalid(m_axi_bvalid),
		.s_axi_bready(m_axi_bready),
		.s_axi_araddr(m_axi_araddr),
		.s_axi_arvalid(m_axi_arvalid),
		.s_axi_arready(m_axi_arready),
		.s_axi_rdata(m_axi_rdata),
		.s_axi_rvalid(m_axi_rvalid),
		.s_axi_rready(m_axi_rready),
		.s_axi_rresp(m_axi_rresp),
		.a(a),
		// .d({d0[31:28], d0[27:20], d0[15:8], d0[7:0]}),
		.d(d),
		.rd(rd),
		.web(web),
		// .spo({spo0[31:28], spo0[27:20], spo0[15:8], spo0[7:0]}),
		.spo(spo),
		.ready(ready)
		// .req(req0), // unsupported now, assume always granted
		// .gnt(gnt0),
		// .hrd(hrd0)
	);

	highmapper highmapper_inst (
		.a(a),
		.d(d),
		.web(web),
		.rd(rd),
		.spo(spo),
		.ready(ready),

        .mem_a(mem_a),
        .mem_d(mem_d),
        .mem_web(mem_web),
        .mem_rd(mem_rd),
        .mem_spo(mem_spo),
        .mem_ready(mem_ready),

        .mmio_a(mmio_a),
        .mmio_d(mmio_d),
        .mmio_web(mmio_web),
        .mmio_rd(mmio_rd),
        .mmio_spo(mmio_spo),
        .mmio_ready(mmio_ready)
	);

	lowmapper lowmapper_inst(
		.clk(clk_main),
		.rst(rst),

        .a(mmio_a),
        .d(mmio_d),
        .web(mmio_web),
        .rd(mmio_rd),
        .spo(mmio_spo),
        .ready(mmio_ready),

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

		//.cache_a(cache_a),
		//.cache_d(cache_d),
		//.cache_we(cache_we),
		//.cache_rd(cache_rd),
		//.cache_spo(cache_spo),
		//.cache_ready(cache_ready),

        .gpio_spo(gpio_spo),
        .gpio_a(gpio_a),
        .gpio_d(gpio_d),
        .gpio_we(gpio_we),
        .gpio_rd(gpio_rd),
		.gpio_ready(gpio_ready),

        .uart_spo(uart_spo),
        .uart_a(uart_a),
        .uart_d(uart_d),
        .uart_we(uart_we),
		.uart_rd(uart_rd),
		.uart_ready(uart_ready),

        .video_spo(video_spo),
        .video_a(video_a),
        .video_d(video_d),
        .video_we(video_we),

        .sd_spo(sd_spo),
        .sd_a(sd_a),
        .sd_d(sd_d),
        .sd_we(sd_we),

        .usb_spo(0),
        .usb_a(),
        .usb_d(),
        .usb_we(),

        // .int_spo(int_spo),
        // .int_a(int_a),
        // .int_d(int_d),
        // .int_we(int_we),

        .sb_a(sb_a),
        .sb_d(sb_d),
        .sb_we(sb_we),
		.sb_ready(sb_ready),

		.ps2_spo(ps2_spo),

		// .t_a(aclint_a),
		// .t_d(aclint_d),
		// .t_we(aclint_we),
		// .t_spo(aclint_spo),

		.eth_a(eth_a),
		.eth_d(eth_d),
		.eth_we(eth_we),
		.eth_spo(eth_spo),

        .irq()
    );
endmodule
