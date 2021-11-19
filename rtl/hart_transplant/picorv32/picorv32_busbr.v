/**
 * File              : picorv32_busbr.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2021.11.19
 * Last Modified Date: 2021.11.19
 */
`timescale 1ns / 1ps

module picorv32_busbr
(
	input clk,

	input ready,
	input [31:0]spo,
	output [31:0]a,
	output [31:0]d,
	output we,
	output rd,

	input mem_valid,
	input mem_instr,
	output mem_ready,
	input [31:0]mem_addr,
	input [31:0]mem_wdata,
	input [3:0]mem_wstrb,
	output [31:0]mem_rdata
);
	wire read = mem_wstrb == 0;
	wire w_normal = mem_valid & !read & mem_wstrb == 4'b1111;
	wire w_unalign = mem_valid & !read & mem_wstrb != 4'b1111;
	//wire write = mem_valid & !read;
	reg [1:0]state = 0;
	reg [31:0]unalign_save = 0;

	assign a = mem_addr;
	assign mem_rdata = spo;

	reg mem_valid_last = 0;
	always @ (posedge clk) begin
		mem_valid_last <= mem_valid;
	end
	wire mem_valid_posedge = mem_valid & !(mem_valid_last);

	assign rd = mem_valid_posedge & (read | w_unalign);
	assign we = state == 0 ? mem_valid_posedge & w_normal : state == 1;
	//assign rd = mem_valid_posedge;
	//assign we = state == 1;
	

	wire [31:0]unalign_mask = {{8{mem_wstrb[3]}}, {8{mem_wstrb[2]}}, {8{mem_wstrb[1]}}, {8{mem_wstrb[0]}}};
	wire [31:0]unalign_w_data = (unalign_save & ~unalign_mask) + (mem_wdata & unalign_mask);

	assign d = state == 0 ? mem_wdata : unalign_w_data;

	reg unalign_done = 0;

	reg mem_ready_r = 0;
	assign mem_ready = mem_ready_r & mem_valid;

	always @ (posedge clk) begin
		if (!mem_valid) begin
			mem_ready_r <= 0;
			unalign_done <= 0;
		end else if (state == 0) begin
			if (ready) begin // ready should drop to 0 imm after valid high
				if (w_unalign & !unalign_done) begin
				//if (write & !unalign_done) begin
					unalign_save <= spo;
					state <= 1;
				end else mem_ready_r <= 1;
			end
		end else if (state == 1) begin
			state <= 2;
		end else if (state == 2) begin
			if (ready) begin
				state <= 0;
				unalign_done <= 1;
				mem_ready_r <= 1;
			end
		end
	end
endmodule
