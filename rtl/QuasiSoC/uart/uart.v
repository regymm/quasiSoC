/**
 * File              : uart.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.24
 * Last Modified Date: 2021.01.24
 */
`timescale 1ns / 1ps
// pComputer UART I/O
// input XXMHz, 16x oversampling
// warning: not very reliable: read/write together case, ...
// so need special software care(better to write one value and wait until idle)
// 921600 baud seems the most this can go at 62.5M clk
//
// write 0x00: transmit data
// read 0x00: received data
// write 0x01: begin receiving
// read 0x01: new data received?
// read 0x02: transmit done?
// *need to x4 these addresses in assembly!
`include "quasi.vh"

module uart
	#(
		parameter CLOCK_FREQ = 62500000,
		parameter BAUD_RATE = 115200
	)
    (
        input clk,
        input rst,

        input rx,
        output reg tx = 1,

        input [2:0]a,
        input [31:0]d,
        input we,
        output reg [31:0]spo,

        output irq,

		output reg rxnew,
		output [7:0]rxdata
    );

	localparam SAMPLE_COUNT = 17;
	localparam SAMPLE_SAMPLE = 6;
	localparam SAMPLE_REMEDY = 4;

	wire [7:0]data = d[31:24];

	(*mark_debug = "true"*) reg rx_r;
	always @ (posedge clk) begin
		rx_r <= rx;
	end

    (*mark_debug = "true"*) wire rxclk_en;
    wire txclk_en;
    baud_rate_gen
	#(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.SAMPLE_MULTIPLIER(32)
	) baud_rate_gen_inst (
        .clk(clk),
        .rst(rst),
        .rxclk_en(rxclk_en),
        .txclk_en(txclk_en)
    );

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    reg [1:0]state_tx = IDLE;
    reg [7:0]data_tx = 8'h00;
    reg [2:0]bitpos_tx = 3'b0;

    localparam RX_STATE_START = 2'b01;
    localparam RX_STATE_START_REMEDY = 2'b00;
    localparam RX_STATE_DATA = 2'b10;
    localparam RX_STATE_STOP = 2'b11;
    (*mark_debug = "true"*) reg [1:0]state_rx = RX_STATE_START;
    (*mark_debug = "true"*) reg [4:0]sample = 0;
    reg [3:0]bitpos_rx = 0;
    (*mark_debug = "true"*) reg [7:0]scratch = 8'b0;

    reg read_enabled = 0;
    (*mark_debug = "true"*)reg [7:0]data_rx = 0;
	reg rx_new = 0;

    always @ (*) begin
        if (a == 3'b000) spo = {data_rx, 24'b0};
        else if (a == 3'b001) spo = {7'b0, rx_new, 24'b0};
        else if (a == 3'b010) spo = {7'b0, (state_tx == IDLE), 24'b0};
        else spo = 32'b0;
    end
	//always @ (posedge clk) begin
		//if (rst) irq <= 0;
		//else if (state_rx == RX_STATE_STOP & sample == 31 & irq == 0) irq <= 1;
		//// TODO
		//else irq <= 0;
	//end
    always @ (posedge clk) begin
        if (rst) begin
            tx <= 1'b1;
            data_tx <= 0;
            state_tx <= IDLE;
            bitpos_tx <= 3'b0;

            data_rx <= 0;
			//rx_new <= 0;
            read_enabled <= 0;
            state_rx <= RX_STATE_START;
            sample <= 0;
        end
        else begin
            case (state_tx)
                IDLE: if (we & (a == 3'b000)) begin
                    data_tx <= data;
                    state_tx <= START;
                    bitpos_tx <= 3'b0;
                end
                START: if (txclk_en) begin
                    tx <= 1'b0;
                    state_tx <= DATA;
                end
                DATA: if (txclk_en) begin
                    if (bitpos_tx == 3'h7) state_tx <= STOP;
                    else bitpos_tx <= bitpos_tx + 1;
                    tx <= data_tx[bitpos_tx];
                end
                STOP: if (txclk_en) begin
                    tx <= 1'b1;
                    state_tx <= IDLE;
                end
            endcase

			//if (we & a == 3'b001) begin
				//rx_new <= 0;
			//end

            if (rxclk_en) begin
                case (state_rx)
                    RX_STATE_START: begin
                        if (!rx_r || sample != 0) sample <= sample + 1;
                        if (sample == SAMPLE_COUNT) begin
                            state_rx <= RX_STATE_DATA;
                            bitpos_rx <= 0;
                            sample <= 0;
                            scratch <= 0;
                        end
                    end
					RX_STATE_START_REMEDY: begin // fix accumulated baud rate difference
						sample <= sample + 1;
                        if (sample == SAMPLE_COUNT) begin
                            state_rx <= RX_STATE_DATA;
                            bitpos_rx <= 0;
                            sample <= 0;
                            scratch <= 0;
                        end
					end
                    RX_STATE_DATA: begin
						if (sample == SAMPLE_COUNT) sample <= 0;
						else sample <= sample + 1;
                        //sample <= sample + 1;
                        if (sample == SAMPLE_SAMPLE) begin
                            scratch[bitpos_rx[2:0]] <= rx_r;
                            bitpos_rx <= bitpos_rx + 1;
                        end
                        if (bitpos_rx == 8 && sample == SAMPLE_COUNT) state_rx <= RX_STATE_STOP;
                    end
                    RX_STATE_STOP: begin
						if (sample == SAMPLE_COUNT || (sample >= SAMPLE_REMEDY && !rx_r)) begin
                            state_rx <= (rx_r == 1) ? RX_STATE_START : RX_STATE_START_REMEDY;
                            data_rx <= scratch;
							//rx_new <= 1;
                            sample <= 0;
                        end else begin
                            sample <= sample + 1;
                        end
                    end
                    //default: state_rx <= RX_STATE_START;
                endcase
            end
        end
    end

	wire wire_rx_state_stop = rxclk_en && (state_rx == RX_STATE_STOP) && (sample == SAMPLE_COUNT || (sample >= SAMPLE_REMEDY && !rx_r));
	wire wire_rx_reset = we && (a == 3'b001);
	always @ (posedge clk) begin
		if (rst) begin
			rx_new <= 0;
		end else begin
			if (wire_rx_state_stop) rx_new <= 1;
			else if (wire_rx_reset) rx_new <= 0;
		end
	end

	//reg rxnew;
	//reg rxnew_1;
	always @ (posedge clk) begin
		rxnew <= wire_rx_state_stop;
		//rxnew_1 <= wire_rx_state_stop;
		//rxnew <= rxnew_1;
	end
	assign irq = rxnew;
	//assign rxnew = wire_rx_state_stop;
	assign rxdata = data_rx;
	//reg override_old;
	//always @ (posedge clk) begin
		//override_old <= override;
		//if (override && !override_old)
			//rxdata <= 0;
		//else rxdata <= data_rx;
	//end
endmodule
