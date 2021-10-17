/**
 * File              : gpio.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.11.25
 * Last Modified Date: 2020.11.25
 */
`timescale 1ns / 1ps
// pComputer LED/Switch IO

module gpio
    (
        input clk,
        input rst,
        input [3:0]a,
        input [31:0]d,
        input we,
        output reg [31:0]spo,

        input [1:0]btn, 
		input [1:0]sw,
        output reg [3:0]led,

		output reg irq = 0
    );

	wire [3:0]data = d[27:24];


	reg [1:0]btn_r;
	reg [1:0]sw_r;
	always @ (posedge clk) begin
		btn_r <= btn;
		sw_r <= sw;
	end

	reg [3:0]led_r[3:0];
	reg [3:0]count = 0;
	always @ (posedge clk) begin
		count <= count + 1;
	end
	genvar i;
	generate
		for(i = 0; i < 4; i = i + 1) begin
			always @ (posedge clk) begin
				if (led_r[i] > count) led[i] <= 1;
				else led[i] <= 0;
			end
		end
	endgenerate

    always @ (*) begin
        case (a)
            0: spo = {31'b0, btn_r[0]};
            1: spo = {31'b0, btn_r[1]};
            4: spo = {31'b0, sw_r[0]};
            5: spo = {31'b0, sw_r[1]};
            6: spo = {28'b0, led_r[0]};
            7: spo = {28'b0, led_r[1]};
            8: spo = {28'b0, led_r[2]};
			9: spo = {28'b0, led_r[3]};
            default: spo = 32'b0;
        endcase
    end

    always @ (posedge clk) begin
        if (rst) begin
			// medium dim light when begin
			led_r[0] <= 4'b0011;
			led_r[1] <= 4'b0011;
			led_r[2] <= 4'b0011;
			led_r[3] <= 4'b0011;
        end
        else if (we) begin
            case (a)
                6: led_r[0] <= data[3:0];
                7: led_r[1] <= data[3:0];
                8: led_r[2] <= data[3:0];
                9: led_r[3] <= data[3:0];
                default: ;
            endcase
        end
    end

	reg [3:0]inputs_reg;
	always @ (posedge clk) begin
		inputs_reg <= {btn_r, sw_r};
	end
	always @ (posedge clk) begin
		if (rst) irq <= 0;
		else if ((inputs_reg != {btn_r, sw_r}) & irq == 0) irq <= 1;
		else irq <= 0;
	end

endmodule
