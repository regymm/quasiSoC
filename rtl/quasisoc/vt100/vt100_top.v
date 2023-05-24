/**
 * File              : vt100_top.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2023.05.23
 * Last Modified Date: 2023.05.23
 */
// top module for standalone VT100 operation

`timescale 1ns / 1ps

module vt100_top
#(
	parameter CLOCK_FREQ = 62500000,
	parameter BAUD_RATE = 115200
)
(
	input sysclk,

	input [1:0]sw,

	input rx,

	output tx,
	input tx_up,


	output [2:0] TMDSp,
	output [2:0] TMDSn,
	output TMDSp_clock,
	output TMDSn_clock
);
	assign tx = tx_up;

    wire clk;
	wire clk_mem;
	wire clk_2x;
    wire clk_hdmi_25;
    wire clk_hdmi_250;
	clock_wizard clock_wizard_inst(
		.clk_in1(sysclk),
		.clk_main(clk),
		.clk_mem(clk_mem),
		.clk_hdmi_25(clk_hdmi_25),
		.clk_hdmi_250(clk_hdmi_250),
		.clk_hdmi_50(clk_2x)
	);

    wire [1:0]sw_d;
    debounce #(.N(2)) debounce_inst_0(
        .clk(clk),
        .i_btn(sw),
        .o_state(sw_d)
    );

	wire rst = sw_d[0];

	wire [11:0]fb_a;
	wire [15:0]fb_d;
	wire fb_we;

	vt100 #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE)
	) vt100_inst (
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.fb_a(fb_a),
		.fb_d(fb_d),
		.fb_we(fb_we)
	);

	mkrvidor4000_top #(
		.FBEXT_ENABLE(1)
	) hdmi_inst (
		.clk(clk),
		.clk_2x(clk_2x),
		.clk_pix(clk_hdmi_25),
		.clk_tmds(clk_hdmi_250),

		.fb_a(fb_a),
		.fb_d(fb_d),
		.fb_we(fb_we),

		.TMDSp(TMDSp),
		.TMDSn(TMDSn),
		.TMDSp_clock(TMDSp_clock),
		.TMDSn_clock(TMDSn_clock)
	);

endmodule
