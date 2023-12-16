/**
 * File              : quasi_main.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.11.25
 * Last Modified Date: 2022.07.13
 */
`timescale 1ns / 1ps
`include "quasi.vh"

module quasi_main 
	#(
		parameter SIMULATION = 0,
		parameter INTERACTIVE_SIM = 0,
		parameter CLOCK_FREQ = 100000000,
		//parameter CLOCK_FREQ = 75000000,
		parameter BAUD_RATE_UART = 3000000,
		//parameter BAUD_RATE_UART = 3686400,
		//parameter BAUD_RATE_CH375 = 9600,
		parameter TIMER_RATE = 10000000
	)
    (
        input sysclk,
        
        input [1:0]sw,
        input [1:0]btn,
        output [3:0]led,

		//output psram_ce,
		//inout psram_mosi, 
		//inout psram_miso, 
		//inout psram_sio2,
		//inout psram_sio3,
		//output psram_sclk,

        input uart_rx,
        output uart_tx,
	`ifdef INTERACTIVE_SIM
		input uart_rxsim_en,
		input [7:0]uart_rxsim_data,
	`endif

		//input uart_rx_2,
		//output uart_tx_2,

        input sd_ncd,
        input sd_dat0,
        output sd_dat1,
        output sd_dat2,
        output sd_dat3,
        output sd_cmd,
        output sd_sck,

		//input ps2_clk,
		//input ps2_data,

		//input eth_intn,
		//output eth_rstn,
		//output eth_sclk,
		//output eth_scsn,
		//output eth_mosi,
		//input eth_miso,

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

		//output [7:0]lcd_d,
		//output lcd_rd,
		//output lcd_wr,
		//output lcd_rs,
		//output lcd_cs,
		//output lcd_rst,

		//input p1p,
		//input p1n,
		//input p3p,
		//input p3n,
		//input p2p,
		//input p2n,
		//input p4p,
		//input p4n
    );
	// bus/memory wires
	// CPU(0) host
	wire req0;
	wire gnt0;
	wire hrd0;
    wire [31:0]a0;
    wire [31:0]d0;
    wire we0;
    wire rd0;
    wire [31:0]spo0;
    wire ready0;
	// (1) host
	wire req1;
	wire gnt1;
	wire [31:0]a1;
	wire [31:0]d1;
	wire we1;
	wire rd1;
	wire [31:0]spo1;
	wire ready1;
	// arb output(bottleneck)
    wire [31:0]a;
    wire [31:0]d;
    wire we;
    wire rd;
    wire [31:0]spo;
    wire ready;
	// MMIO
	wire [31:0]mmio_a;
	wire [31:0]mmio_d;
	wire mmio_we;
	wire mmio_rd;
	wire [31:0]mmio_spo;
	wire mmio_ready;
	// main memory
	wire [31:0]mem_a;
	wire [31:0]mem_d;
	wire mem_we;
	wire mem_rd;
	wire [31:0]mem_spo;
	wire mem_ready;
	// physical memory
	wire mainm_burst_en;
	wire [7:0]mainm_burst_length;
	wire [31:0]mainm_a;
	wire [31:0]mainm_d;
	wire mainm_we;
	wire mainm_rd;
	wire [31:0]mainm_spo;
	wire mainm_ready;

    wire clk_main;
	wire clk_mem;
	wire clk_2x;
    wire clk_hdmi_25;
    wire clk_hdmi_250;
`ifndef SIMULATION
	clocking_wizard clock_wizard_inst(
		.clk_in1(sysclk),
		.clk_main(),
		.clk_mem(clk_mem),
		.clk_hdmi_25(clk_hdmi_25),
		.clk_hdmi_250(clk_hdmi_250),
		.clk_hdmi_50(clk_2x)
	);
`else
	assign clk_main = sysclk;
`endif
	//clocking_xc7 clocking_xc7_inst (
		//.clk_50(sysclk),
		//.clk1_62d5(clk_main),
		//.clk2_125(clk_mem),
		//.clk3_25(clk_hdmi_25),
		//.clk4_250(clk_hdmi_250),
		//.clk5_50(clk_2x)
	//);

	//(*mark_debug = "true"*)reg [7:0]probe;
	//always @ (posedge clk_main) begin
		//probe <= {p1p, p1n, p3p, p3n, p2p, p2n, p4p, p4n};
	//end

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
`ifndef SIMULATION
		.INIT("/home/petergu/quasiSoC/firmware/bootrom/bootrom.dat")
