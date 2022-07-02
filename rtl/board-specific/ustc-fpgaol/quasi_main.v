/**
 * File              : quasi_main.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.11.25
 * Last Modified Date: 2022.06.17
 */
`timescale 1ns / 1ps
// For Nexsy 4 DDR @ FPGAOL
`include "quasi.vh"
//`define SIMULATION

module quasi_main 
	#(
		//parameter CLOCK_FREQ = 62500000,
		parameter CLOCK_FREQ = 100000000,
		parameter BAUD_RATE_UART = 115200, // may misbehave if modified
		parameter BAUD_RATE_CH375 = 9600,
		//parameter TIMER_COUNTER = 4000 // for debugging
		parameter TIMER_COUNTER = 1000000,
		parameter SIMULATION = "FALSE"
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
		output uart_rx_led,

		inout [15:0]ddr2_dq,
		inout [1:0]ddr2_dqs_n,
		inout [1:0]ddr2_dqs_p,
		output [12:0]ddr2_addr,
		output [2:0]ddr2_ba,
		output ddr2_ras_n,
		output ddr2_cas_n,
		output ddr2_we_n,
		output ddr2_ck_p,
		output ddr2_ck_n,
		output ddr2_cke,
		output ddr2_cs_n,
		output [1:0]ddr2_dm,
		output ddr2_odt
    );

	assign cts = 0;
	assign rts_led = rts;
	assign uart_tx_led = uart_tx;
	assign uart_rx_led = uart_rx;

    wire clk_main; // coming from MIG
	wire clk_mem; // 200 MHz for MIG
	clk_wiz_0 clk_wiz_0_inst(
		.clk_in1(sysclk),
		//.clk_main(clk_main),
		.clk_mem(clk_mem)
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
        .i_btn(btn),
        .o_state(btn_d)
    );

    // reset signal
	wire manual_rst = sw_d[0];
	wire ui_clk_sync_rst;
	wire ddr_calib_complete;
	(*mark_debug = "true"*) wire rst = manual_rst | uart_rst | ui_clk_sync_rst;
    //(*mark_debug = "true"*) wire rst = manual_rst | uart_rst | ui_clk_sync_rst | !ddr_calib_complete;

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
	wire rst_aclint;
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
		.rst_timer(rst_aclint),
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
	uart_new #(
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
	assign sd_spo = {7'b0, 1'b1, 24'b0}; // indicate SD not deteced
	assign irq_sd = 0;
	assign sd_dat1 = 1'bZ;
	assign sd_dat2 = 1'bZ;
	assign sd_dat3 = 1'bZ;
	assign sd_cmd = 1'bZ;
	assign sd_sck = 1'bZ;

	// CH375b
	wire [2:0]usb_a;
	wire [31:0]usb_d;
	wire usb_we;
	wire [31:0]usb_spo;
	wire irq_usb;
	assign usb_spo = 0;
	assign ch375_rx = 1;

	wire mainm_burst_en_m;
	wire [7:0]mainm_burst_length_m;
	wire [31:0]mainm_a_m;
	wire [31:0]mainm_d_m;
	wire mainm_we_m;
	wire mainm_rd_m;
	wire [31:0]mainm_spo_m;
	wire mainm_ready_m;
	wire mainm_irq;
`ifdef DDR_EN
	//`ifdef CACHE_EN
	//`else
	// 1-bit wires are left implicitly declared
	wire [3:0]ddr_axi_awid;
	wire [27:0]ddr_axi_awaddr;
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
	wire [27:0]ddr_axi_araddr;
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
		.AXI4_ADDRLEN(27),
		.AXI4_DATALEN(32)
	) mm2axi4_ddr
	(
		.clk(clk_main),
		.rst(rst),

		.a(mainm_a_m),
		.d(mainm_d_m),
		.we(mainm_we_m),
		.rd(mainm_rd_m),
		.spo(mainm_spo_m),
		.ready(mainm_ready_m), 

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

	reg rst_ddr_auto = 0;
	reg [13:0]rst_ddr_auto_cnt = 0;
	always @ (posedge clk_mem) begin
		rst_ddr_auto_cnt <= rst_ddr_auto_cnt + 1;
		if (rst_ddr_auto_cnt == 2000) rst_ddr_auto <= 1;
	end

	ddr ddr_inst(
		.ddr2_dq(ddr2_dq),
		.ddr2_dqs_n(ddr2_dqs_n),
		.ddr2_dqs_p(ddr2_dqs_p),
		.ddr2_addr(ddr2_addr),
		.ddr2_ba(ddr2_ba),
		.ddr2_ras_n(ddr2_ras_n),
		.ddr2_cas_n(ddr2_cas_n),
		.ddr2_we_n(ddr2_we_n),
		.ddr2_ck_n(ddr2_ck_n),
		.ddr2_ck_p(ddr2_ck_p),
		.ddr2_cke(ddr2_cke),
		.ddr2_cs_n(ddr2_cs_n),
		.ddr2_dm(ddr2_dm),
		.ddr2_odt(ddr2_odt),

		.init_calib_complete(ddr_calib_complete),

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
	//`endif
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
	assign video_spo = 0;

	wire [31:0]ps2_spo;
	wire irq_ps2;
	assign irq_ps2 = 0;

	wire [31:0]eth_a;
	wire [31:0]eth_d;
	wire eth_we;
	wire [31:0]eth_spo;
	wire irq_eth;
	assign eth_spo = 0;
	assign irq_eth = 0;

    // interrupt unit
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
    // timer interrupt
    wire irq_timer;
    aclint #(.TIMER_COUNTER(TIMER_COUNTER)) aclint_inst(
        .clk(clk_main),
        .rst(rst_aclint),

        .s_irq(irq_soft_pending),
        .t_irq(irq_timer_pending),

		.a(aclint_a),
		.d(aclint_d),
		.we(aclint_we),
		.spo(aclint_spo)
    );

    interrupt_unit interrupt_unit_inst(
        .clk(clk_main),
        .rst(rst_interrupt),

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

        .sd_spo({7'b0, 1'b1, 24'b0}),
        .sd_a(),
        .sd_d(),
        .sd_we(),

        .usb_spo(0),
        .usb_a(),
        .usb_d(),
        .usb_we(),

        .gpio_spo(gpio_spo),
        .gpio_a(gpio_a),
        .gpio_d(gpio_d),
        .gpio_we(gpio_we),

        .uart_spo(uart_spo),
        .uart_a(uart_a),
        .uart_d(uart_d),
        .uart_we(uart_we),

        .video_spo(0),
        .video_a(),
        .video_d(),
        .video_we(),

        .int_spo(int_spo),
        .int_a(int_a),
        .int_d(int_d),
        .int_we(int_we),

        .sb_spo(sb_spo),
        .sb_a(sb_a),
        .sb_d(sb_d),
        .sb_we(sb_we),
		.sb_ready(sb_ready),

		.ps2_spo(0),

		.t_a(aclint_a),
		.t_d(aclint_d),
		.t_we(aclint_we),
		.t_spo(aclint_spo),

		.eth_a(),
		.eth_d(),
		.eth_we(),
		.eth_spo(0),

        .irq(pirq)
    );
endmodule
