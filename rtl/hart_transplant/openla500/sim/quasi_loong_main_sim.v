// SPDX-License-Identifier: GPL-3.0-or-later
// Simulation wrapper for quasi_main with SDRAM model

`timescale 1ns / 1ps

module quasi_main_sim
	#(
		parameter SIMULATION = 1,
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

        input sd_ncd,
        input sd_dat0,
        output sd_dat1,
        output sd_dat2,
        output sd_dat3,
        output sd_cmd,
        output sd_sck,

	// `ifdef HDMI_EN
        output [2:0]TMDSp,
        output [2:0]TMDSn,
        output TMDSp_clock,
        output TMDSn_clock
    );

	// Internal SDRAM wires for connection between quasi_main and SDRAM model
	wire sdram_clk_int;
	wire sdram_ce_int;
	wire [1:0] sdram_ba_int;
	wire [12:0] sdram_a_int;
	wire sdram_cs_int;
	wire sdram_ras_int;
	wire sdram_cas_int;
	wire sdram_we_int;
	wire [15:0] sdram_dq_int;
	wire [15:0] sdram_dq_int_dly;

	wire sdram_clk_int_dly;
	wire sdram_ce_int_dly;
	assign #0 sdram_ce_int_dly = sdram_ce_int;
	assign #0 sdram_clk_int_dly = sdram_clk_int;
	assign #0 sdram_dq_int_dly = sdram_dq_int;

	// Instantiate the main design
	quasi_main #(
		.SIMULATION(SIMULATION),
		.INTERACTIVE_SIM(INTERACTIVE_SIM),
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE_UART(BAUD_RATE_UART),
		.BAUD_RATE_UART2(BAUD_RATE_UART2),
		.TLBNUM(TLBNUM)
	) dut (
		.sysclk(sysclk),
		.sw(sw),
		.btn(btn),
		.led(led),
		.uart_rx(uart_rx),
		.uart_tx(uart_tx),
	`ifdef INTERACTIVE_SIM
		.uart_rxsim_en(uart_rxsim_en),
		.uart_rxsim_data(uart_rxsim_data),
	`endif
		.sd_ncd(1'b1),
		.sd_dat0(sd_dat0),
		.sd_dat1(sd_dat1),
		.sd_dat2(sd_dat2),
		.sd_dat3(sd_dat3),
		.sd_cmd(sd_cmd),
		.sd_sck(sd_sck),
	`ifdef SDRAM_EN
		.sdram_clk(sdram_clk_int),
		.sdram_ce(sdram_ce_int),
		.sdram_ba(sdram_ba_int),
		.sdram_a(sdram_a_int),
		.sdram_cs(sdram_cs_int),
		.sdram_ras(sdram_ras_int),
		.sdram_cas(sdram_cas_int),
		.sdram_we(sdram_we_int),
		.sdram_dq(sdram_dq_int),
	`endif
		.TMDSp(TMDSp),
		.TMDSn(TMDSn),
		.TMDSp_clock(TMDSp_clock),
		.TMDSn_clock(TMDSn_clock)
	);

`ifdef SDRAM_EN
`ifndef NO_SDRAM
	// Instantiate the SDRAM simulation model
	mt48lc16m16a2 sdram_model (
		.Dq(sdram_dq_int),
		.Addr({1'b0, sdram_a_int}),  // Pad 12-bit address to 13-bit
		.Ba(sdram_ba_int),
		.Clk(sdram_clk_int_dly),
		.Cke(sdram_ce_int),
		.Cs_n(sdram_cs_int),        // Active high to active low
		.Ras_n(sdram_ras_int),      // Active high to active low
		.Cas_n(sdram_cas_int),      // Active high to active low
		.We_n(sdram_we_int),        // Active high to active low
		.Dqm(2'b00)                  // Data mask not used, enable all bytes
	);
`endif
`endif

endmodule

