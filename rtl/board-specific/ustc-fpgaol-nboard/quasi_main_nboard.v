/**
 * File              : quasi_main.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.11.25
 * Last Modified Date: 2024.01.27
 */
`timescale 1ns / 1ps
`include "quasi.vh"

module quasi_main_nboard
	#(
		parameter SIMULATION = 0,
		parameter INTERACTIVE_SIM = 0,
		parameter CLOCK_FREQ = 62500000,
		//parameter CLOCK_FREQ = 75000000,
		parameter BAUD_RATE_UART = 9600,
		//parameter BAUD_RATE_UART = 3686400,
		parameter TIMER_RATE = 10000000,
		parameter PSPI_WIDTH = 1,
		parameter UBERDDR3_CTRL_CLK_PERIOD = 16_000, // 1e12 / CLOCK_FREQ
		parameter UBERDDR3_CLK_PERIOD = 4_000 // UBERDDR3_CTRL_CLK_PERIOD / 4
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

		output wire pspi_sck,
		output wire [PSPI_WIDTH-1:0]pspi_mosi,
		input wire [PSPI_WIDTH:0]pspi_miso,

        inout [7:0]       ddr3_dq,
        inout [0:0]        ddr3_dqs_n,
        inout [0:0]        ddr3_dqs_p,
        output [15:0]     ddr3_addr,
        output [2:0]        ddr3_ba,
        output            ddr3_ras_n,
        output            ddr3_cas_n,
        output            ddr3_we_n,
        output            ddr3_cs_n,
        output            ddr3_reset_n,
        output [0:0]       ddr3_ck_p,
        output [0:0]       ddr3_ck_n,
        output [0:0]       ddr3_cke,
        output [0:0]     ddr3_dm,
        output [0:0]       ddr3_odt
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
	wire clk_mem_n;
    wire clk_hdmi_25;
    wire clk_hdmi_250;
	wire clk_ref;
	wire clk_locked;
	//assign clk_2x = clk_hdmi_250;
	wire clk_2x;
	assign clk_hdmi_250 = clk_mem;
`ifndef SIMULATION
	clocking_wizard clock_wizard_inst(
		.clk_in1(sysclk),
		.clk_main(clk_main),
		.clk_mem(clk_mem),
		.clk_hdmi_25(clk_hdmi_25),
		.clk_hdmi_2x(clk_2x),
		.clk_mem_n(clk_mem_n),
		.clk_ref(clk_ref),
		.reset(1'b0),
		.locked(clk_locked)
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

    wire [1:0]sw_d;
    debounce #(.N(2)) debounce_inst_0(
        .clk(clk_main),
        .i_btn(sw),
        .o_state(sw_d)
    );

    wire [1:0]sw_d_free;
    debounce #(.N(2)) debounce_inst_0_free(
        .clk(sysclk),
        .i_btn(sw),
        .o_state(sw_d_free)
    );

    wire [1:0]btn_d;
    debounce #(.N(2)) debounce_inst_1(
        .clk(clk_main),
        .i_btn(btn),
        .o_state(btn_d)
    );

    // reset signal
	wire manual_rst = sw_d[0];
	wire ddr_calib_complete;
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
`ifndef SIMULATION
		.INIT("/home/petergu/quasiSoC/firmware/fpgaolbl/fpgaolbl.dat")
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

	// pspi
	wire [31:0]pspi_a;
	wire [31:0]pspi_d;
	wire pspi_we;
	wire pspi_rd;
	wire [31:0]pspi_spo;
	wire pspi_ready;
	//wire pspi_sck;
	//wire [7:0]pspi_mosi;
	//wire [7:0]pspi_miso;
	pspi_host #(.PSPI_WIDTH(PSPI_WIDTH)) pspi_host_inst (
		.clk(clk_main),
		.rst(rst),

		.a(pspi_a),
		.d(pspi_d),
		.we(pspi_we),
		.rd(pspi_rd),
		.spo(pspi_spo),
		.ready(pspi_ready),

		.sck(pspi_sck),
		.mosi(pspi_mosi),
		.miso(pspi_miso)
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
	wire [31:0]dbg_pc;
	wire [31:0]dbg_instr;
	wire [31:0]dbg_ra;
	wire [31:0]dbg_rb;
