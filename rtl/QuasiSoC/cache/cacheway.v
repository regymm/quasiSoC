/**
 * File              : cacheway.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.xx.xx
 * Last Modified Date: 2021.06.24
 */
`timescale 1ns / 1ps
// pComputer LED/Switch IO

// one way of cache, 
// blocks as BRAM, tags as Dist. RAM
module cacheway
	#(
		parameter LINES=128,
		parameter WORDS_PER_BLOCK=32,
		parameter TAG_LENGTH=32
	)
    (
        input clk,
        input rst,

		input en,

        input [31:0]a,
        input [31:0]d,
        input we,
		//input rd,
        output [31:0]spo,

		input tag_we,
		input [TAG_LENGTH-1:0]tag_in,
		(*mark_debug = "true"*)output [TAG_LENGTH-1:0]tag_out,

		output init_done
    );

	wire [$clog2(WORDS_PER_BLOCK)-1:0]offset = a[$clog2(WORDS_PER_BLOCK)-1+2:2];
	wire [$clog2(LINES)-1:0]index = a[$clog2(LINES)-1+$clog2(WORDS_PER_BLOCK)+2:$clog2(WORDS_PER_BLOCK)+2];
	wire [$clog2(LINES * WORDS_PER_BLOCK)-1:0]bram_a = {index, offset};

	reg [TAG_LENGTH-1:0]tags[LINES-1:0];

	reg state;
	localparam INIT = 0;
	localparam INIT_DONE = 1;
	reg [$clog2(LINES)-1:0]count = 0;
	always @ (posedge clk) begin
		if (rst) begin
			state <= INIT;
			count <= 0;
		end
		else begin
			if (state == INIT) begin
				count <= count + 1;
				if (count == {($clog2(LINES)){1'b1}}) state <= INIT_DONE;
				tags[count] <= 0;
			end else
				if (en & tag_we) tags[index] <= tag_in;
		end
	end
	assign tag_out = tags[index];

	assign init_done = state;

	simple_ram #(
		.WIDTH(32),
		.DEPTH($clog2(LINES * WORDS_PER_BLOCK))
	) c_way_bram (
		.clk(clk),
		.a(bram_a),
		.d(d),
		.we(en & we),
		.rd(1),
		.spo(spo)
		//.ready(ready)
	);

endmodule
