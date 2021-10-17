/**
 * File              : reset.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.24
 * Last Modified Date: 2021.01.24
 */
`timescale 1ns / 1ps


module reset
	(
		input clk,
		input rst_globl,

		//input [2:0]a,
		input [31:0]d,
		input we,
		//output reg [31:0]spo,

		output reg rst_gpio,
		output reg rst_uart,
		output reg rst_sdcard,
		output reg rst_video,
		output reg rst_usb,
		output reg rst_psram,
		output reg rst_interrupt,
		output reg rst_sb,
		output reg rst_timer,
		output reg rst_mmu
    );

	wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};
	
	reg rst_globl_reg = 1;

	// TODO: simplify
	always @ (posedge clk) begin
		if (rst_globl) begin
			{rst_gpio, rst_uart, rst_sdcard, rst_video, rst_usb, rst_psram, rst_interrupt, rst_sb, rst_timer, rst_mmu} <= 10'b1111111111;
			rst_globl_reg <= 1;
		end else if (we) {rst_gpio, rst_uart, rst_sdcard, rst_video, rst_usb, rst_psram, rst_interrupt, rst_sb, rst_timer, rst_mmu} <= data[9:0];
		else if (rst_globl_reg) begin
			{rst_gpio, rst_uart, rst_sdcard, rst_video, rst_usb, rst_psram, rst_interrupt, rst_sb, rst_timer, rst_mmu} <= 10'b0;
			rst_globl_reg <= 0;
		end
	end
endmodule