`else
		.INIT("/home/petergu/quasiSoC/firmware/bootrom/bootrom_sim.dat")
`endif
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
		.INIT("/home/petergu/quasiSoC/sim/zeros.dat")
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
	`ifdef AXI_GPIO_TEST
	wire [8:0]gpio_axi_araddr;
	wire [8:0]gpio_axi_awaddr;
	wire [1:0]gpio_axi_bresp;
	wire [31:0]gpio_axi_rdata;
	wire [1:0]gpio_axi_rresp;
	wire [31:0]gpio_axi_wdata;
	wire [3:0]gpio_axi_wstrb;
	axi_gpio_0 axi_gpio_inst(
		.gpio_io_i({28'b0, sw_d, btn_d}),
		.gpio_io_o(led),
		.gpio_io_t(),

		.s_axi_araddr(gpio_axi_araddr),
		.s_axi_arready(gpio_axi_arready),
		.s_axi_arvalid(gpio_axi_arvalid),
		.s_axi_awaddr(gpio_axi_awaddr),
		.s_axi_awready(gpio_axi_awready),
		.s_axi_awvalid(gpio_axi_awvalid),
		.s_axi_bready(gpio_axi_bready),
		.s_axi_bresp(gpio_axi_bresp),
		.s_axi_bvalid(gpio_axi_bvalid),
		.s_axi_rdata(gpio_axi_rdata),
		.s_axi_rready(gpio_axi_rready),
		.s_axi_rresp(gpio_axi_rresp),
		.s_axi_rvalid(gpio_axi_rvalid),
		.s_axi_wdata(gpio_axi_wdata),
		.s_axi_wstrb(gpio_axi_wstrb),
		.s_axi_wvalid(gpio_axi_wvalid),
		.s_axi_wready(gpio_axi_wready),

		.s_axi_aclk(clk_main),
		.s_axi_aresetn(!rst)
	);

	mm2axi4 mm2axi4_gpio_inst (
		.clk(clk_main),
		.rst(rst),

		.a({26'b0, gpio_a, 2'b0}),
		.d(gpio_d),
		.we(gpio_we),
		.rd(gpio_rd),
		.spo(gpio_spo),
		.ready(gpio_ready),

		.m_axi_awaddr(gpio_axi_awaddr),
		.m_axi_awvalid(gpio_axi_awvalid),
		.m_axi_awready(gpio_axi_awready),

		.m_axi_wdata(gpio_axi_wdata),
		.m_axi_wstrb(gpio_axi_wstrb),
		.m_axi_wvalid(gpio_axi_wvalid),
		.m_axi_wready(gpio_axi_wready),

		.m_axi_bready(gpio_axi_bready),
		.m_axi_bresp(gpio_axi_bresp),
		.m_axi_bvalid(gpio_axi_bvalid),

		.m_axi_araddr(gpio_axi_araddr),
		.m_axi_arvalid(gpio_axi_arvalid),
		.m_axi_arready(gpio_axi_arready),

		.m_axi_rdata(gpio_axi_rdata),
		.m_axi_rready(gpio_axi_rready),
		.m_axi_rresp(gpio_axi_rresp),
		.m_axi_rvalid(gpio_axi_rvalid)
	);
	`else
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
	`endif
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
    wire [31:0]uart_spo;
	wire [7:0]sb_rxdata;
	wire sb_rxnew;
    wire irq_uart;
`ifdef UART_EN
`ifndef INTERACTIVE_SIM
	uart_new #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE_UART)
	) uart_inst (
        .clk(clk_main),
		`ifdef UART_RST_EN
			// avoid UART reset dead lock
			.rst(manual_rst),
		`else
			.rst(rst),
		`endif

        .tx(uart_tx),
        .rx(uart_rx),

        .a(uart_a),
        .d(uart_d),
        .we(uart_we),
        .spo(uart_spo), 

        .irq(irq_uart),

		.rxnew(sb_rxnew),
		.rxdata(sb_rxdata)
    );
