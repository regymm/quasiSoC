/**
 * File              : timer_interrupt.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.01.25
 * Last Modified Date: 2022.01.25
 */
`timescale 1ns / 1ps
// quasiSoC core local interrupt controller
// 0: IPI
// 4000: CMP
// BFF8: VAL
// default 10MHz rate
`include "quasi.vh"

module timer
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
		output reg [31:0]spo,

		output s_irq,
		output t_irq // t_irq
    );

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

	//reg irq_mode = 0;
	//always @ (posedge clk) begin
		//if (rst) irq_mode <= 0;
		//else if (we & a == 3'b011) irq_mode <= (d != 0);
	//end
	//assign irq = irq_mode ? irq_cmp : irq_counter;
	//assign irq = 0;

	(*mark_debug = "true"*)reg [31:0]mtimel = 0;
	(*mark_debug = "true"*)reg [31:0]mtimeh = 0;
	(*mark_debug = "true"*)reg [31:0]mtimecmpl = 0;
	(*mark_debug = "true"*)reg [31:0]mtimecmph = 0;
	wire t_i_pending = (mtimeh > mtimecmph) | (mtimeh == mtimecmph & mtimel >= mtimecmpl);
	assign t_irq = t_i_pending;

	wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};

	//reg t_irq_rst = 0;

	always @ (posedge clk) begin
		if (rst) begin
			mtimel <= 0;
			mtimeh <= 0;
			mtimecmpl <= 32'hffffffff;
			mtimecmph<= 32'hffffffff;
			//t_irq_rst <= 0;
			//irq <= 0;
		end else begin
			if (tic) begin
				if (mtimel == 32'hffffffff) begin
					mtimel <= 0;
					mtimeh <= mtimeh + 1;
				end else mtimel <= mtimel + 1;
			end

			if (we) begin
				//t_irq_rst <= 1;
				case (a)
					16'h4000: mtimecmpl <= data;
					16'h4004: mtimecmph <= data;
					16'hbff8: mtimel <= data;
					16'hbffc: mtimeh <= data;
				endcase
			end
			//else if (t_i_pending & t_irq_rst == 1) begin
				//t_irq_rst <= 0;
				//irq <= 1;
			//end else begin
				//irq <= 0;
			//end
		end
	end

	always @ (*) begin
		case (a)
			16'h0000: spo = 0;
			16'h4000: spo = {mtimecmpl[7:0], mtimecmpl[15:8], mtimecmpl[23:16], mtimecmpl[31:24]};
			16'h4004: spo = {mtimecmph[7:0], mtimecmph[15:8], mtimecmph[23:16], mtimecmph[31:24]};
			16'hbff8: spo = {mtimel[7:0], mtimel[15:8], mtimel[23:16], mtimel[31:24]};
			16'hbffc: spo = {mtimeh[7:0], mtimeh[15:8], mtimeh[23:16], mtimeh[31:24]};
			default: spo = 0;
		endcase
	end

endmodule
