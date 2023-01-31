/**
 * File              : mmu.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.07.21
 * Last Modified Date: 2022.07.21
 */

`timescale 1ns / 1ps
`include "quasi.vh"

module mmu_sv32
(
	input clk,
	input rst,

	input vreq,
	output vgnt,
	output vhrd,
	input [31:0]va,
	input [31:0]vd,
	input vwe,
	input vrd,
	output [31:0]vspo,
	output vready,

	output preq,
	input pgnt,
	input phrd,
	output [31:0]pa,
	output [31:0]pd,
	output pwe,
	output prd,
	input [31:0]pspo,
	input pready,

	// control ports
	input [31:0]satp,
	input [1:0]mode,

	// these are synchronous exceptions, not interrupts
	output err,
	output [15:0]err_code
);
	localparam PAGESIZE = 4096; // 2**12
	localparam LEVELS = 2;
	localparam PTESIZE = 4;

	reg p1req;
	wire v1gnt;
	wire v1hrd;
	reg [31:0]p1a;
	reg [31:0]p1d;
	reg p1we;
	reg p1rd;
	wire [31:0]v1spo;
	wire v1ready;

	assign preq = mode ? p1req : vreq;
	assign vgnt = mode ? v1gnt : pgnt;
	assign vhrd = mode ? v1hrd : phrd;
	assign pa = mode ? p1a : va;
	assign pd = mode ? p1d : vd;
	assign pwe = mode ? p1we : vwe;
	assign prd = mode ? p1rd : vrd;
	assign vspo = mode ? v1spo : pspo;
	assign vready = mode ? v1ready : pready;

	assign v1gnt = 1;
	assign v1hrd = 0;

	reg [31:0]vareg;
	reg [31:0]vdreg;
	reg vwereg;
	reg vrdreg;

	wire enabled = satp[31]; // 0: bare, 1: sv32
	wire [8:0]asid = satp[30:22];
	wire [21:0]root_ppn = satp[21:0];

	wire [9:0]vpn1 = vareg[31:22];
	wire [9:0]vpn0 = vareg[21:12];
	wire [11:0]offset = vareg[11:0];
	wire [31:0]pteaddr1 = (root_ppn << $clog2(PAGESIZE)) + (vpn1 << PTESIZE);

	reg [31:0]pte1;
	wire pte1v = pte1[0];
	wire pte1r = pte1[1];
	wire pte1w = pte1[2];
	wire pte1x = pte1[3];
	wire pte1u = pte1[4];

	localparam DISABLED = 0;
	localparam IDLE = 1;
	localparam LV1RD = 2;
	localparam LV1DECODE = 3;
	reg [3:0]state;

	// bus control
	reg mfuse_r;
	wire mfuse = mfuse_r & !phrd;
	wire bus_occupied = p1req & pgnt;
	wire phase_need_gnt = state == LV1RD;
	assign p1req = !phrd & phase_need_gnt;
	always @ (posedge clk) begin
		if (rst) mfuse_r <= 1;
		else if (!phase_changing & phase_with_mem & bus_xfer_ok) mfuse_r <= 0;
		else mfuse_r <= 1;
	end

	always @ (posedge clk) begin
		if (rst) begin
			state <= IDLE;
		end else begin
			case (state)
				IDLE: begin
					vareg <= va;
					vdreg <= vd;
					vwereg <= vwe;
					vrdreg <= vrd;
					if (mode == 0)
						state <= DISABLED;
					else if (vwe | vrd) begin
						state <= LV1RD;
					end
				end
				LV1RD: begin
					p1a <= pteaddr1;
					p1we <= mfuse;
					if (bus_occupied & pready) begin
						state <= LV1DECODE; 
						pte1 <= pspo;
					end
				end
				LV1DECODE: begin
				end
				DISABLED: begin
					if (mode == 1) state <= IDLE;
				end
				default: state <= IDLE;
			endcase
		end
	end
endmodule
