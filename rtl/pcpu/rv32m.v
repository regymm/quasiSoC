/**
 * File              : rv32m.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.11.28
 * Last Modified Date: 2022.07.05
 */
// a simple 32-bit multiplication and division unit
// 0 m: 00 mul, 01 mulh, 10 mulhsu, 11 mulhu
// 1 d: 00 div, 01 divu, 10 rem, 11 remu
// 64 cycles for mulh, 32 cycles for other mul and div
// dirty but seems working
`timescale 1ns / 1ps

module rv32m
	(
		input clk,
		input start,
		input [31:0]a,
		input [31:0]b,
		input [2:0]m,
		output reg finish,
		output reg [31:0]r,
		output reg div0
		//output reg [63:0]r_debug
    );
	reg [2:0]mreg;
	reg [63:0]aext;
	reg [63:0]bext;
	reg [64:0]result;
	reg [6:0]cnt;
	wire mul_or_div = !mreg[2];
	wire finish_cond = mul_or_div ? 
		(mreg[1:0] == 2'b01) ? cnt == 64 : cnt == 32
		: cnt == 32;
	reg divfix;
	reg remfix;
	always @ (posedge clk) begin
		if (start) begin
			if (!m[2]) begin
				// mul
				aext <= (m[1:0] != 2'b11) ? {{32{a[31]}}, a} : {32'b0, a};
				bext <= (m[1:0] == 2'b01) ? {{32{b[31]}}, b} : {32'b0, b};
			end else begin
				// div
				if (!m[0]) begin // signed div
					if (b[31]) begin
						aext <= {{32{!a[31]}}, -a};
						bext <= {-b, 32'b0};
					end else begin
						aext <= {{32{a[31]}}, a};
						bext <= {b, 32'b0};
					end
				end else begin // unsigned div
					aext <= {32'b0, a};
					bext <= {b, 32'b0};
				end
			end
			mreg <= m;
			result <= 0;
			cnt <= 0;
			finish <= 0;
			div0 <= (b == 0) && m[2];
			divfix <= (a[31] ^ b[31]) && !m[0] && (a != 32'h80000000);
			remfix <= b[31] && !m[0];
		end
		else begin
			cnt <= cnt + 1;
			if (mul_or_div) begin
				// mul
				aext <= aext << 1;
				bext <= bext >> 1;
				if (bext[0])
					result <= result + aext;
				if (finish_cond) begin
					r <= (mreg[1:0] == 2'b00) ? result[31:0] : result[63:32];
					finish <= 1;
				end
			end else begin
				// div
				if (aext[62:31] >= bext[63:32])
					aext <= aext[63] ? 
						(aext << 1) + bext + 1'b1
						: 
						(aext << 1) - bext + 1'b1;
				else
					aext <= (aext << 1);
				if (finish_cond) begin
					r <= divfix ? 
						(!mreg[1]) ? aext[31:0]+1 : (remfix ? ~aext[63:32]+bext[63:32]+1 : aext[63:32]-bext[63:32])
						: 
						(!mreg[1]) ? aext[31:0] : (remfix ? ~aext[63:32]+1 : aext[63:32]);
					finish <= 1;
				end
			end
		end
	end
endmodule
