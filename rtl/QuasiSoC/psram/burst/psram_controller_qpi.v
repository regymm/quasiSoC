/**
 * File              : psram_controller_simple.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.10.21
 * Last Modified Date: 2020.12.01
 */
// pComputer SPI PSRAM(ESP-PSRAM64H) controller
// 64Mbit, A[22:0]
// QPI mode, high clock freq

`timescale 1ns / 1ps
//`define SIMULATION

module psram_controller_fast
	#(
		// TODO: elegant
		parameter BOOT_COUNTER=20000
		//parameter BOOT_COUNTER=20
	)
	(
		input rst,
		input clk, 
		input clk_mem,
		//input clk_pulse_slow, 

		output reg sclk = 0, 
		output reg ce = 1, 
		inout mosi, 
		inout miso, 
		inout sio2, 
		inout sio3, 

		input rd, 
		input rend,
		input we,   
		input wend,
		input [23:0]a,
		output reg [7:0]dout, 
		output reg byte_available, 
		input [7:0]din, 
		output reg ready_for_next_byte, 

		output ready,

		/*(*mark_debug = "true"*)*/ output reg [4:0]state = INIT
	);

	localparam INIT = 0;
	localparam RSTEN = 1;
	localparam BTWN_RSTEN_RST = 2;
	localparam RST = 3;
	localparam BTWN_RST_QE = 4;
	localparam QPI_ENTER = 5;
	localparam BTWN_QPI_IDLE = 6;
	localparam IDLE = 7;
	localparam SEND = 8;
	localparam SEND_QUAD = 9;
	localparam READING_PREPARE_QUAD = 10;
	localparam READING_QUAD = 11;
	localparam WRITING_PREPARE_QUAD = 12;
	localparam WRITING_QUAD = 13;
	localparam BTWN_READ_IDLE = 14;
	localparam BTWN_WRITE_IDLE = 15;


	reg [4:0]state_return = 0;
	reg [15:0]boot_counter = 2000;
	reg [31:0]sendbits = 0;
	reg [7:0]sendcnt = 0;
	reg [2:0]cecnt = 0;
	reg [3:0]read_p_cnt = 0;
	//reg sendmode; // 1: send cmd, 0: send data

	reg [7:0]databyte = 0;
	reg [2:0]bytecnt = 0; // auto-overflow from 7 to 0

	reg reseting = 1;
	wire spi_or_qpi = state < SEND_QUAD;
	wire r_or_w = (state == READING_PREPARE_QUAD | state == READING_QUAD); // r: input, w: output

	// state != INIT ? z : out
    //wire mosi_out = (state == IDLE) ? 0 : 
		//(state == WRITING) ?
		//databyte[7] : sendbits[31];
	//wire miso_out = 1'b0;
	//wire sio2_out = 1'b0;
	//wire sio3_out = 1'b0;
	(*mark_debug = "true"*)reg mosi_out;
	(*mark_debug = "true"*)reg miso_out;
	(*mark_debug = "true"*)reg sio2_out;
	(*mark_debug = "true"*)reg sio3_out;
	always @ (*) begin
		if (state == INIT) begin
			{mosi_out, miso_out, sio2_out, sio3_out} = 4'b0;
		end else if (state != IDLE) begin
			if (spi_or_qpi) begin
				mosi_out = (state == WRITING_QUAD) ? databyte[7] : sendbits[31];
				{miso_out, sio2_out, sio3_out} = 3'bz;
			end else begin
				{mosi_out, miso_out, sio2_out, sio3_out} = (state == WRITING_QUAD) ? 
					{databyte[4], databyte[5], databyte[6], databyte[7]} :
					{sendbits[28], sendbits[29], sendbits[30], sendbits[31]};
			end
		end else begin
			{mosi_out, miso_out, sio2_out, sio3_out} = 4'bz;
		end
	end

	(*mark_debug = "true"*)wire miso_in;
	(*mark_debug = "true"*)wire mosi_in;
	(*mark_debug = "true"*)wire sio2_in;
	(*mark_debug = "true"*)wire sio3_in;
	IOBUF miso_inout
	(
		.T(r_or_w),
		.I(miso_out),
		.O(miso_in),
		.IO(miso)
	);
	IOBUF mosi_inout
	(
		.T(r_or_w),
		.I(mosi_out),
		.O(mosi_in),
		.IO(mosi)
	);
	IOBUF sio2_inout
	(
		.T(r_or_w),
		.I(sio2_out),
		.O(sio2_in),
		.IO(sio2)
	);
	IOBUF sio3_inout
	(
		.T(r_or_w),
		.I(sio3_out),
		.O(sio3_in),
		.IO(sio3)
	);

	//reg sclk_en = 0;
	//assign sclk = sclk_en ? clk : 0;

	reg rend_latch = 0;
	always @ (posedge clk_mem) begin
		if (rst) rend_latch <= 0;
		else if (state == READING_QUAD & rend) rend_latch <= 1;
		else if (state != READING_QUAD) rend_latch <= 0;
	end
	reg wend_latch = 0;
	always @ (posedge clk_mem) begin
		if (rst) wend_latch <= 0;
		else if (state == WRITING_QUAD & wend) wend_latch <= 1;
		else if (state != WRITING_QUAD) wend_latch <= 0;
	end
	reg we_latch = 0;
	always @ (posedge clk_mem) begin
		if (rst) we_latch <= 0; // TODO: check
		else if (we) we_latch <= 1;
		else if (state == BTWN_WRITE_IDLE) we_latch <= 0;
	end
	reg rd_latch = 0;
	always @ (posedge clk_mem) begin
		if (rst) rd_latch <= 0;
		else if (rd) rd_latch <= 1;
		else if (state == BTWN_READ_IDLE) rd_latch <= 0;
	end

    always @(posedge clk_mem) begin
		if(rst) begin // >150us, CE high, CLK low, SI/SO/SIO[3:0] low
			ce <= 1;
			sclk <= 0;
			//sclk_en <= 0;
			boot_counter <= BOOT_COUNTER;
			state <= INIT;
			byte_available <= 0;
			ready_for_next_byte <= 0;
			sendbits <= 0;
			//sendcnt <= 0;
			//cecnt <= 0;
			//read_p_cnt <= 0;
			databyte <= 0;
			bytecnt <= 0;
			reseting <= 1;
        end
        else case(state)
				// initialization >150us, CLK low, CE# high
                INIT: begin
                    if(boot_counter == 0) state <= RSTEN;
                    else boot_counter <= boot_counter - 1;
                end
				RSTEN: begin
					sendbits <= {8'b01100110, 24'b0};
					sendcnt <= 8;
					ce <= 0;
					state <= SEND;
					state_return <= BTWN_RSTEN_RST;
					cecnt <= 7;
				end
				BTWN_RSTEN_RST: begin
					if (cecnt != 7) ce <= 1;
					if (cecnt == 0) state <= RST;
					cecnt <= cecnt - 1;
				end
				RST: begin
					sendbits <= {8'b10011001, 24'b0};
					sendcnt <= 8;
					ce <= 0;
					state <= SEND;
					state_return <= BTWN_RST_QE;
					cecnt <= 7; // actually don't need cos 0-1=7
				end
				BTWN_RST_QE: begin
					if (cecnt != 7) ce <= 1;
					if (cecnt == 0) state <= QPI_ENTER;
					cecnt <= cecnt - 1;
				end
				QPI_ENTER: begin
					sendbits <= {8'b00110101, 24'b0};
					sendcnt <= 8;
					ce <= 0;
					cecnt <= 7;
					state <= SEND;
					state_return <= BTWN_QPI_IDLE;
				end
				BTWN_QPI_IDLE: begin
					if (cecnt != 7) ce <= 1;
					if (cecnt == 0) state <= IDLE;
					cecnt <= cecnt - 1;
				end
                IDLE: begin
					sclk <= 0;
					if (reseting) begin
						reseting <= 0;
						ce <= 1;
					end else if (we_latch) begin
						sendbits <= {8'h38, a[23:0]};
						//sendbits <= {8'b10011111, a[23:0]};
						sendcnt <= 8 + 24;
						state <= SEND_QUAD;
						state_return <= WRITING_PREPARE_QUAD;
						bytecnt <= 0;
						ce <= 0;
					end else if (rd_latch) begin
						sendbits <= {8'hEB, a[23:0]};
						sendcnt <= 8 + 24;
						state <= SEND_QUAD;
						state_return <= READING_PREPARE_QUAD;
						read_p_cnt <= 12;
						bytecnt <= 0;
						ce <= 0;
					end
					else ce <= 1;
                end
				SEND: begin
					// the first bit is automatically prepared
					// before state <= SEND:
					// sclk should be zero, ce should be 0
					// ce will be kept 0 after state_return
					sclk <= ~sclk;
					if (sclk) begin
						sendcnt <= sendcnt - 1;
						sendbits <= {sendbits[30:0], 1'b1};
						if (sendcnt == 1) begin
							state <= state_return;
						end
					end
				end
				SEND_QUAD: begin
					sclk <= ~sclk;
					if (sclk) begin
						sendcnt <= sendcnt - 4;
						sendbits <= {sendbits[27:0], 4'b1};
						if (sendcnt == 4) begin
							state <= state_return;
						end
					end
					if (state_return == WRITING_PREPARE_QUAD)
						ready_for_next_byte <= 1;
				end
				READING_PREPARE_QUAD: begin
					// 6 cycles
					sclk <= ~sclk;
					read_p_cnt <= read_p_cnt - 1;
					if (read_p_cnt == 0) state <= READING_QUAD;
				end
				READING_QUAD: begin
					if (rend_latch & sclk == 0 & bytecnt == 0) begin
						state <= BTWN_READ_IDLE;
						cecnt <= 7;
					end
					else sclk <= ~sclk;
					if (sclk) begin
						bytecnt <= bytecnt + 4;
						databyte <= {databyte[3:0], sio3_in, sio2_in, miso_in, mosi_in};
						if (bytecnt == 4) begin
							byte_available <= 1;
							dout <= {databyte[3:0], sio3_in, sio2_in, miso_in, mosi_in};
						end
						else byte_available <= 0;
					end
				end
				WRITING_PREPARE_QUAD: begin
					databyte <= din;
					ready_for_next_byte <= 0;
					state <= WRITING_QUAD;
				end
				WRITING_QUAD: begin
					sclk <= ~sclk;
					if (sclk) begin
						databyte <= bytecnt == 4 ?
							din : {databyte[3:0], 4'b1};
						bytecnt <= bytecnt + 4;
						if (bytecnt == 0) ready_for_next_byte <= 1;
						else ready_for_next_byte <= 0;
						if (wend_latch & bytecnt == 4) begin
							state <= BTWN_WRITE_IDLE;
							cecnt <= 7;
						end
					end
				end
				BTWN_READ_IDLE: begin
					if (cecnt != 7) ce <= 1;
					if (cecnt == 0) state <= IDLE;
					cecnt <= cecnt - 1;
					byte_available <= 0;
				end
				BTWN_WRITE_IDLE: begin
					if (cecnt != 7) ce <= 1;
					if (cecnt == 0) state <= IDLE;
					cecnt <= cecnt - 1;
					ready_for_next_byte <= 0;
				end
		endcase
    end

    assign ready = (state == IDLE);
endmodule
