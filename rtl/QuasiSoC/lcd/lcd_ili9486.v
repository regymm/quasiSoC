/**
 * File              : ili9486.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2021.07.xx
 * Last Modified Date: 2022.01.31
 */
`timescale 1ns / 1ps
// ILI9486 8-bit parallel interface LCD module
// commonly used for Arduino Uno
// software care-free, everything done in FPGA

module lcd_ili9486
(
	input clk,
	input rst,

	input [31:0]a,
	input [31:0]d,
	input we,
	output [31:0]spo,

	output [7:0]lcd_d,
	output rd, // = 1
	output wr,
	output rs,
	output cs, // = 0
	output lcd_rst
);

	wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};

	reg [27:0]cnt = 0;

	reg [1:0]mode = 0; // 0: dark(default), 1: light, 2: mono

	wire [27:0]pix_xfer_idx = {2'b0, cnt[27:2]};
	wire [15:0]pix_a = pix_xfer_idx[17:2];
	wire [31:0]pix_spo_l;
	wire [31:0]pix_spo_h;
	wire [31:0]pix_spo = pix_a[15] ? pix_spo_h : pix_spo_l;
	//wire [31:0]pix_spo = 32'hdeadbeef;
	reg [7:0]pixel;
	always @ (*) begin case (pix_xfer_idx[1:0])
		2'b00: pixel = pix_spo[7:0];
		2'b01: pixel = pix_spo[15:8];
		2'b10: pixel = pix_spo[23:16];
		2'b11: pixel = pix_spo[31:24];
	endcase end
	wire [4:0]r = {pixel[7:5], pixel[5] ? 2'b11 : 2'b00};
	wire [5:0]g = {pixel[4:2], pixel[2] ? 3'b111: 3'b000};
	wire [4:0]b = {pixel[1:0], pixel[0] ? 3'b111 : 3'b000};

	// frame buffer memory: 128 + 32 ~ 153.6 KB
	// TODO: color palette? 256-entry array?
	simple_dp_ram #(
		.WIDTH(32),
		.DEPTH(15)
	) vram_low128K (
		.clk1(clk),
		.a1(a[16:2]),
		.d1(data),
		.we1(we & !a[17]),
		.clk2(clk),
		.a2(pix_a),
		.rd2(1),
		.spo2(pix_spo_l)
	);
	simple_dp_ram #(
		.WIDTH(32),
		.DEPTH(13)
	) vram_high32K (
		.clk1(clk),
		.a1(a[16:2]),
		.d1(data),
		.we1(we & a[17]),
		.clk2(clk),
		.a2(pix_a),
		.rd2(1),
		.spo2(pix_spo_h)
	);
	//simple_dp_ram #(
		//.WIDTH(16),
		//.DEPTH(8)
	//) color_palette_4K (
		//.clk1(clk),
		//.a1(),
		//.d1(),
		//.we1(),
		//.clk2(clk),
		//.a2(),
		//.rd2(1),
		//.spo2()
	//);

	reg [1:0]clk_reg = 0;
	always @ (posedge clk) begin
		clk_reg <= clk_reg + 1;
	end
	wire clk_en = (clk_reg[1:0] == 0);

	localparam RST = 0;
	localparam SLPOUT = 1;
	localparam DISPON = 2;
	localparam MAC = 3;
	localparam COLMOD = 4;
	localparam VOLT_1 = 5;
	localparam VOLT_2 = 6;
	//localparam CLEAR_1 = 7;
	//localparam CLEAR_2 = 8;
	localparam IDLE = 9;
	localparam CAS = 10;
	localparam PAS = 11;
	localparam SEND_C = 12;
	localparam SEND_D = 13;
	localparam WCHAR = 14;
	localparam WCHAR_MEM = 15;
	//localparam CLR_LINE_1 = 15;
	//localparam CLR_LINE_2 = 16;
	//localparam DRAW_CURSOR = 17;
	//localparam CLR_CURSOR = 18;
	//localparam CURSOR_MEM = 19;
	localparam GAMMA_1 = 20;
	localparam GAMMA_2 = 21;
	//localparam SCROLL = 22;
	localparam CAS_INIT = 22;
	localparam PAS_INIT = 23;
	reg [5:0]state = RST;
	reg [5:0]state_ret;
	reg [5:0]state_ret_stash;

	reg [7:0]command;
	reg [27:0]param_num;
	reg [7:0]param;

	assign lcd_rst = !rst;
	assign rd = 1; // we never read
	assign rs = !(state == SEND_C); // command or data
	assign cs = 0; // we always select //assign cs = !(state == SEND_C | state == SEND_D);
	assign wr = !((state == SEND_C & cnt[0] == 0) | (state == SEND_D & cnt[0] == 0 & param_num != 0)); // write
	assign lcd_d = !rs ? command : param;

	localparam SOFT_RESET = 8'h01;
	localparam SLEEP_OUT = 8'h11;
	localparam DISPLAY_ON = 8'h29;
	localparam MEM_ACCESS_CTRL = 8'h36;
	localparam IF_PIXEL_FMT = 8'h3A;
	localparam COLUMN_A_SET = 8'h2A;
	localparam PAGE_A_SET = 8'h2B;
	localparam MEM_WRITE = 8'h2C;
	//localparam MEM_WRITE_CONT = 8'h3C;
	localparam PGAMCTRL = 8'hE0;
	localparam NGAMCTRL = 8'hE1;
	localparam PWRCTRL2 = 8'hC1;
	localparam VCOMCTRL = 8'hC5;
	//localparam VERTICAL_SCROLL = 8'h37;

	wire [15:0]cas_sc = 0;
	wire [15:0]cas_ec = 479;
	wire [15:0]pas_sp = 0;
	wire [15:0]pas_ep = 319;

	always @ (*) begin
		param = 8'h00;
		case (command)
			MEM_ACCESS_CTRL: param = 8'h28;
			IF_PIXEL_FMT: param = 8'h55;
			PWRCTRL2: param = 8'h41;
			VCOMCTRL: begin case (param_num)
				4: param = 8'h00;
				3: param = 8'h91;
				2: param = 8'h80;
				1: param = 8'h00;
			endcase end
			PGAMCTRL: begin case (param_num)
				15: param = 8'h0F;
				14: param = 8'h1F;
				13: param = 8'h1C;
				12: param = 8'h0C;
				11: param = 8'h0F;
				10: param = 8'h08;
				9: param = 8'h48;
				8: param = 8'h98;
				7: param = 8'h37;
				6: param = 8'h0A;
				5: param = 8'h13;
				4: param = 8'h04;
				3: param = 8'h11;
				2: param = 8'h0D;
				1: param = 8'h00;
			endcase end
			NGAMCTRL: begin case (param_num)
				15: param = 8'h0F;
				14: param = 8'h32;
				13: param = 8'h2E;
				12: param = 8'h0B;
				11: param = 8'h0D;
				10: param = 8'h05;
				9: param = 8'h47;
				8: param = 8'h75;
				7: param = 8'h37;
				6: param = 8'h06;
				5: param = 8'h10;
				4: param = 8'h03;
				3: param = 8'h24;
				2: param = 8'h20;
				1: param = 8'h00;
			endcase end
			COLUMN_A_SET: begin case (param_num)
				4: param = cas_sc[15:8];
				3: param = cas_sc[7:0];
				2: param = cas_ec[15:8];
				1: param = cas_ec[7:0];
			endcase end
			PAGE_A_SET: begin case (param_num)
				4: param = pas_sp[15:8];
				3: param = pas_sp[7:0];
				2: param = pas_ep[15:8];
				1: param = pas_ep[7:0];
			endcase end
			MEM_WRITE: begin
				param = cnt[1] == 0 ? {r, g[5:3]} : {g[2:0], b};
			end
		endcase
	end

	localparam DBG = 0;
	localparam NCNT = DBG ? 1 : 800000;
	localparam DRAW_COUNT = DBG ? 200 : 2*480*320;

	always @ (posedge clk) begin
		if (rst) begin
			state <= RST;
		end else if (clk_en) begin
			case (state)
				RST: begin
					state <= SEND_C;
					command <= SOFT_RESET;
					param_num <= 0;
					state_ret <= SLPOUT;
					cnt <= 0;
				end
				SLPOUT: begin
					if (cnt > 5*NCNT) begin
						state <= SEND_C;
						command <= SLEEP_OUT;
						param_num <= 0;
						state_ret <= DISPON;
						cnt <= 0;
					end else begin
						cnt <= cnt + 1;
					end
				end
				DISPON: begin
					if (cnt > 5*NCNT) begin
						state <= SEND_C;
						command <= DISPLAY_ON;
						param_num <= 0;
						state_ret <= MAC;
						cnt <= 0;
					end else begin
						cnt <= cnt + 1;
					end
				end
				MAC: begin
					state <= SEND_C;
					command <= MEM_ACCESS_CTRL;
					param_num <= 1;
					state_ret <= COLMOD;
					cnt <= 0;
				end
				COLMOD: begin
					state <= SEND_C;
					command <= IF_PIXEL_FMT;
					param_num <= 1;
					state_ret <= VOLT_1;
					cnt <= 0;
				end
				VOLT_1: begin
					state <= SEND_C;
					command <= PWRCTRL2;
					param_num <= 1;
					state_ret <= VOLT_2;
					cnt <= 0;
				end
				VOLT_2: begin
					state <= SEND_C;
					command <= VCOMCTRL;
					param_num <= 4;
					state_ret <= GAMMA_1;
					cnt <= 0;
				end
				GAMMA_1: begin
					state <= SEND_C;
					command <= PGAMCTRL;
					param_num <= 15;
					state_ret <= GAMMA_2;
					cnt <= 0;
				end
				GAMMA_2: begin
					state <= SEND_C;
					command <= NGAMCTRL;
					param_num <= 15;
					state_ret <= CAS_INIT;
					cnt <= 0;
				end
				CAS_INIT: begin
					state <= SEND_C;
					command <= COLUMN_A_SET;
					param_num <= 4;
					state_ret <= PAS_INIT;
					cnt <= 0;
				end
				PAS_INIT: begin
					state <= SEND_C;
					command <= PAGE_A_SET;
					param_num <= 4;
					state_ret <= IDLE;
					cnt <= 0;
				end
				IDLE: begin // handle FPGA signals
					//if (we & a[23:16] == 8'hFF) state <= WCHAR_MEM;
					//cnt <= cnt + 1;
					//if (cnt >= 10) state <= WCHAR_MEM;
					state <= WCHAR_MEM;
				end
				//DRAW_CURSOR: begin
					//o_cursor <= 1;
					//d_cursor <= 1;
					//state <= CAS;
					//state_ret <= CURSOR_MEM;
					//cnt <= 0;
				//end
				//CLR_CURSOR: begin
					//o_cursor <= 1;
					//d_cursor <= 0;
					//state <= CAS;
					//state_ret <= CURSOR_MEM;
					//cnt <= 0;
				//end
				//CURSOR_MEM: begin
					//state <= SEND_C;
					//command <= MEM_WRITE;
					//param_num <= DRAW_C_COUNT;
					//state_ret <= IDLE;
					//cnt <= 0;
				//end
				CAS: begin
					state <= SEND_C;
					command <= COLUMN_A_SET;
					param_num <= 4;
					state_ret_stash <= state_ret;
					state_ret <= PAS;
					cnt <= 0;
				end
				PAS: begin
					state <= SEND_C;
					command <= PAGE_A_SET;
					param_num <= 4;
					state_ret <= state_ret_stash;
					cnt <= 0;
				end
				WCHAR: begin
					state <= CAS;
					state_ret <= WCHAR_MEM;
					cnt <= 0;
				end
				WCHAR_MEM: begin
					state <= SEND_C;
					state_ret <= IDLE;
					command <= MEM_WRITE;
					param_num <= DRAW_COUNT; // 6*7 * 2
					//param_num <= 108; // 6*9 * 2
					cnt <= 0;
				end
				SEND_C: begin
					if (cnt == 1) begin // 
						cnt <= 0;
						if (param_num == 0) state <= state_ret;
						else state <= SEND_D;
					end else 
						cnt <= cnt + 1;
				end
				SEND_D: begin
					if (param_num == 0) begin
						state <= state_ret;
						cnt <= 0;
					end else begin
						cnt <= cnt + 1;
						if (cnt[0] == 1) begin
							param_num <= param_num - 1;
						end
					end
				end
				default: state <= IDLE;
			endcase
		end
	end

endmodule
	//// 6x8 font terminal
	//reg [6:0]charcol = 0;
	//reg [5:0]charrow = 0; // begin from laaaast line

	//wire [6:0]charcol_next = charcol == 79 ? 0 : (charcol + 1);
	//wire [5:0]charrow_next = charcol == 79 ? (charrow == 39 ? 0 : charrow + 1) : charrow;

	//reg [7:0]char;
	//wire [41:0]char_pixel = 
		//char == 9'h20 ? 42'b000000000000000000000000000000000000000000 :
		//char == 8'h21 ? 42'b011000011000011000011000000000010000011000 :
		//char == 8'h22 ? 42'b010100010100010100000000000000000000000000 :
		//char == 8'h23 ? 42'b010100111110010100010100010100111110010100 :
		//char == 8'h24 ? 42'b010000111100100000111100000100111100001000 :
		//char == 8'h25 ? 42'b110010110100000100001000010000110110100110 :
		//char == 8'h26 ? 42'b011000100100100000010000101010100100011010 :
		//char == 8'h27 ? 42'b001000001000001000000000000000000000000000 :
		//char == 8'h28 ? 42'b000100001000010000010000010000001000000100 :
		//char == 8'h29 ? 42'b010000001000000100000100000100001000010000 :
		//char == 8'h2a ? 42'b000000100010010100111110010100100010000000 :
		//char == 8'h2b ? 42'b000000001000001000111110001000001000000000 :
		//char == 8'h2c ? 42'b000000000000000000000000011000011000110000 :
		//char == 8'h2d ? 42'b000000000000000000111110000000000000000000 :
		//char == 8'h2e ? 42'b000000000000000000000000000000011000011000 :
		//char == 8'h2f ? 42'b000010000110001100001000011000110000100000 :
		//char == 8'h30 ? 42'b011100100010100010101010100010100010011100 :
		//char == 8'h31 ? 42'b001000011000001000001000001000001000011100 :
		//char == 8'h32 ? 42'b011100100010000010000100001000010000111110 :
		//char == 8'h33 ? 42'b011100100010000010001100000010100010011100 :
		//char == 8'h34 ? 42'b000100001100010100100100111110000100000100 :
		//char == 8'h35 ? 42'b111110100000100000111100000010100010011100 :
		//char == 8'h36 ? 42'b011100100010100000111100100010100010011100 :
		//char == 8'h37 ? 42'b111110100010000100001000010000010000010000 :
		//char == 8'h38 ? 42'b011100100010100010111110100010100010011100 :
		//char == 8'h39 ? 42'b011100100010100010011110000010000100011000 :
		//char == 8'h3a ? 42'b000000011000011000000000011000011000000000 :
		//char == 8'h3b ? 42'b000000011000011000000000011000001000010000 :
		//char == 8'h3c ? 42'b000100001000010000100000010000001000000100 :
		//char == 8'h3d ? 42'b000000000000111110000000111110000000000000 :
		//char == 8'h3e ? 42'b100000010000001000000100001000010000100000 :
		//char == 8'h3f ? 42'b011100100010100010001100001000000000001000 :
		//char == 8'h40 ? 42'b011100100010101110101010101110100000011100 :
		//char == 8'h41 ? 42'b001000010100100010100010111110100010100010 :
		//char == 8'h42 ? 42'b111100100010100010111100100010100010111100 :
		//char == 8'h43 ? 42'b011100100010100000100000100000100010011100 :
		//char == 8'h44 ? 42'b111100100010100010100010100010100010111100 :
		//char == 8'h45 ? 42'b111110100000100000111100100000100000111110 :
		//char == 8'h46 ? 42'b111110100000100000111100100000100000100000 :
		//char == 8'h47 ? 42'b011100100010100000101110100010100010011100 :
		//char == 8'h48 ? 42'b100010100010100010111110100010100010100010 :
		//char == 8'h49 ? 42'b011100001000001000001000001000001000011100 :
		//char == 8'h4a ? 42'b000100000100000100000100000100100100011000 :
		//char == 8'h4b ? 42'b100010100100101000110000101000100100100010 :
		//char == 8'h4c ? 42'b100000100000100000100000100000100010111110 :
		//char == 8'h4d ? 42'b100010110110101010100010100010100010100010 :
		//char == 8'h4e ? 42'b100010110010101010101010101010100110100010 :
		//char == 8'h4f ? 42'b011100100010100010100010100010100010011100 :
		//char == 8'h50 ? 42'b111100100010100010111100100000100000100000 :
		//char == 8'h51 ? 42'b011100100010100010100010101010100100011010 :
		//char == 8'h52 ? 42'b111100100010100010111100101000100100100010 :
		//char == 8'h53 ? 42'b011100100010100000011100000010100010011100 :
		//char == 8'h54 ? 42'b111110001000001000001000001000001000001000 :
		//char == 8'h55 ? 42'b100010100010100010100010100010100010011100 :
		//char == 8'h56 ? 42'b100010100010100010100010110110011100001000 :
		//char == 8'h57 ? 42'b100010100010100010101010101010110110100010 :
		//char == 8'h58 ? 42'b100010010100010100001000010100010100100010 :
		//char == 8'h59 ? 42'b100010100010100010010100001000001000001000 :
		//char == 8'h5a ? 42'b111110000010000100001000010000100000111110 :
		//char == 8'h5b ? 42'b011100010000010000010000010000010000011100 :
		//char == 8'h5c ? 42'b100000110000010000011000001100000110000010 :
		//char == 8'h5d ? 42'b011100000100000100000100000100000100011100 :
		//char == 8'h5e ? 42'b001000010100100010000000000000000000000000 :
		//char == 8'h5f ? 42'b000000000000000000000000000000000000111110 :
		//char == 8'h60 ? 42'b010000011000001100000000000000000000000000 :
		//char == 8'h61 ? 42'b000000000000111000000100111100100100011010 :
		//char == 8'h62 ? 42'b000000100000100000111000100100100100111000 :
		//char == 8'h63 ? 42'b000000000000000000011100100000100000011100 :
		//char == 8'h64 ? 42'b000000000100000100011100100100100100011000 :
		//char == 8'h65 ? 42'b000000000000011100100010111100100000011100 :
		//char == 8'h66 ? 42'b001100010000010000111100010000010000010000 :
		//char == 8'h67 ? 42'b000000011100100010100110011010000010011100 :
		//char == 8'h68 ? 42'b100000100000100000111000100100100100100100 :
		//char == 8'h69 ? 42'b000000001000000000011000001000001000001000 :
		//char == 8'h6a ? 42'b001000000000011000001000001000101000011000 :
		//char == 8'h6b ? 42'b100000100000100000101000110000101000100100 :
		//char == 8'h6c ? 42'b110000010000010000010000010000010000001100 :
		//char == 8'h6d ? 42'b000000000000110100101010101010101010101010 :
		//char == 8'h6e ? 42'b000000000000111000100100100100100100100100 :
		//char == 8'h6f ? 42'b000000000000011000100100100100100100011000 :
		//char == 8'h70 ? 42'b000000000000111000100100100100111000100000 :
		//char == 8'h71 ? 42'b000000000000011100100100100100011100000100 :
		//char == 8'h72 ? 42'b000000000000101100110000100000100000100000 :
		//char == 8'h73 ? 42'b000000000000011100100000011000000100111000 :
		//char == 8'h74 ? 42'b000000010000111100010000010000010100011000 :
		//char == 8'h75 ? 42'b000000000000100100100100100100100100011100 :
		//char == 8'h76 ? 42'b000000000000100100100100100100010100001000 :
		//char == 8'h77 ? 42'b000000000000100010100010100010101010010100 :
		//char == 8'h78 ? 42'b000000000000100100100100011000100100100100 :
		//char == 8'h79 ? 42'b000000000000100100100100011100000100111000 :
		//char == 8'h7a ? 42'b000000000000111100000100011000100000111100 :
		//char == 8'h7b ? 42'b000100001000001000010000001000001000000100 :
		//char == 8'h7c ? 42'b001000001000001000001000001000001000001000 :
		//char == 8'h7d ? 42'b010000001000001000000100001000001000010000 :
		//char == 8'h7e ? 42'b000000000000011010101100000000000000000000 :
		//{char[7:4], 2'b10, char[3:0], 8'b10111110, 24'b0};
	//wire curr_pixel = char_pixel[41-(cnt>>2)];
	////wire curr_pixel = cnt > 24 ? char_pixel[53-(cnt>>2)] : 0;
	//wire [4:0]r = 5'b11111;
	//wire [5:0]g = 6'b111111;
	//wire [4:0]b = 5'b11111;
