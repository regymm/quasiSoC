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
		parameter WEB = 0,
		parameter INIT = "/dev/null"
	)
	(
		input clk, 
		input [DEPTH-1:0]a,
		input [WIDTH-1:0]d,
		input we,
		input [3:0]web,
		input rd,
		output reg [WIDTH-1:0]spo,
		output ready
	);

	reg [WIDTH-1:0]mem[(2**DEPTH)-1:0];
	initial $readmemh(INIT, mem);

	assign ready = ~(rd | (WEB ? |web : we));
	
	always @ (posedge clk) begin
		if (WEB) begin
			if (web[0]) mem[a][7:0] <= d[7:0];
			if (web[1]) mem[a][15:8] <= d[15:8];
			if (web[2]) mem[a][23:16] <= d[23:16];
			if (web[3]) mem[a][31:24] <= d[31:24];
		end else begin
			if (we) begin
				mem[a] <= d;
			end
		end
		//spo <= d;
		spo <= mem[a];
	end
endmodule
