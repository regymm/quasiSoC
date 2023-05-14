/**
 * File              : simple_ram.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.11.26
 * Last Modified Date: 2020.11.26
 */
`timescale 1ns / 1ps
module simple_ram
	#(
		parameter WIDTH = 32,
		parameter DEPTH = 1,
		parameter INIT = "/home/petergu/MyHome/pComputer/pCPU/null.dat"
	)
	(
		input clk, 
		input [DEPTH-1:0]a,
		input [WIDTH-1:0]d,
		input we,
		input rd,
		output reg [WIDTH-1:0]spo,
		output ready
	);

	reg [WIDTH-1:0]mem[(2**DEPTH)-1:0];
	initial $readmemh(INIT, mem);

	assign ready = ~(rd | we);
	
	always @ (posedge clk) begin
		if (we) begin
			mem[a] <= d;
			spo <= d;
		end
		spo <= mem[a];
	end
	//always @ (a) begin
		//spo = mem[a];
	//end
endmodule
