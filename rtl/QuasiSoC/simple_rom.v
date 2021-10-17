/**
 * File              : simple_rom.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.11.25
 * Last Modified Date: 2020.11.26
 */
`timescale 1ns / 1ps
module simple_rom
	#(
		parameter WIDTH = 32,
		parameter DEPTH = 1,
		parameter INIT = "/home/petergu/MyHome/pComputer/pCPU/null.dat"
	)
	(
		input [DEPTH-1:0]a,
		output reg [WIDTH-1:0]spo
	);

	reg [WIDTH-1:0]mem[(2**DEPTH)-1:0];
	initial $readmemh(INIT, mem);
	
	always @ (a) begin
		spo = mem[a];
	end
endmodule
