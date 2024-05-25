/**
 * File              : simple_ram.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.11.26
 * Last Modified Date: 2020.11.26
 */
`timescale 1ns / 1ps
module simple_dp_ram
	#(
		parameter WIDTH = 32,
		parameter DEPTH = 1,
		parameter INIT = "/dev/null"
	)
	(
		input clk1, 
		input [DEPTH-1:0]a1,
		input [WIDTH-1:0]d1,
		input we1,

		input clk2,
		input [DEPTH-1:0]a2,
		input rd2,
		output reg [WIDTH-1:0]spo2,
		output ready
	);

	reg [WIDTH-1:0]mem[(2**DEPTH)-1:0];
	initial $readmemh(INIT, mem);

	assign ready = ~(we1 | rd2);
	
	always @ (posedge clk1) begin
		if (we1) mem[a1] <= d1;
	end

	always @(posedge clk2) begin
		spo2 <= mem[a2];
	end

endmodule
