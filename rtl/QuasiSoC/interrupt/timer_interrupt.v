`timescale 1ns / 1ps
// pComputer timer interrupt unit
// 50ms interval under 125MHz clock
`include "quasi.vh"

module timer
	#(
		parameter TIMER_COUNTER = 4000
	)
    (
        input clk,
        input rst,

		input [2:0]a,
		input [31:0]d,
		input we,
		output reg [31:0]spo,

        output irq
    );

	reg irq_counter;
    reg [31:0]counter = 0;
    always @ (posedge clk) begin
        if (rst) begin
            counter <= 0;
            irq_counter <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == TIMER_COUNTER) begin
                counter <= 0;
                irq_counter <= 1;
            end
            else irq_counter <= 0;
        end
    end

	reg irq_cmp;
	always @ (posedge clk) begin
		if (mtimecmp == 1) irq_cmp <= 1;
		else irq_cmp <= 0;
	end

	reg irq_mode = 0;
	always @ (posedge clk) begin
		if (rst) irq_mode <= 0;
		else if (we & a == 3'b011) irq_mode <= (d != 0);
	end
	assign irq = irq_mode ? irq_cmp : irq_counter;

	reg [31:0]mtimel = 0;
	reg [31:0]mtimeh = 0;
	reg [31:0]mtimecmp = 0;

	always @ (posedge clk) begin
		if (rst) begin
			mtimel <= 0;
			mtimeh <= 0;
			mtimecmp <= 0;
		end else begin
			if (mtimel == 32'hffffffff) begin
				mtimel <= 0;
				mtimeh <= mtimeh + 1;
			end else mtimel <= mtimel + 1;

			if (we & a == 3'b010)
				mtimecmp <= {d[7:0], d[15:8], d[23:16], d[31:24]};
			else if (mtimecmp != 0)
				mtimecmp <= mtimecmp - 1;
		end
	end

	always @ (*) begin
		if (a == 3'b000)
			spo = {mtimel[7:0], mtimel[15:8], mtimel[23:16], mtimel[31:24]};
		else if (a == 3'b001)
			spo = {mtimeh[7:0], mtimeh[15:8], mtimeh[23:16], mtimeh[31:24]};
		else spo = 0;
	end

endmodule
