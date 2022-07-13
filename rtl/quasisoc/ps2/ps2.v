/**
 * File              : ps2.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.04.26
 * Last Modified Date: 2021.04.26
 */
`timescale 1ns / 1ps
`include "quasi.vh"

module ps2
	(
		input clk,
		input rst,

		//input [2:0]a,
		//input [31:0]d,
		//input we,
		output [31:0]spo,

		output reg irq = 0,

		input kclk,
		input kdata
	);

	wire [31:0]keycodeout;
	wire newkeypress;
	ps2_driver ps2_driver_inst(
		.clk(clk),
		.rst(rst),
		.kclk(kclk),
		.kdata(kdata),
		.keycodeout(keycodeout),
		.newkeypress(newkeypress)
	);

	reg [31:0]keycode;
	reg newkeypress_old;
	always @ (posedge clk) begin
		if (rst) begin
			newkeypress_old <= 0;
			keycode <= 0;
			irq <= 0;
		end else begin
			newkeypress_old <= newkeypress;
			if (newkeypress & !newkeypress_old) begin
				keycode <= keycodeout;
				irq <= 1;
			end else irq <= 0;
		end
	end
	assign spo = keycode;
endmodule
