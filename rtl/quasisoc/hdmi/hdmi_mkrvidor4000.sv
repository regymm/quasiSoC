/**
 * File              : hdmi_mkrvidor4000.sv
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2023.06.10
 * Last Modified Date: 2023.06.10
 */
`timescale 1ns / 1ps
`include "quasi.vh"

module mkrvidor4000_top
#(
	parameter FBEXT_ENABLE = 0
)
(
	input [31:0]dbg_pc,
	input [31:0]dbg_instr,
	input [31:0]dbg_ra,
	input [31:0]dbg_rb,
	input clk,
	input clk_2x,
	input rst,
	input clk_pix,
	input clk_tmds,

	input [31:0]a,
	input [31:0]d,
	input we,
	output reg [31:0]spo = 0,

	input [11:0]fb_a,
	input [15:0]fb_d,
	input fb_we,

//`ifdef HDMI_PICTURE
	//output req,
	//input gnt,
	//output burst_en,
	//output [7:0]burst_length,
	//output [31:0]vram_a,
	//output [31:0]vram_d,
	//output reg vram_we,
	//output reg vram_rd,
	//input [31:0]vram_spo,
	//input vram_ready,
	//assign burst_en = 1;
	//assign burst_length = 512;
	//assign lowmem_d = 0;
	//assign lowmem_we = 0;
//`endif


	// HDMI output
	output [2:0] TMDSp,
	output [2:0] TMDSn,
	output TMDSp_clock,
	output TMDSn_clock
);

	wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};
	wire we_vram = we & a[23:22] == 2'b00;
	wire we_char = we & a[23:22] == 2'b01;
	wire we_ctrl = we & a[23:22] == 2'b10;

	wire [23:0]rgb;
	wire [9:0]cx;
	wire [9:0]cy;
	wire [9:0]cx_next;
	wire [9:0]cy_next;

`ifdef TRUE_HDMI_EN
	wire [2:0]tmds;
	wire tmds_clock;
	hdmi #(
		.VIDEO_ID_CODE(1)
	) hdmi_hdl_util (
		.clk_pixel_x5(clk_tmds),
		.clk_pixel(clk_pix),
		.clk_audio(0),
		.rgb(rgb),
		.audio_sample_word({0, 0}),
		.tmds(tmds),
		.tmds_clock(tmds_clock),
		.cx(cx),
		.cy(cy)
	);
	assign cx_next = cx;
	assign cy_next = cy;
	OBUFDS #(.IOSTANDARD("TMDS_33")) obufds0 (.I(tmds[0]), .O(TMDSp[0]), .OB(TMDSn[0]));
	OBUFDS #(.IOSTANDARD("TMDS_33")) obufds1 (.I(tmds[1]), .O(TMDSp[1]), .OB(TMDSn[1]));
	OBUFDS #(.IOSTANDARD("TMDS_33")) obufds2 (.I(tmds[2]), .O(TMDSp[2]), .OB(TMDSn[2]));
	OBUFDS #(.IOSTANDARD("TMDS_33")) obufds_clock(.I(tmds_clock), .O(TMDSp_clock), .OB(TMDSn_clock));
`else
	hdmi_fpga4fun hdmi(
		.clk_pix(clk_pix), 
		.clk_tmds(clk_tmds), 
		.rgb(rgb), 
		.TMDSp(TMDSp), 
		.TMDSp_clock(TMDSp_clock), 
		.TMDSn(TMDSn), 
		.TMDSn_clock(TMDSn_clock), 
		.cx(cx), 
		.cy(cy),
		.cx_next(cx_next),
		.cy_next(cy_next)
	);