`ifdef VIDEO_EN
	mkrvidor4000_top mkrvidor4000_top_inst(
		.dbg_pc(dbg_pc),
		.dbg_instr(dbg_instr),
		.dbg_ra(dbg_ra),
		.dbg_rb(dbg_rb),

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

`ifdef DDR_EN
	wire wb_cyc;
	wire wb_we;
	wire wb_stb;
	wire [31:0]wb_addr;
	wire [31:0]wb_dat_o;
	wire [3:0]wb_sel;
	wire [31:0]wb_dat_i;
	wire wb_stall;
	wire wb_wb_ack;
	mm2wb mm2axi4_ddr
	(
		.clk(clk_main),
		.rst(rst),

		.a(mainm_a),
		.d(mainm_d),
		.we(mainm_we),
		.rd(mainm_rd),
		.spo(mainm_spo),
		.ready(mainm_ready), 

		.wb_cyc(wb_cyc),
		.wb_we(wb_we),
		.wb_stb(wb_stb),
		.wb_addr(wb_addr),
		.wb_dat_o(wb_dat_o),

		.wb_sel(wb_sel),
		.wb_dat_i(wb_dat_i),
		.wb_stall(wb_stall),
		.wb_ack(wb_ack),

		.irq(mainm_irq)
	);

    ddr3_top #(
        .CONTROLLER_CLK_PERIOD(UBERDDR3_CTRL_CLK_PERIOD), //12_000ps, controller interface
        .DDR3_CLK_PERIOD(UBERDDR3_CLK_PERIOD), //3_000ps, DDR3 RAM device (1/4 CONTROLLER_CLK_PERIOD) 
        .ROW_BITS(15), //width of row address
        .COL_BITS(10), //width of column address
        .BA_BITS(3), //width of bank address
        .DQ_BITS(8),  //width of DQ
        .LANES(1),
        .AUX_WIDTH(4),
        .WB2_ADDR_BITS(32),
        .WB2_DATA_BITS(32),
        .OPT_LOWPOWER(1),
        .OPT_BUS_ABORT(1),
        .MICRON_SIM(0),
        .ODELAY_SUPPORTED(0),
        .SECOND_WISHBONE(0)
	) ddr3_top_inst
	(
		//clock and reset
		.i_controller_clk(clk_main), // CONTROLLER_CLK_PERIOD
		.i_ddr3_clk(clk_mem), //DDR3_CLK_PERIOD 
		.i_ref_clk(clk_ref), // 200 MHz
		.i_ddr3_clk_90(clk_mem_n), // phase shifted
		.i_rst_n(!rst && clk_locked), 
		// Wishbone inputs
		.i_wb_cyc(1'b1),
		.i_wb_stb(wb_stb),
		.i_wb_we(wb_we),
		.i_wb_addr(wb_addr),
		.i_wb_data(wb_dat_o),
		.i_wb_sel(16'hffff),
		//.i_aux(wb_we),
		// Wishbone outputs
		.o_wb_stall(wb_stall),
		.o_wb_ack(wb_ack),
		.o_wb_data(wb_dat_i),
		//.o_aux(o_aux),
		// DDR3 I/O Interface
		.o_ddr3_clk_p(ddr3_ck_p),
		.o_ddr3_clk_n(ddr3_ck_n),
		.o_ddr3_reset_n(ddr3_reset_n),
		.o_ddr3_cke(ddr3_cke),
		.o_ddr3_cs_n(ddr3_cs_n),
		.o_ddr3_ras_n(ddr3_ras_n),
		.o_ddr3_cas_n(ddr3_cas_n),
		.o_ddr3_we_n(ddr3_we_n),
		.o_ddr3_addr(ddr3_addr),
		.o_ddr3_ba_addr(ddr3_ba),
		.io_ddr3_dq(ddr3_dq),
		.io_ddr3_dqs(ddr3_dqs_p),
		.io_ddr3_dqs_n(ddr3_dqs_n),
		.o_ddr3_dm(ddr3_dm),
		.o_ddr3_odt(ddr3_odt),
		.o_debug1(),
		.o_debug2(),
		.o_debug3()
	);
`else
	`ifndef SIMULATION
		// 2**14 * 32 64KB -- have to be w/o cache and ...
		simple_ram #(
			.WIDTH(32),
			.DEPTH(14),
			.INIT("/dev/null")
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

	// unused
    interrupt_unit interrupt_unit_inst(
        .clk(clk_main),
        .rst(rst),

        .interrupt(cpu_eip),
        .int_reply(cpu_eip_reply),

        .i_uart(irq_uart),
        .i_gpio(irq_gpio),
		.i_ps2(0),

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
		.ready(vready),

		.dbg_pc(dbg_pc),
		.dbg_instr(dbg_instr),
		.dbg_ra(dbg_ra),
		.dbg_rb(dbg_rb)
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

        .pspi_spo(pspi_spo),
        .pspi_a(pspi_a),
        .pspi_d(pspi_d),
        .pspi_we(pspi_we),
        .pspi_rd(pspi_rd),
		.pspi_ready(pspi_ready),

        .uart_spo(uart_spo),
        .uart_a(uart_a),
        .uart_d(uart_d),
        .uart_we(uart_we),

        .video_spo(video_spo),
        .video_a(video_a),
        .video_d(video_d),
        .video_we(video_we),

        .sd_spo({7'b0, 1'b1, 24'b0}),
        .sd_a(),
        .sd_d(),
        .sd_we(),

        .usb_spo(0),
        .usb_a(),
        .usb_d(),
        .usb_we(),

        .int_spo(int_spo),
        .int_a(int_a),
        .int_d(int_d),
        .int_we(int_we),

        .sb_a(sb_a),
        .sb_d(sb_d),
        .sb_we(sb_we),
        .sb_spo(sb_spo),
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
