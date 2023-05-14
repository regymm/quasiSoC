`timescale 1ns / 1ps
module mkrvidor4000_top
(
	input clk,
	input clk_2x,
	input rst,
	input clk_pix,
	input clk_tmds,

	input [31:0]a,
	input [31:0]d,
	input we,
	output logic [31:0]spo = 0,

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

	wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};

	wire [23:0]rgb;
	wire [9:0]cx;
	wire [9:0]cy;
	wire [9:0]cx_next;
	wire [9:0]cy_next;
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

	//wire [9:0]cx_onscreen = cx;
	//wire [9:0]cy_onscreen = cy;


	// use upper blank memory address for mode control modes
	reg light_mode = 0;
	reg mono_mode = 0;
	reg [1:0]char_mode = 0;
	always @ (posedge clk) begin
		if (rst) begin
			light_mode = 0;
			mono_mode = 0;
			char_mode = 0;
		end else begin
			if (we & a[23:22] == 2'b10) begin
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
		.we1(we & !a[16] & a[23:22] == 2'b00),
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
		.we1(we & a[16] & a[23:22] == 2'b00),
		.clk2(clk_2x),
		.a2(pix_a_vram),
		.rd2(1),
		.spo2(pix_spo_h)
		//.ready()
	);

	// character terminal!

	// my VRAM interface
	// 30 rows, 80 columns?
	// the address for video display
	(*mark_debug = "true"*) wire [11:0]char_a_v = ({6'b0, cy[9:4]}) * 80 + {5'b0, cx[9:3]};

	// character console RAM, 8KB
	wire [15:0]char_vram_spo;
	simple_dp_ram #(
		//.INIT("/home/petergu/quasiSoC/firmware/bootrom/bootrom.dat"),
		.WIDTH(16),
		.DEPTH(12)
	) video_ram (
		.clk1(clk),
		.a1(a[13:2]),
		.d1(data[15:0]),
		.we1(we & a[23:22] == 2'b01),
		.clk2(clk_2x),
		.a2(char_a_v),
		.rd2(1),
		.spo2(char_vram_spo)
	);
	
	// fetch rgb from glyphmap
	wire [23:0]char_rgb;
	console console(
		.clk_pixel(clk_pix), 
		.codepoint(char_vram_spo[7:0]), 
		.attribute(char_vram_spo[15:8]), 
		//.attribute({cx[9], cy[8:6], cx[8:5]}), 
		.cx(cx_next), 
		.cy(cy_next), 
		.rgb(char_rgb)
	);

	// finally, select which(picture mode or char mode), or both
	assign rgb = char_mode_pix == 2'b00 ? pix_rgb : 
		char_mode_pix == 2'b01 ? char_rgb : pix_rgb ^ char_rgb;

endmodule
