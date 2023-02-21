/**
 * File              : mul_simu.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.11.28
 * Last Modified Date: 2020.11.28
 */
`timescale 1ns / 1ps

module rv32m_simu();
    reg clk = 0;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
	reg start = 0;
	reg [31:0]a;
	reg [31:0]b;
	reg [2:0]m;
	wire finish;
	wire [31:0]r;
	wire [63:0]r_debug;
	rv32m rv32m_inst
	(
		.clk(clk),
		.start(start),
		.a(a),
		.b(b),
		.m(m),
		.finish(finish),
		.r(r)
		//.r_debug(r_debug)
	);
	initial begin
		//a = 25;
		//b = 80;
		//m = 2'b00;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		//a = -10;
		//b = 8;
		//m = 2'b00;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		//a = 2100000000;
		//b = 2;
		//m = 2'b00;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		//a = 32'hfffff000;
		//b = 32'habcdefff;
		//m = 2'b10;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		//a = 32'hfffff000;
		//b = 32'habcdefff;
		//m = 2'b01;
		//start = 1;
		//#20
		//start = 0;
		//#1000
		//$finish;

		//a = 80;
		//b = 13;
		//m = 3'b100;
		//start = 1;
		//#20
		//start = 0;
		//#1000
		//a = 80;
		//b = 13;
		//m = 3'b110;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		//a = -25;
		//b = 8;
		//m = 3'b101;
		//start = 1;
		//#20
		//start = 0;
		//#1000
		//a = -25;
		//b = 8;
		//m = 3'b111;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		a = -25;
		b = 8;
		m = 3'b100;
		start = 1;
		#20
		start = 0;
		#1000
		a = -25;
		b = 8;
		m = 3'b110;
		start = 1;
		#20
		start = 0;
		#1000

		a = 32'hcbcd1234;
		b = 32'h1777ffff;
		m = 3'b100;
		start = 1;
		#20
		start = 0;
		#1000
		a = 32'hcbcd1234;
		b = 32'h1777ffff;
		m = 3'b110;
		start = 1;
		#20
		start = 0;
		#1000

		a = 32'h1bcd1234;
		b = 32'hffff7fff;
		m = 3'b100;
		start = 1;
		#20
		start = 0;
		#1000
		a = 32'h1bcd1234;
		b = 32'hffff7fff;
		m = 3'b110;
		start = 1;
		#20
		start = 0;
		#1000


		a = 32'h3432edcc;
		b = 32'he8880001;
		m = 3'b100;
		start = 1;
		#20
		start = 0;
		#1000
		a = 32'h3432edcc;
		b = 32'he8880001;
		m = 3'b110;
		start = 1;
		#20
		start = 0;
		#1000

		a = 32'hf1234567;
		b = 32'hfffa1234;
		m = 3'b100;
		start = 1;
		#20
		start = 0;
		#1000
		a = 32'hf1234567;
		b = 32'hfffa1234;
		m = 3'b110;
		start = 1;
		#20
		start = 0;
		#1000

		//a = 2100000000;
		//b = 2;
		//m = 2'b00;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		//a = 32'hfffff000;
		//b = 32'habcdefff;
		//m = 2'b10;
		//start = 1;
		//#20
		//start = 0;
		//#1000

		//a = 32'hfffff000;
		//b = 32'habcdefff;
		//m = 2'b01;
		//start = 1;
		//#20
		//start = 0;
		//#1000
		$finish;
	end
endmodule
