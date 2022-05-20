/**
 * File              : aclint.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.01.25
 * Last Modified Date: 2022.05.18
 */
`timescale 1ns / 1ps
// quasiSoC core local interrupt controller
// 0: IPI
// 4000: CMP
// BFF8: VAL
// default 10MHz rate
`include "quasi.vh"

module aclint
	#(
		parameter CLOCK_FREQ = 62500000,
		parameter TIMER_COUNTER = 4000, // abandoned
		// default 10 MHz
		parameter TIMER_RATE = 10000000
		// slow...
		//parameter TIMER_RATE = 1000000
	)
    (
        input clk,
        input rst,

		input [15:0]a,
		input [31:0]d,
		input we,
		output [31:0]spo,

		output s_irq,
		output t_irq
    );

	wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};

	// mswi 0x0000 - 0x3fff
	// TODO: UNTESTED!
	reg msip0 = 0;
	assign s_irq = msip0;

	// mtime 0x4000 - 0xbfff
	// very crude timer
	localparam COUNT_RATE = CLOCK_FREQ / TIMER_RATE;
	reg [15:0]tic_reg = 0;
	wire tic = tic_reg == COUNT_RATE - 1;
    always @ (posedge clk) begin
        if (rst) begin
			tic_reg <= 0;
        end else begin
			if (tic_reg == COUNT_RATE - 1) tic_reg <= 0;
			else tic_reg <= tic_reg + 1;
        end
    end

	(*mark_debug = "true"*)reg [31:0]mtimel = 0;
	(*mark_debug = "true"*)reg [31:0]mtimeh = 0;
	(*mark_debug = "true"*)reg [31:0]mtimecmpl = 0;
	(*mark_debug = "true"*)reg [31:0]mtimecmph = 0;
	assign t_irq = (mtimeh > mtimecmph) | (mtimeh == mtimecmph & mtimel >= mtimecmpl);

	always @ (posedge clk) begin
		if (rst) begin
			msip0 <= 0;
			mtimel <= 0;
			mtimeh <= 0;
			mtimecmpl <= 32'hffffffff;
			mtimecmph<= 32'hffffffff;
		end else begin
			if (tic) begin
				if (mtimel == 32'hffffffff) begin
					mtimel <= 0;
					mtimeh <= mtimeh + 1;
				end else mtimel <= mtimel + 1;
			end

			if (we) begin
				case (a)
					16'h0000: msip0 <= data[0];
					16'h4000: mtimecmpl <= data;
					16'h4004: mtimecmph <= data;
					16'hbff8: mtimel <= data;
					16'hbffc: mtimeh <= data;
				endcase
			end
		end
	end

	reg [31:0]dout;
	always @ (*) begin
		case (a)
			16'h0000: dout = {31'b0, msip0};
			16'h4000: dout = mtimecmpl;
			16'h4004: dout = mtimecmph;
			16'hbff8: dout = mtimel;
			16'hbffc: dout = mtimeh;
			default: dout = 0;
		endcase
	end
	assign spo = {dout[7:0], dout[15:8], dout[23:16], dout[31:24]};

endmodule
