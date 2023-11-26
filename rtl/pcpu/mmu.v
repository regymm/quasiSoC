/**
 * File              : mmu.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.07.21
 * Last Modified Date: 2023.07.16
 */

`timescale 1ns / 1ps
`include "quasi.vh"

module mmu_sv32
(
	input clk,
	input rst,

	input [1:0]mode,
	input paging,
	input [21:0]root_ppn,

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

	// these are synchronous exceptions, not interrupts
	output reg pagefault,
	output reg accessfault,
	output reg [15:0]err_code
);
	localparam PAGESIZE = 4096; // 2**12
	localparam LEVELS = 2;
	localparam PTESIZE = 4;

	wire mmureq;
	wire mmugnt;
	wire mmuhrd;
	reg [31:0]mmua;
	reg [31:0]mmud;
	reg mmuwe;
	reg mmurd;
	reg [31:0]mmuspo;
	reg mmuready;

	// TODO: add delay elsewhere for timing
	wire enabled = mode[1] == 0 & paging;
	//reg enabled = 0;
	//always @ (posedge clk) begin
		//enabled <= mode[1] == 0 & paging;
	//end

	// TODO: take care about bus switching problems
	assign preq = enabled ? mmureq : vreq;
	assign vgnt = enabled ? mmugnt : pgnt;
	assign vhrd = enabled ? mmuhrd : phrd;
	assign pa = enabled ? mmua : va;
	assign pd = enabled ? mmud : vd;
	assign pwe = enabled ? mmuwe : vwe;
	assign prd = enabled ? mmurd : vrd;
	assign vspo = enabled ? mmuspo : pspo;
	assign vready = enabled ? (mmuready & !(vrd | vwe)) : pready;

	wire [31:0]pspo_endian = {pspo[7:0], pspo[15:8], pspo[23:16], pspo[31:24]};

	// the sets we are operating on: 
	// cpu-side: va, vd, vwe, vrd, mmuspo, mmuready, ignore vreq, mmugnt=1, mmuhrd=0
	// phys mem: mmua, mmud, mmuwe, mmurd, pready, pspo, mmureq, pgnt, phrd

	assign mmugnt = 1;
	assign mmuhrd = 0;

	reg [31:0]vareg;
	reg [31:0]vdreg;
	reg vwereg;
	reg vrdreg;

	wire [9:0]vpn1 = vareg[31:22];
	wire [9:0]vpn0 = vareg[21:12];
	wire [11:0]offset = vareg[11:0];

	reg levels_i; // 1: pte1, 0: pte2

	wire [31:0]pteaddr1 = (root_ppn << $clog2(PAGESIZE)) + (vpn1 << $clog2(PTESIZE));
	reg [31:0]pte1;
	wire pte1v = pte1[0];
	wire pte1r = pte1[1];
	wire pte1w = pte1[2];
	wire pte1x = pte1[3];
	wire pte1u = pte1[4];
	wire pte1a = pte1[6];
	wire pte1d = pte1[7];
	wire [21:0]pte1ppn = pte1[31:10];
	wire [31:0]pteaddr2 = (pte1ppn << $clog2(PAGESIZE)) + (vpn0 << $clog2(PTESIZE));
	reg [31:0]pte2;
	wire pte2v = pte2[0];
	wire pte2r = pte2[1];
	wire pte2w = pte2[2];
	wire pte2x = pte2[3];
	wire pte2u = pte2[4];
	wire pte2a = pte2[6];
	wire pte2d = pte2[7];
	wire [21:0]pte2ppn = pte2[31:10];
	wire [31:0]physaddr = {levels_i ? {pte1ppn[21:10], vpn0} : pte2ppn, offset};

	localparam DISABLED = 0;
	localparam IDLE = 1;
	localparam BAD = 2;
	localparam PAGEFAULT = 3;
	localparam ACCESSFAULT = 4;
	localparam LV1RD = 8;
	localparam LV1DECODE = 9;
	localparam LV2RD = 10;
	localparam LV2DECODE = 11;
	localparam TAINT = 12;
	localparam MEMRW = 13;
	reg [3:0]phase;
	reg [3:0]phase_n;

	// bus control
	reg mfuse_r;
	wire mfuse = mfuse_r & !phrd;
	wire bus_xfer_ok = mmureq & pgnt;
	wire phase_need_gnt = phase[3]; // (phase!=IDLE & phase!=DISABLED & phase!=BAD);
	wire phase_with_mem = phase == LV1RD | phase == LV2RD | phase == TAINT | phase == MEMRW; // maybe we don't need this... a mfuse=1 when no mem access does no harm
	assign mmureq = !phrd & phase_need_gnt;
	wire phase_changing = phase_n != phase;
	always @ (posedge clk) begin
		if (rst) mfuse_r <= 1;
		else if (!phase_changing & phase_with_mem & bus_xfer_ok) mfuse_r <= 0;
		else mfuse_r <= 1;
	end

	wire [31:0]taint_d = (levels_i ? pte1 : pte2) | 32'h40 | (vwereg & 32'h80);
	wire [31:0]taint_d_endian = {taint_d[7:0], taint_d[15:8], taint_d[23:16], taint_d[31:24]};

	always @ (*) begin
		phase_n = phase; // remain last phase by default
		mmuready = 0;
		mmua = 0;
		mmuwe = 0;
		mmurd = 0;
		pagefault = 0;
		accessfault = 0;
		case (phase) 
			IDLE: begin
				mmuready = 1;
				if (enabled & (vwe | vrd)) phase_n = LV1RD;
				else phase_n = IDLE;
				//if (!enabled) phase_n = DISABLED;
				//else if (vwe | vrd) phase_n = LV1RD;
				//else phase_n = IDLE;
			end
			LV1RD: begin
				mmua = pteaddr1;
				mmurd = mfuse;
				if (bus_xfer_ok & pready) phase_n = LV1DECODE;
				else phase_n = LV1RD;
			end
			LV1DECODE: begin
				if (!pte1v | (!pte1r & pte1w)) phase_n = PAGEFAULT;
				else if (pte1r | pte1x) begin
					// leaf PTE is found
					// see LV2DECODE for details
					if ((vwereg & !pte1w) | (!pte1u & mode == 2'b00)) phase_n = PAGEFAULT;
					else if (!pte1a | (vwereg & !pte1d)) phase_n = TAINT;
					else phase_n = MEMRW;
				end
				else phase_n = LV2RD;
			end
			LV2RD: begin
				mmua = pteaddr2;
				mmurd = mfuse;
				if (bus_xfer_ok & pready) phase_n = LV2DECODE;
				else phase_n = LV2RD;
			end
			LV2DECODE: begin
				if (!pte2v | (!pte2r & pte2w)) phase_n = PAGEFAULT;
				else if (pte2r | pte2x) begin
					// leaf PTE is found
					// we only check write violations and u-mode violations
					// distinguishing r and x is too much
					// SUM/MXR check: easy but no
					if ((vwereg & !pte2w) | (!pte2u & mode == 2'b00)) phase_n = PAGEFAULT; 
					else if (!pte2a | (vwereg & !pte2d)) phase_n = TAINT;
					else phase_n = MEMRW;
				end
				else phase_n = BAD;
			end
			TAINT: begin
				mmua = levels_i ? pteaddr1 : pteaddr2;
				//mmud = (levels_i ? pte1 : pte2) | 32'h40 | (vwereg & 32'h80);
				mmud = taint_d_endian;
				mmuwe = mfuse;
				if (bus_xfer_ok & pready) phase_n = MEMRW;
				else phase_n = TAINT;
			end
			MEMRW: begin
				mmua = physaddr;
				mmud = vdreg;
				mmurd = mfuse & vrdreg;
				mmuwe = mfuse & vwereg;
				if (bus_xfer_ok & pready) phase_n = IDLE;
				else phase_n = MEMRW;
			end
			DISABLED: begin
				if (enabled) phase_n = IDLE;
				else phase_n = DISABLED;
			end
			PAGEFAULT: begin
				pagefault = 1;
				mmuready = 1;
				phase_n = IDLE;
			end
			ACCESSFAULT: begin
				accessfault = 1;
				mmuready = 1;
				phase_n = IDLE;
			end
			BAD: begin
				pagefault = 1;
				accessfault = 1;
				phase_n = BAD;
			end
		endcase
	end

	always @ (posedge clk) begin
		if (rst) begin
			phase <= IDLE;
			mmuspo <= 0;
		end else begin
			phase <= phase_n;
			case (phase)
				IDLE: begin
					vareg <= va;
					vdreg <= vd;
					vwereg <= vwe;
					vrdreg <= vrd;
					levels_i <= 1;
				end
				LV1RD: begin
					if (phase_n == LV1DECODE) begin
						pte1 <= pspo_endian;
					end
				end
				LV1DECODE: begin
				end
				LV2RD: begin
					levels_i <= 0;
					if (phase_n == LV2DECODE) begin
						pte2 <= pspo_endian;
					end
				end
				LV2DECODE: begin
				end
				TAINT: begin
				end
				MEMRW: begin
					if (phase_n == IDLE) begin
						mmuspo <= pspo;
					end
				end
				PAGEFAULT: begin
					//$display("va vd vwe vrd: %h %h %h %h", vareg, vdreg, vwereg, vrdreg);
					//$display("levels_i mode: %d %x", levels_i, mode);
					//$display("1 v r w u: %h %h %h %h", pte1v, pte1r, pte1w, pte1u);
					//$display("2 v r w u: %h %h %h %h", pte2v, pte2r, pte2w, pte2u);
				end
				DISABLED: begin
				end
				default: ;
			endcase
		end
	end
endmodule
