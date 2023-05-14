/**
 * File              : clocking_xc7.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2021.10.21
 * Last Modified Date: 2021.10.21
 */

module clocking_xc7 (
	input clk_50,
	output clk1_62d5,
	output clk2_125,
	output clk3_25,
	output clk4_250,
	output clk5_50
);
	wire clk_ibuf;
	wire clk_bufg;
	wire clk1_pll;
	wire clk2_pll;
	wire clk3_pll;
	wire clk4_pll;
	wire clk5_pll;

	PLLE2_ADV #(
	  .CLKFBOUT_MULT(10),
	  //.CLKFBOUT_MULT(30),
      .CLKIN1_PERIOD(10.0),
	  .CLKOUT0_DIVIDE(40),
      //.CLKOUT0_DIVIDE(20),
      .CLKOUT0_PHASE(0),
	  .CLKOUT1_DIVIDE(8),
      //.CLKOUT1_DIVIDE(10),
      .CLKOUT1_PHASE(0),
      .CLKOUT2_DIVIDE(40),
      .CLKOUT2_PHASE(0),
      .CLKOUT3_DIVIDE(4),
      .CLKOUT3_PHASE(0),
      .CLKOUT4_DIVIDE(20),
      .CLKOUT4_PHASE(0),
      .DIVCLK_DIVIDE(1'd1),
      .REF_JITTER1(0.01),
      .STARTUP_WAIT("FALSE")
	) plle2_adv_inst (
		.CLKFBIN(pll_fb),
		.CLKFBOUT(pll_fb),
		.CLKIN1(clk_bufg),
		.CLKOUT0(clk1_pll),
		.CLKOUT1(clk2_pll),
		.CLKOUT2(clk3_pll),
		.CLKOUT3(clk4_pll),
		.CLKOUT4(clk5_pll)
	);

	IBUF clkbuf (
		.I(clk_50),
		.O(clk_ibuf)
	);
	BUFG bufg_in (
		.I(clk_ibuf),
		.O(clk_bufg)
	);
	BUFG bufg_1 (
		.I(clk1_pll),
		.O(clk1_62d5)
	);
	BUFG bufg_2 (
		.I(clk2_pll),
		.O(clk2_125)
	);
	BUFG bufg_3 (
		.I(clk3_pll),
		.O(clk3_25)
	);
	BUFG bufg_4 (
		.I(clk4_pll),
		.O(clk4_250)
	);
	BUFG bufg_5 (
		.I(clk5_pll),
		.O(clk5_50)
	);
endmodule