`else
	uart_sim uart_sim_inst (
        .clk(clk_main),
		`ifdef UART_RST_EN
			// avoid UART reset dead lock
			.rst(manual_rst),
		`else
			.rst(rst),
		`endif

        .tx(uart_tx),
        .rx(uart_rx),
		.rxsim_en(uart_rxsim_en),
		.rxsim_data(uart_rxsim_data),

        .a(uart_a),
        .d(uart_d),
        .we(uart_we),
        .spo(uart_spo), 

        .irq(irq_uart),

		.rxnew(sb_rxnew),
		.rxdata(sb_rxdata)
    );
`endif
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
		.rst(rst),

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
		.lowmem_we(mainm_we),
		.lowmem_rd(mainm_rd),
		.lowmem_spo(mainm_spo),
		.lowmem_ready(mainm_ready)
	);
`else
	assign mainm_burst_en = 1;
	assign mainm_burst_length = 1;
	assign mainm_a = mem_a;
	assign mainm_d = mem_d;
	assign mainm_we = mem_we;
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
		.clk_mem(clk_mem),
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
	`ifndef SIMULATION
		// 2**14 * 32 64KB -- have to be w/o cache and ...
		simple_ram #(
			.WIDTH(32),
			.DEPTH(14),
			.INIT("/home/petergu/quasiSoC/rtl/null.dat")
		) distram_mainm (
			.clk(clk_main),
			.a({2'b0, mainm_a[31:2]}),
			.d(mainm_d),
			.we(mainm_we),
			.rd(mainm_rd),
			.spo(mainm_spo),
			.ready(mainm_ready)
		);
	`else
		// 2**27 * 32 64MB
		simple_ram #(
			.WIDTH(32),
			.DEPTH(27),
			.INIT("/tmp/meminit.dat")
		) distram_mainm (
			.clk(clk_main),
			.a({2'b0, mainm_a[31:2]}),
			.d(mainm_d),
			.we(mainm_we),
			.rd(mainm_rd),
			.spo(mainm_spo),
			.ready(mainm_ready)
		);
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
`endif

    // interrupt
    wire cpu_eip;
    wire cpu_eip_reply;
    wire irq_timer_pending;
    wire irq_soft_pending;

	wire [15:0]aclint_a;
	wire [31:0]aclint_d;
	wire aclint_we;
	wire [31:0]aclint_spo;

    wire [2:0]int_a;
    wire [31:0]int_d;
    wire int_we;
    wire [31:0]int_spo;
`ifdef IRQ_EN
    // RISC-V advanced core-local interrupt controller
    aclint #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.TIMER_RATE(TIMER_RATE)
	) aclint_inst(
        .clk(clk_main),
        .rst(rst),
		
		.s_irq(irq_soft_pending),
        .t_irq(irq_timer_pending),

		.a(aclint_a),
		.d(aclint_d),
		.we(aclint_we),
		.spo(aclint_spo)
    );

    interrupt_unit interrupt_unit_inst(
        .clk(clk_main),
        .rst(rst),

        .interrupt(cpu_eip),
        .int_reply(cpu_eip_reply),

        .i_uart(irq_uart),
        .i_gpio(irq_gpio),
		.i_ps2(irq_ps2),

        .a(int_a),
        .d(int_d),
        .we(int_we),
        .spo(int_spo)
    );
`else
	assign irq_timer_pending = 0;
	assign irq_soft_pending = 0;
	assign cpu_eip = 0;
	assign int_spo = 0;
	assign aclint_spo = 0;
`endif

	// arbitrator
	arbitrator arb_inst (
		.clk(clk_main),
		.rst(rst),

		.req0(req0),
		.gnt0(gnt0),
		.hrd0(hrd0),
		.a0(a0),
		.d0(d0),
		.we0(we0),
		.rd0(rd0),
		.spo0(spo0),
		.ready0(ready0),

		.req1(req1),
		.gnt1(gnt1),
		.a1(a1),
		.d1(d1),
		.we1(we1),
		.rd1(rd1),
		.spo1(spo1),
		.ready1(ready1),

		.req2(0),

		.req3(0),

		.a(a),
		.d(d),
		.we(we),
		.rd(rd),
		.spo(spo),
		.ready(ready)
	);

    // cpu-multi-cycle
	wire [1:0]mode;
	wire paging;
	wire [21:0]root_ppn;
	wire pagefault;
	wire accessfault;
	riscv_multicyc riscv_multicyc_inst(
		.clk(clk_main),
		.rst(rst),

		.tip(irq_timer_pending),
		.eip(cpu_eip),
		.eip_reply(cpu_eip_reply),

		.mode(mode),
		.paging(paging),
		.root_ppn(root_ppn),
		.pagefault(pagefault),
		.accessfault(accessfault),

		.req(vreq),
		.gnt(vgnt),
		.hrd(vhrd),
		.a(va),
		.d(vd),
		.we(vwe),
		.rd(vrd),
		.spo(vspo),
		.ready(vready)
	);

	// MMU
	wire vreq;
	wire vgnt;
	wire vhrd;
	wire [31:0]vspo;
	wire vready;
	wire virq;
	wire [31:0]va;
	wire [31:0]vd;
	wire vwe;
	wire vrd;
	// IRQ_EN must be defined also
`ifdef MMU_EN
	mmu_sv32 mmu_inst(
		.clk(clk_main),
		.rst(rst),

		.mode(mode),
		.paging(paging),
		.root_ppn(root_ppn),

		.vreq(vreq),
		.vgnt(vgnt),
		.vhrd(vhrd),
		.va(va),
		.vd(vd),
		.vwe(vwe),
		.vrd(vrd),
		.vspo(vspo),
		.vready(vready),
		//.virq(virq), // nc

		.preq(req0),
		.pgnt(gnt0),
		.phrd(hrd0),
		.pa(a0),
		.pd(d0),
		.pwe(we0),
		.prd(rd0),
		.pspo(spo0),
		.pready(ready0),

		.pagefault(pagefault),
		.accessfault(accessfault)
	);
`else
	assign req0 = vreq;
	assign vgnt = gnt0;
	assign vhrd = hrd0;
	assign a0 = va;
	assign d0 = vd;
	assign we0 = vwe;
	assign rd0 = vrd;
	assign vspo = spo0;
	assign vready = ready0;
	assign virq = 0;
	assign pagefault = 0;
	assign accessfault = 0;
`endif

	highmapper highmapper_inst (
		.a(a),
		.d(d),
		.we(we),
		.rd(rd),
		.spo(spo),
		.ready(ready),

        .mem_a(mem_a),
        .mem_d(mem_d),
        .mem_we(mem_we),
        .mem_rd(mem_rd),
        .mem_spo(mem_spo),
        .mem_ready(mem_ready),

        .mmio_a(mmio_a),
        .mmio_d(mmio_d),
        .mmio_we(mmio_we),
        .mmio_rd(mmio_rd),
        .mmio_spo(mmio_spo),
        .mmio_ready(mmio_ready)
	);

	lowmapper lowmapper_inst(
		.clk(clk_main),
		.rst(rst),

        .a(mmio_a),
        .d(mmio_d),
        .we(mmio_we),
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

        .video_spo(video_spo),
        .video_a(video_a),
        .video_d(video_d),
        .video_we(video_we),

        .sd_spo(sd_spo),
        .sd_a(sd_a),
        .sd_d(sd_d),
        .sd_we(sd_we),

        .usb_spo(usb_spo),
        .usb_a(usb_a),
        .usb_d(usb_d),
        .usb_we(usb_we),

        .int_spo(int_spo),
        .int_a(int_a),
        .int_d(int_d),
        .int_we(int_we),

        .sb_a(sb_a),
        .sb_d(sb_d),
        .sb_we(sb_we),
        .sb_spo(sb_spo),
		.sb_ready(sb_ready),

		.ps2_spo(ps2_spo),

		.t_a(aclint_a),
		.t_d(aclint_d),
		.t_we(aclint_we),
		.t_spo(aclint_spo),

		.eth_a(eth_a),
		.eth_d(eth_d),
		.eth_we(eth_we),
		.eth_spo(eth_spo),

        .irq(pirq)
    );
endmodule
