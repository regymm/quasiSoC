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
		parameter CLOCK_FREQ = 62500000,
		//parameter CLOCK_FREQ = 75000000,
		parameter BAUD_RATE_UART = 1843200,
		//parameter BAUD_RATE_UART = 3686400,
		parameter BAUD_RATE_CH375 = 9600,
		//parameter TIMER_COUNTER = 4000 // for debugging
		parameter TIMER_COUNTER = 1000000
	)
    (
        input sysclk,
        
        input [1:0]sw,
        input [1:0]btn,
        output [3:0]led,

		output psram_ce,
		inout psram_mosi, 
		inout psram_miso, 
		inout psram_sio2,
		inout psram_sio3,
		output psram_sclk,

        input uart_rx,
        output uart_tx,

		//input uart_rx_2,
		//output uart_tx_2,

        input sd_ncd,
        input sd_wp,
        input sd_dat0,
        output sd_dat1,
        output sd_dat2,
        output sd_dat3,
        output sd_cmd,
        output sd_sck,

		input ch375_tx,
		output ch375_rx,
		input ch375_nint,

		input ps2_clk,
		input ps2_data,

		input eth_intn,
		output eth_rstn,
		output eth_sclk,
		output eth_scsn,
		output eth_mosi,
		input eth_miso,

        output [2:0]TMDSp,
        output [2:0]TMDSn,
        output TMDSp_clock,
        output TMDSn_clock,

		output [7:0]lcd_d,
		output lcd_rd,
		output lcd_wr,
		output lcd_rs,
		output lcd_cs,
		output lcd_rst,

		input p1p,
		input p1n,
		input p3p,
		input p3n,
		input p2p,
		input p2n,
		input p4p,
		input p4n
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

	(*mark_debug = "true"*)reg [7:0]probe;
	always @ (posedge clk_main) begin
		probe <= {p1p, p1n, p3p, p3n, p2p, p2n, p4p, p4n};
	end

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
    (*mark_debug = "true"*) wire rst = manual_rst | uart_rst;

    // bootrom 1024*32
	// TODO: 2 LSB problem: mmapper or here?
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
	assign sb_ready = 1;
	assign a_mem = mainm_a_c;
	assign d_mem = mainm_d_c;
	assign we_mem = mainm_we_c;
	assign spo_mem = mainm_spo_c;
	assign rd_mem = mainm_rd_c;
	assign ready_mem = mainm_ready_c;
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
	// 2**14 * 32 64KB -- have to be w/o cache and ...
	simple_ram #(
		.WIDTH(32),
		.DEPTH(14),
		.INIT("/home/petergu/MyHome/quasiSoC/rtl/null.dat")
	) distram_mainm (
        .clk(clk_main),
        .a({2'b0, mainm_a[31:2]}),
        .d(mainm_d),
        .we(mainm_we),
		.rd(mainm_rd),
        .spo(mainm_spo),
		.ready(mainm_ready)
    );
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
    aclint #(.TIMER_COUNTER(TIMER_COUNTER)) aclint_inst(
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
	riscv_multicyc riscv_multicyc_inst(
		.clk(clk_main),
		.rst(rst),

		.tip(irq_timer_pending),
		.sip(irq_soft_pending),
		.eip(cpu_eip),
		.eip_reply(cpu_eip_reply),

		.req(req0),
		.gnt(gnt0),
		.hrd(hrd0),
		.a(a0),
		.d(d0),
		.we(we0),
		.rd(rd0),
		.spo(spo0),
		.ready(ready0)
	);

    //// MMU
    //wire [31:0]vspo;
    //wire vready;
    //wire virq;
    //wire [31:0]va;
    //wire [31:0]vd;
    //wire vwe;
    //wire vrd;
//`ifdef MMU_EN
    //mmu mmu_inst(
        //.clk(clk_main),
        //.rst(rst),

        //.ring(ring),

        //.va(va),
        //.vd(vd),
        //.vwe(vwe),
        //.vrd(vrd),
        //.vspo(vspo),
        //.vready(vready),
        //.virq(virq), // nc

        //.pspo(spo0),
        //.pready(ready0),
        //.pa(a0),
        //.pd(d0),
        //.pwe(we0),
        //.prd(rd0)
    //);
//`else
	//assign virq = 0;
	//assign a0 = va;
	//assign d0 = vd;
	//assign we0 = vwe;
	//assign rd0 = vrd;
	//assign spo0 = vspo;
	//assign ready0 = vready;
//`endif
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
