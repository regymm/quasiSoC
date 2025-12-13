/**
 * File              : sdram_br.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2024.05.26
 * Last Modified Date: 2024.05.26
 */
`timescale 1ns / 1ps
`default_nettype wire

// a:
// 0x1000
// 0x1004
//
// data_address (DATA_WIDTH=8):
// 0x1000 -> 0x1000, 0x1001, 0x1002, 0x1003
// 0x1004 -> 0x1004, ...
//
// data_address (DATA_WIDTH=16):
// 0x1000 -> 0x800, 0x801
// 0x1004 -> 0x802, 0x803
//
// LSB(7:0) at low address
// ONLY 16-bit TESTED FOR NOW!

module sdram_br #(
	parameter DATA_WIDTH = 16
) (
		input clk,
		input rst,

		input [31:0]a, // as convention, a is 32-bit aligned
		input [31:0]d,
		input we,
		input rd,
		output reg [31:0]spo,
		output ready,

		output reg [1:0]command,
		output reg [31:0]data_address,
		output reg [31:0]data_write, // abuse the 32-bit bus a little bit
		input [DATA_WIDTH-1:0]data_read,
		input data_read_valid,
		input data_write_done
    );
	reg we_reg = 0;
	reg ready_reg = 1;
	reg [5:0]cnt = 0;

	localparam CNT = 32 / DATA_WIDTH; // 16-bit case: 2
	localparam ASHIFT = $clog2(CNT); // 16-bit case: 1
	localparam IDLE = 0;
	localparam BEGIN = 1;
	reg state = IDLE;

    always @ (posedge clk) begin
		if (rst) begin
			state <= IDLE;
			command <= 2'b00;
			we_reg <= 0;
			ready_reg <= 1;
			data_address <= 0;
			data_write <= 0;
			spo <= 0;
			cnt <= 0;
		end else if (state == IDLE & (rd | we)) begin
			state <= BEGIN;
			command <= we ? 2'b01 : 2'b10;
			data_address <= {{ASHIFT{1'b0}}, a[31:ASHIFT]};
			data_write <= we ? d : 0;
			we_reg <= we;
			ready_reg <= 0;
			cnt <= 0;
		end else if (state == BEGIN) begin
			spo <= we_reg ? 0 : {data_read, spo[31:32-DATA_WIDTH]};
			if (we_reg & data_write_done) begin
				data_write <= {{DATA_WIDTH{1'b0}}, data_write[31:DATA_WIDTH]};
				cnt <= cnt + 1;
				if (cnt == CNT - 1) begin
					state <= IDLE;
					we_reg <= 0;
					ready_reg <= 1;
					command <= 2'b00;
				end
			end else if (data_read_valid) begin
                cnt <= cnt + 1;
                if (cnt == CNT - 1) begin
				    state <= IDLE;
				    ready_reg <= 1;
				    command <= 2'b00;
				end
			end
		end
    end

	assign ready = ready_reg & !(we | rd);
endmodule
