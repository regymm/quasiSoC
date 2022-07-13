/**
 * File              : clocked_rom.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.19
 * Last Modified Date: 2021.01.19
 */

`timescale 1ns / 1ps

module clocked_rom
	#(
		parameter WIDTH = 32,
		parameter DEPTH = 1,
		parameter INIT = "/home/petergu/MyHome/pComputer/pCPU/null.dat"
	)
	(
		input clk,
		input [DEPTH-1:0]a,
		input rd,
		output reg [WIDTH-1:0]spo,
		output ready
	);

	reg [WIDTH-1:0]mem[(2**DEPTH)-1:0];
	initial $readmemh(INIT, mem);

	assign ready = ~rd;
	
	always @ (posedge clk) begin
		spo <= mem[a];
	end
endmodule
