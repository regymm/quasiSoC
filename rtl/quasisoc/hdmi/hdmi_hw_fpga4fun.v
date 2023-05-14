`timescale 1ns / 1ps

module hdmi_fpga4fun
    (
        input clk_pix, // 25MHz
        input clk_tmds, // 250MHz

		input [23:0]rgb,

		output reg [9:0]cx, // 0 to 799
		output reg [9:0]cy, // 0 to 524
		output [9:0]cx_next,
		output [9:0]cy_next,

        // 8 differential signals output
        output [2:0] TMDSp, TMDSn,
        output TMDSp_clock, TMDSn_clock
    );

	// 800x525 frame counter
	assign cx_next = cx == 799 ? 0 : cx + 1;
	assign cy_next = cx == 799 ? ((cy == 524) ? 0 : cy + 1) : cy;
	always @ (posedge clk_pix) begin
		cx <= cx_next;
		cy <= cy_next;
	end
	wire hSync = (cx >= 656) & (cx < 752);
	wire vSync = (cy >= 490) & (cy < 492);
	wire DrawArea = (cx < 640) & (cy < 480);

	//hdmi_char_term hdmi_char_term_inst(
		//.red(red),
		//.green(green),
		//.blue(blue),
		//.counterX(counterX),
		//.counterY(counterY)
	//);

	//wire [7:0] red = {counterX[5:0] & {6{counterY[4:3]==~counterX[4:3]}}, 2'b00};
	//wire [7:0] green = counterX[7:0] & {8{counterY[6]}};
	//wire [7:0] blue = counterY[7:0];
	
	wire [7:0]red = rgb[23:16];
	wire [7:0]green = rgb[15:8];
	wire [7:0]blue = rgb[7:0];

	wire [9:0] TMDS_red, TMDS_green, TMDS_blue;

	TMDS_encoder encode_R(
		.clk(clk_pix),
		.VD(red),
		.TMDS(TMDS_red),
		.CD(2'b00),
		.VDE(DrawArea)
	);
	TMDS_encoder encode_G(
		.clk(clk_pix),
		.VD(green),
		.TMDS(TMDS_green),
		.CD(2'b00),
		.VDE(DrawArea)
	);
	TMDS_encoder encode_B(
		.clk(clk_pix),
		.VD(blue),
		.TMDS(TMDS_blue),
		.CD({vSync,hSync}),
		.VDE(DrawArea)
	);

	reg [3:0]TMDS_mod10 = 0;
	reg [9:0]TMDS_shift_red = 0, TMDS_shift_green = 0, TMDS_shift_blue = 0;
	reg TMDS_shift_load = 0;
	//wire TMDS_shift_load = (TMDS_mod10 == 0);

	// output 
	// shift registers: 10 bits per pixclock cycle
	always @(posedge clk_tmds) begin
		TMDS_mod10 <= (TMDS_mod10 == 4'd9) ? 4'd0 : TMDS_mod10 + 4'd1;
		TMDS_shift_load <= (TMDS_mod10 == 4'd9);
		if (TMDS_shift_load) begin
			TMDS_shift_red <= TMDS_red;
			TMDS_shift_green <= TMDS_green;
			TMDS_shift_blue <= TMDS_blue;
		end
		else begin
			TMDS_shift_red <= {1'b0, TMDS_shift_red[9:1]};
			TMDS_shift_green <= {1'b0, TMDS_shift_green[9:1]};
			TMDS_shift_blue <= {1'b0, TMDS_shift_blue[9:1]};
		end
	end

	OBUFDS OBUFDS_red(
		.I(TMDS_shift_red[0]),
		.O(TMDSp[2]),
		.OB(TMDSn[2])
	);
	OBUFDS OBUFDS_green(
		.I(TMDS_shift_green[0]),
		.O(TMDSp[1]),
		.OB(TMDSn[1])
	);
	OBUFDS OBUFDS_blue(
		.I(TMDS_shift_blue[0]),
		.O(TMDSp[0]),
		.OB(TMDSn[0])
	);
	OBUFDS OBUFDS_clock(
		.I(clk_pix),
		.O(TMDSp_clock),
		.OB(TMDSn_clock)
	);

endmodule

module TMDS_encoder
	(
		input clk,
		input [7:0] VD,  // video data (red, green or blue)
		input [1:0] CD,  // control data
		input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
		output reg [9:0] TMDS = 0
	);

	wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
	wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
	wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};

	reg [3:0] balance_acc = 0;
	wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
	wire balance_sign_eq = (balance[3] == balance_acc[3]);
	wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
	wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
	wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
	wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
	wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);

	always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
	always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;
endmodule
