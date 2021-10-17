/**
 * File              : psram_controller_simple.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.10.21
 * Last Modified Date: 2020.12.01
 */
// pComputer SPI PSRAM(ESP-PSRAM64H) controller
// simple SPI mode, slow read, maximum 33 MHz clk_pulse_slow
// 64Mbit, A[22:0]

`timescale 1ns / 1ps
//`define SIMULATION

module psram_controller(
	input rst,
    input clk, 
    input clk_pulse_slow, 

    (*mark_debug = "true"*) output reg ce = 1, 
    (*mark_debug = "true"*) inout mosi, 
    (*mark_debug = "true"*) inout miso, 
    (*mark_debug = "true"*) inout sio2, 
    (*mark_debug = "true"*) inout sio3, 
    (*mark_debug = "true"*) output reg sclk = 0, 

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

    (*mark_debug = "true"*) output reg [4:0]state
);

	localparam INIT = 0;
	localparam RSTEN = 1;
	localparam BTWN_RST = 2;
	localparam RST = 3;
	localparam IDLE = 4;
	localparam SEND = 5;
	localparam READING = 6;
	localparam WRITING_PREPARE = 7;
	localparam WRITING = 8;

	reg [4:0]state_return;
	reg [15:0]boot_counter = 2000;
	reg [31:0]sendbits = 0;
	reg [7:0]sendcnt;
	//reg sendmode; // 1: send cmd, 0: send data

	reg [7:0]databyte = 0;
	reg [2:0]bytecnt; // auto-overflow from 7 to 0

    wire mosi_out = (state == IDLE) ? 0 : 
		(state == WRITING) ?
		databyte[7] : sendbits[31];
    assign ready = (state == IDLE);

	reg reseting = 1;

	assign miso = (state == INIT) ? 1'b0 : 1'bz;
	`ifdef SIMULATION
		wire miso_out = 1;
	`else
		wire miso_out = miso;
	`endif
	assign mosi = (state == INIT) ? 1'b0 : mosi_out;
	assign sio2 = (state == INIT) ? 1'b0 : 1'bz;
	assign sio3 = (state == INIT) ? 1'b0 : 1'bz;

	reg rend_latch = 0;
	always @ (posedge clk) begin
		if (rst) rend_latch <= 0;
		else if (state == READING & rend) rend_latch <= 1;
		else if (state != READING) rend_latch <= 0;
	end
	reg wend_latch = 0;
	always @ (posedge clk) begin
		if (rst) wend_latch <= 0;
		else if (state == WRITING & wend) wend_latch <= 1;
		else if (state != WRITING) wend_latch <= 0;
	end
	reg we_latch = 0;
	always @ (posedge clk) begin
		if (we) we_latch <= 1;
		else if (state == IDLE & clk_pulse_slow & !reseting) we_latch <= 0;
	end
	reg rd_latch = 0;
	always @ (posedge clk) begin
		if (rd) rd_latch <= 1;
		else if (state == IDLE & clk_pulse_slow & !reseting) rd_latch <= 0;
	end

    always @(posedge clk) begin
		if(rst) begin // >150us, CE high, CLK low, SI/SO/SIO[3:0] low
			ce <= 1;
			sclk <= 0;
			`ifdef SIMULATION
				boot_counter <= 10;
			`else
				boot_counter <= 2000;
			`endif
			state <= INIT;
			byte_available <= 0;
			ready_for_next_byte <= 0;
			reseting <= 1;
			databyte <= 0;
			sendbits <= 0;
        end
        else if (clk_pulse_slow) case(state)
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
					state_return <= BTWN_RST;
				end
				BTWN_RST: begin
					ce <= 1;
					if (ce == 1) state <= RST;
				end
				RST: begin
					sendbits <= {8'b10011001, 24'b0};
					sendcnt <= 8;
					ce <= 0;
					state <= SEND;
					state_return <= IDLE;
				end
                IDLE: begin
					sclk <= 0;
					if (reseting) begin
						reseting <= 0;
						ce <= 1;
					end else if (we_latch) begin
						sendbits <= {8'b0000010, a[23:0]};
						//sendbits <= {8'b10011111, a[23:0]};
						sendcnt <= 8 + 24;
						state <= SEND;
						state_return <= WRITING_PREPARE;
						bytecnt <= 0;
						ce <= 0;
					end
					else if (rd_latch) begin
						sendbits <= {8'b0000011, a[23:0]};
						sendcnt <= 8 + 24;
						state <= SEND;
						state_return <= READING;
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
							if (state_return == WRITING_PREPARE)
								ready_for_next_byte <= 1;
						end
					end
				end
				READING: begin
					if (rend_latch & sclk == 0 & bytecnt == 0) begin
						state <= IDLE;
						ce <= 1;
					end
					else sclk <= ~sclk;
					if (sclk) begin
						bytecnt <= bytecnt + 1;
						databyte <= {databyte[6:0], miso_out};
						if (bytecnt == 7) begin
							byte_available <= 1;
							dout <= {databyte[6:0], miso_out};
						end
						else byte_available <= 0;
					end
				end
				WRITING_PREPARE: begin
					databyte <= din;
					ready_for_next_byte <= 0;
					state <= WRITING;
				end
				WRITING: begin
					sclk <= ~sclk;
					if (sclk) begin
						databyte <= bytecnt == 7 ?
							din : {databyte[6:0], 1'b1};
						bytecnt <= bytecnt + 1;
						if (bytecnt == 6) ready_for_next_byte <= 1;
						else ready_for_next_byte <= 0;
						if (wend_latch & bytecnt == 7) begin
							state <= IDLE;
							ce <= 1;
						end
					end
				end
		endcase
    end
endmodule