`endif

	// use upper blank memory address for mode control modes
	// TODO: use single word for bitwise control
	reg light_mode = 0;
	reg mono_mode = 0;
	reg [1:0]char_mode = 2'b11;
	always @ (posedge clk) begin
		if (rst) begin
			light_mode <= 0;
			mono_mode <= 0;
			char_mode <= 2'b11;
		end else begin
			if (we_ctrl) begin
				case (a[18:17])
					2'b01: light_mode <= data[0];
					2'b10: mono_mode <= data[0];
					2'b11: char_mode <= data[1:0];
					default: ;
				endcase
			end
		end
	end
	reg light_mode_pix;
	reg mono_mode_pix;
	reg [1:0]char_mode_pix;
	always @ (posedge clk_pix) begin
		light_mode_pix <= light_mode;
		mono_mode_pix <= mono_mode;
		char_mode_pix <= char_mode;
	end

	// framebuffer graphics
	// TODO: consider wasting some address space for 32-bit addr per pixel

	// the ID of the pixel. We're at 640x480 physically but only 320x240 are used, so /2
	wire [16:0]pix_a_pix = (cx/2) + cy/2 * 512/2 + cy/2 * 128/2;
	// pixel address in VRAM, each 32-bit contains 4 pixel so /4
	wire [14:0]pix_a_vram = pix_a_pix[16:2];

	// VRAM divided into two(64K + 16K) due to BRAM size, select the right one
	reg pix_a_last_sel;
	always @(posedge clk_2x) begin
		pix_a_last_sel <= pix_a_vram[14];
	end
	wire [31:0]pix_spo_l;
	wire [31:0]pix_spo_h;
	// fetched pixel data(4-in-1)
	wire [31:0]pix_data = pix_a_last_sel ? pix_spo_h : pix_spo_l;

	// select the one we need from four
	reg [7:0]pix_curr;
	always @ (*) begin case (pix_a_pix[1:0])
			2'b00: pix_curr = pix_data[7:0];
			2'b01: pix_curr = pix_data[15:8];
			2'b10: pix_curr = pix_data[23:16];
			2'b11: pix_curr = pix_data[31:24];
	endcase end
	// padding, as we're too low in resolution, and to have pure black/white
	wire [4:0]r_padding = light_mode_pix ? 
		(pix_curr[7:5] == 3'b000 ? 5'b0 : 5'b1) :
		(pix_curr[7:5] == 3'b111 ? 5'b1 : 5'b0);
	wire [4:0]g_padding = light_mode_pix ? 
		(pix_curr[4:2] == 3'b000 ? 5'b0 : 5'b1) :
		(pix_curr[4:2] == 3'b111 ? 5'b1 : 5'b0);
	wire [5:0]b_padding = light_mode_pix ? 
		(pix_curr[1:0] == 2'b00 ? 6'b0 : 6'b1) :
		(pix_curr[1:0] == 2'b11 ? 6'b1 : 6'b0);
	wire [23:0]pix_rgb = mono_mode_pix ? {
		pix_curr, pix_curr, pix_curr
	} : {
		{pix_curr[7:5], r_padding},
		{pix_curr[4:2], g_padding},
		{pix_curr[1:0], b_padding}
	};

	// 75KB total VRAM, supports 640x480 2bit monochrome color
	// or 320x240 8bit 3-3-2 color
	simple_dp_ram #(
		.WIDTH(32),
		.DEPTH(14)
	) vram_low64K (
		.clk1(clk),
		.a1(a[15:2]),
		.d1(data),
		.we1(we_vram & !a[16]),
		.clk2(clk_2x),
		.a2(pix_a_vram),
		.rd2(1),
		.spo2(pix_spo_l)
		//.ready()
	);
	simple_dp_ram#(
		.WIDTH(32),
		.DEPTH(12)
	) vram_high16K (
		.clk1(clk),
		.a1(a[15:2]),
		.d1(data),
		.we1(we_vram & a[16]),
		.clk2(clk_2x),
		.a2(pix_a_vram),
		.rd2(1),
		.spo2(pix_spo_h)
		//.ready()
	);

	// character terminal

	// my VRAM interface
	// 30 rows, 80 columns
	// the address for video display
	wire [11:0]char_a_v = ({6'b0, cy[9:4]}) * 80 + {5'b0, cx[9:3]};

	// character console RAM, 8KB
	wire [15:0]char_vram_spo;
	simple_dp_ram #(
	`ifdef OPENXC7
		.INIT("../../../firmware/bootrom/bootrom.dat"),
	`else
		.INIT("/home/petergu/quasiSoC/firmware/bootrom/bootrom.dat"),
	`endif
		.WIDTH(16),
		.DEPTH(12)
	) video_ram (
		.clk1(clk),
		.a1(FBEXT_ENABLE ? fb_a : a[13:2]),
		.d1(FBEXT_ENABLE ? fb_d : data[15:0]),
		.we1(FBEXT_ENABLE ? fb_we : we_char),
		.clk2(clk),
		.a2(char_a_v),
		.rd2(1),
		.spo2(char_vram_spo)
	);
	reg [3:0]pc_active;
	always @ (*) begin
		case (char_a_v[11:0])
			0: pc_active = dbg_pc[31:28];
			1: pc_active = dbg_pc[27:24];
			2: pc_active = dbg_pc[23:20];
			3: pc_active = dbg_pc[19:16];
			4: pc_active = dbg_pc[15:12];
			5: pc_active = dbg_pc[11:8];
			6: pc_active = dbg_pc[7:4];
			7: pc_active = dbg_pc[3:0];

			8: pc_active = dbg_instr[31:28];
			9: pc_active = dbg_instr[27:24];
			10: pc_active = dbg_instr[23:20];
			11: pc_active = dbg_instr[19:16];
			12: pc_active = dbg_instr[15:12];
			13: pc_active = dbg_instr[11:8];
			14: pc_active = dbg_instr[7:4];
			15: pc_active = dbg_instr[3:0];

			28: pc_active = dbg_ra[31:28];
			29: pc_active = dbg_ra[27:24];
			30: pc_active = dbg_ra[23:20];
			31: pc_active = dbg_ra[19:16];
			32: pc_active = dbg_ra[15:12];
			33: pc_active = dbg_ra[11:8];
			34: pc_active = dbg_ra[7:4];
			35: pc_active = dbg_ra[3:0];

			38: pc_active = dbg_rb[31:28];
			39: pc_active = dbg_rb[27:24];
			40: pc_active = dbg_rb[23:20];
			41: pc_active = dbg_rb[19:16];
			42: pc_active = dbg_rb[15:12];
			43: pc_active = dbg_rb[11:8];
			44: pc_active = dbg_rb[7:4];
			45: pc_active = dbg_rb[3:0];

			default: pc_active = 0;
		endcase
	end
	wire [7:0]pc_code = pc_active < 4'hA ? {4'h0, pc_active} + 8'h30 : {4'h0, pc_active} + 8'h57;
	
	// fetch rgb from glyphmap
	wire [23:0]char_rgb;
	console console(
		.clk_pixel(clk_pix), 
		.codepoint(char_vram_spo[7:0]), 
		//.codepoint(pc_code), 
		.attribute(char_vram_spo[15:8]), 
		//.attribute(16'h0F), 
		//.attribute({cx[9], cy[8:6], cx[8:5]}), 
		.cx(cx_next), 
		.cy(cy_next), 
		.rgb(char_rgb)
	);

	// finally, select which(picture mode or char mode), or both
	assign rgb = char_mode_pix == 2'b00 ? pix_rgb : 
		char_mode_pix == 2'b01 ? char_rgb : pix_rgb ^ char_rgb;


//(*mark_debug = "true"*) logic [23:0] rgb;
//logic [10:0]cx;
//logic [9:0]cy;
//(*mark_debug = "true"*) wire [9:0]cx_next;
//(*mark_debug = "true"*) wire [9:0]cy_next;
//hdmi #(
	//.VIDEO_ID_CODE(1), 
	//.DVI_OUTPUT(1),
	//.DDRIO(0)
	////.AUDIO_RATE(AUDIO_RATE), 
	////.AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH)
//) hdmi(
	//.clk_pixel_x10(clk_tmds), 
	//.clk_pixel(clk_pix), 
	//.clk_audio(0), 
	//.rgb(rgb), 
	////.audio_sample_word(0), 
	//.tmds_p(TMDSp), 
	//.tmds_clock_p(TMDSp_clock), 
	//.tmds_n(TMDSn), 
	//.tmds_clock_n(TMDSn_clock), 
	//.cx(cx), 
	//.cy(cy),
	//.cx_next(cx_next),
	//.cy_next(cy_next)
//);

//wire [9:0]cx_onscreen = cx_next - 160;
//wire [9:0] cy_onscreen = cy_next - 45;
endmodule
