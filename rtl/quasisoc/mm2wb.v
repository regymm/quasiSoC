/**
 * File              : mm2wb.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2024.01.27
 * Last Modified Date: 2024.01.27
 */
`timescale 1ns / 1ps
`default_nettype wire

module mm2wb
	#(
		// TODO: this probably only work for 32-bit
		parameter ADDRLEN = 32,
		parameter DATALEN = 32
	)
    (
		input clk,
		input rst,

		// CPU bus is fixed 32-bit
		input [31:0]a,
		input [31:0]d,
		input we,
		input rd,
		output reg [31:0]spo,
		output ready,

		output reg wb_cyc,
		output reg wb_we,
		output reg wb_stb,
		output reg [ADDRLEN-1:0]wb_addr,
		output reg [DATALEN-1:0]wb_dat_o,
		output [DATALEN/8-1:0]wb_sel,
		input [DATALEN-1:0]wb_dat_i,
		input wb_stall, // stall may suddenly assert!
		input wb_ack,

		output reg irq = 0
    );
	assign wb_sel = 4'b1111;

	reg we_reg = 0;
	reg ready_reg = 1;

	localparam IDLE = 0;
	localparam DESTALL = 1;
	localparam BEGIN = 2;
	reg [1:0]state = IDLE;

	// UberDDR3 wb doens't use wb_cyc
    always @ (posedge clk) begin
		if (rst) begin
			state <= IDLE;
			wb_cyc <= 0;
			wb_stb <= 0;
			wb_we <= 0;
			we_reg <= 0;
			ready_reg <= 1;
			wb_addr <= 0;
			wb_dat_o <= 0;
			spo <= 0;
		end else if (state == IDLE & (rd | we)) begin
			if (!wb_stall) begin
				state <= BEGIN;
				wb_cyc <= 1;
				wb_stb <= 1;
				wb_we <= we;
			end else begin
				state <= DESTALL;
			end
			we_reg <= we;
			ready_reg <= 0;
			wb_addr <= a;
			wb_dat_o <= d;
		end else if (state == DESTALL & !wb_stall) begin
			state <= BEGIN;
			wb_cyc <= 1;
			wb_stb <= 1;
			wb_we <= we_reg;
		end else if (state == BEGIN) begin
			if (wb_stall) begin // come across a stall right in the head
				state <= DESTALL;
			end
			wb_stb <= 0;
			wb_we <= 0;
			if (wb_ack) begin
				wb_cyc <= 0;
				we_reg <= 0;
				ready_reg <= 1;
				if (!we_reg)
					spo <= wb_dat_i;
				state <= IDLE;
			end
		end
    end

	assign ready = ready_reg & !(we | rd);
endmodule
