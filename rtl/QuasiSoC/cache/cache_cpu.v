/**
 * File              : cache_cpu.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.xx.xx
 * Last Modified Date: 2021.07.22
 */
`timescale 1ns / 1ps
// pComputer LED/Switch IO

module cache_cpu
	#(
		parameter WAYS=1,
		parameter WAY_LINES=256,
		parameter WAY_WORDS_PER_BLOCK=32,
		parameter WAY_TAG_LENGTH=32
	)
    (
        input clk,
        input rst,

        input [31:0]a,
        input [31:0]d,
        input we,
		input rd,
        output [31:0]spo,
		output ready,

		output burst_en,
		output [7:0]burst_length,
		(*mark_debug = "true"*)output [31:0]lowmem_a,
		(*mark_debug = "true"*)output [31:0]lowmem_d,
		(*mark_debug = "true"*)output reg lowmem_we,
		(*mark_debug = "true"*)output reg lowmem_rd,
		(*mark_debug = "true"*)input [31:0]lowmem_spo,
		(*mark_debug = "true"*)input lowmem_ready

		//output hit,
		//output miss
    );

	(*mark_debug = "true"*)reg [31:0]hit_count;
	(*mark_debug = "true"*)reg [31:0]miss_count;
	always @ (posedge clk) begin
		if (rst) begin
			hit_count <= 0;
			miss_count <= 0;
		end else begin
			if (state == IDLE & (we | rd) & (| way_hit))
				hit_count <= hit_count + 1;
			if (state == IDLE & (we | rd) & !(| way_hit))
				miss_count <= miss_count + 1;
		end
	end

	localparam INIT = 0;
	localparam IDLE = 1;
	localparam HIT = 2;
	localparam LOAD = 3;
	localparam WRITEBACK = 4;
	(*mark_debug = "true"*)reg [3:0]state = INIT;

	assign spo = way_spo[0];
	assign ready = !(we | rd) & (state == IDLE);

	assign burst_en = 1;
	assign burst_length = WAY_WORDS_PER_BLOCK;
	// TODO;
	assign lowmem_a = {state == WRITEBACK ? burst_wb_base_a : host_a[31:$clog2(WAY_WORDS_PER_BLOCK)+2], {($clog2(WAY_WORDS_PER_BLOCK)+2){1'b0}}};
	assign lowmem_d = way_spo[0]; // TODO: set assoc

	wire quick_hit = (we | rd) & (| way_hit);

	(*mark_debug = "true"*)reg [WAYS-1:0]way_en;
	(*mark_debug = "true"*)reg way_we;
	(*mark_debug = "true"*)reg way_tag_we;
	reg way_valid_in;
	reg way_dirty_in;
	reg way_iord_in;
    always @ (*) begin
		way_en[0] = 0;
		way_we = 0;
		way_tag_we = 0;

		way_valid_in = 0;
		way_dirty_in = 0;
		way_iord_in = 0;

		lowmem_rd = 0;
		lowmem_we = 0;
		case (state)
			INIT: begin
			end
			IDLE: begin
				// make hit fast is important
				if (quick_hit) begin
					way_en[0] = 1;
					way_tag_we = 1;
					way_valid_in = 1;
					way_we = we;
					way_dirty_in =
						we ? 1 : way_tag_dirty;
					//way_iord_in = 0;
				end
			end
			HIT: begin
				way_en[0] = 1;
				way_tag_we = 1;
				way_valid_in = 1;
				way_we = host_weorrd;
				way_dirty_in = 
					host_weorrd ? 1 : way_tag_dirty;
			end
			LOAD: begin
				way_en[0] = 1;
				way_we = burst_we;
				way_tag_we = burst_issue; // abuse burst_issue a bit ...

				way_valid_in = 1;
				way_dirty_in = 0;

				lowmem_rd = burst_issue;
			end
			WRITEBACK: begin
				way_en[0] = 1;
				way_tag_we = burst_issue; // abuse burst_issue a bit ...

				way_valid_in = 1;
				way_dirty_in = 0;
				lowmem_we = burst_issue_delayed & !burst_issue;
			end
		endcase
    end


	(*mark_debug = "true"*)reg burst_issue = 0;
	reg burst_issue_delayed;
	reg [31-$clog2(WAY_WORDS_PER_BLOCK)-2:0]burst_wb_base_a;
	wire [31:0]burst_ld_a = {host_a[31:$clog2(WAY_WORDS_PER_BLOCK)+2], xfer_cnt[$clog2(WAY_WORDS_PER_BLOCK)-1:0], 2'b0};
	wire [31:0]burst_wb_a = {burst_wb_base_a, xfer_cnt[$clog2(WAY_WORDS_PER_BLOCK)-1:0], 2'b0};
	wire [31:0]burst_d = lowmem_spo;
	reg burst_we = 0;

	reg host_weorrd;
	reg [31:0]host_a = 0;
	(*mark_debug = "true"*)reg [31:0]host_d;

	reg [15:0]xfer_cnt = 0;

	always @ (posedge clk) begin
		burst_issue_delayed <= burst_issue;
	end

    always @ (posedge clk) begin
        if (rst) begin
			host_a <= 0;
			state <= INIT;
			xfer_cnt <= 0;
			burst_issue <= 0;
			burst_we <= 0;
        end
		else begin case(state)
			INIT: begin
				//if (way_init_done[0] == 1'b1 & lowmem_ready)
				// first r/w command will be sent 
				// before lowmem is ready -- so
				// lowmem must be able to latch r/w
				// TODO: elegant
				if (way_init_done[0] == 1'b1)
					state <= IDLE;
			end
			IDLE: begin
				xfer_cnt <= 0;
				burst_issue <= 1;
				if (we | rd) begin
					host_a <= a;
					host_d <= d;
					host_weorrd <= we;
					if (| way_hit) begin
						state <= IDLE; // one-cycle hit
					end else begin
						if (!way_tag_valid) begin
							state <= LOAD;
						end else if (!way_tag_dirty) begin
							state <= LOAD;
						end else if (way_tag_dirty) begin
							state <= WRITEBACK;
							burst_wb_base_a <= way_tag_addr[0];
						end
					end
				end
			end
			HIT: begin
				state <= IDLE;
				//spo <= way_spo[0]; // TODO: set assoc
			end
			WRITEBACK: begin
				if (burst_issue) begin
					burst_issue <= 0;
					xfer_cnt <= 0;
				end else begin
					if (lowmem_ready) begin
						xfer_cnt <= xfer_cnt + 1;
					end
					if (xfer_cnt == WAY_WORDS_PER_BLOCK) begin
						// xfer_cnt may overflow but don't care
						// this means all write are ready
						// (instead of last write just sent)
						state <= LOAD;
						burst_issue <= 1;
					end
				end
			end
			LOAD: begin
				if (burst_issue) begin
					burst_issue <= 0;
					xfer_cnt <= -1;
				end else begin
					if (lowmem_ready) begin
						xfer_cnt <= xfer_cnt + 1; // xfer_cnt + 1 is next burst_a address
						if (xfer_cnt == WAY_WORDS_PER_BLOCK - 1) begin
							burst_we <= 0;
							state <= HIT;
						end else begin
							burst_we <= 1;
						end
					end else burst_we <= 0;
				end
			end
		endcase end
    end

	wire [31:0]way_spo[WAYS-1:0];
	wire [WAY_TAG_LENGTH-1:0]way_tag_out[WAYS-1:0];
	wire [WAYS-1:0]way_init_done;

	wire [WAYS-1:0]way_tag_valid;
	wire [WAYS-1:0]way_tag_dirty;
	wire [WAYS-1:0]way_tag_iord;
	wire [31-($clog2(WAY_WORDS_PER_BLOCK)+2):0]way_tag_addr[WAYS-1:0];

	wire [WAYS-1:0]way_hit;

	wire bursting = (state == WRITEBACK | state == LOAD);
	wire [31:0]way_a = bursting ? (state == WRITEBACK ? burst_wb_a : burst_ld_a) : (state == IDLE ? a : host_a); // here the WRITEBACK judgement seems useless, because when writeback is needed(in case cache conflict) burst_wb_a and burst_ld_a should be literally the same for way RAM, as way tag which will soon be overwriten during LOAD state don't matter. No need to fix until there's some extra "manual writeback" functionality. 
	wire [31:0]way_d = bursting ? burst_d : (state == IDLE ? d : host_d);
	wire [$clog2(WAY_WORDS_PER_BLOCK)+2-1 - 3:0]way_zeros = 0;
	wire [31:0]way_tag_in = {
		a[31:$clog2(WAY_WORDS_PER_BLOCK)+2],
		way_zeros,
		way_iord_in,
		way_dirty_in,
		way_valid_in};

	//genvar i;
	//generate
		//for (i = 0; i < WAYS; i = i + 1) begin
			cacheway #(
				.LINES(WAY_LINES),
				.WORDS_PER_BLOCK(WAY_WORDS_PER_BLOCK),
				.TAG_LENGTH(WAY_TAG_LENGTH)
			) way_gen (
				.clk(clk),
				.rst(rst),
				.en(way_en[0]),
				.a(way_a),
				.d(way_d),
				.we(way_we),
				.spo(way_spo[0]),
				.tag_we(way_tag_we),
				.tag_in(way_tag_in),
				.tag_out(way_tag_out[0]),
				.init_done(way_init_done[0])
			);

			assign way_tag_valid[0] = way_tag_out[0][0];
			assign way_tag_dirty[0] = way_tag_out[0][1];
			assign way_tag_iord[0] = way_tag_out[0][2];
			assign way_tag_addr[0] = way_tag_out[0][31:$clog2(WAY_WORDS_PER_BLOCK)+2];
			assign way_hit[0] = way_tag_valid[0] & (way_tag_addr[0] == a[31:$clog2(WAY_WORDS_PER_BLOCK)+2]);
		//end
	//endgenerate


endmodule
