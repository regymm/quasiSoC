/**
 * File              : uartnew.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.24
 * Last Modified Date: 2022.05.18
 */
`timescale 1ns / 1ps
// pComputer UART
// a better version (arbitary input clk freq, fifo, ...)
// TODO: fifo? fifo w/ uartboot?
//
// write 0x00: transmit data -- (tx fifo enqueue)
// read 0x00: received data -- (first data in rx fifo)
// write 0x01: begin receiving -- (rx fifo dequeue, ignore empty)
// read 0x01: new data received? -- (rx fifo empty?)
// read 0x02: transmit done? -- (tx fifo full?)
// 0x03: 
// rxnew/rxdata: real-time, extra fifo required in serialboot
// *need to x4 these addresses in assembly!
`include "quasi.vh"

module uart_new
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

	wire [7:0]data = d[31:24];

	(*mark_debug = "true"*) reg rx_r;
	reg rx_r0;
	reg tx_r = 1;
	always @ (posedge clk) begin
		rx_r0 <= rx;
		rx_r <= rx_r0;
		tx <= tx_r;
	end

	// required clk_en derived from clk and baud
	reg [31:0]tx_en_cnt = 0;
    wire txclk_en = tx_en_cnt == 0;
	localparam TX_COUNT = CLOCK_FREQ / BAUD_RATE;
	always @ (posedge clk) begin
		if (rst) tx_en_cnt <= 0;
		else tx_en_cnt <= tx_en_cnt == TX_COUNT ?
			0 : tx_en_cnt + 1;
	end

	localparam SAMPLE_COUNT = CLOCK_FREQ / BAUD_RATE;
	localparam SAMPLE_SAMPLE = SAMPLE_COUNT / 2;
	localparam SAMPLE_REMEDY = SAMPLE_COUNT / 4;

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
    (*mark_debug = "true"*) reg [15:0]sample = 0;
    reg [3:0]bitpos_rx = 0;
    (*mark_debug = "true"*) reg [7:0]scratch = 8'b0;

    (*mark_debug = "true"*)reg [7:0]data_rx = 0;
	reg rx_new = 0; // no fifo case -- equivalent fifo empty/full

    always @ (*) begin
        if (a == 3'b000) spo = {data_rx, 24'b0};
        else if (a == 3'b001) spo = {7'b0, rx_new, 24'b0};
        else if (a == 3'b010) spo = {7'b0, (state_tx == IDLE), 24'b0};
        else spo = 32'b0;
    end
    always @ (posedge clk) begin
        if (rst) begin
            tx_r <= 1'b1;
            state_tx <= IDLE;
            data_tx <= 0;
            bitpos_tx <= 3'b0;

            state_rx <= RX_STATE_START;
            data_rx <= 0;
			bitpos_rx <= 0;
            sample <= 0;
			scratch <= 0;
        end
        else begin
            case (state_tx)
                IDLE: if (we & (a == 3'b000)) begin
                    data_tx <= data;
                    state_tx <= START;
                    bitpos_tx <= 3'b0;
                end
                START: if (txclk_en) begin
                    tx_r <= 1'b0;
                    state_tx <= DATA;
                end
                DATA: if (txclk_en) begin
                    if (bitpos_tx == 3'h7) state_tx <= STOP;
                    else bitpos_tx <= bitpos_tx + 1;
                    tx_r <= data_tx[bitpos_tx];
                end
                STOP: if (txclk_en) begin
                    tx_r <= 1'b1;
                    state_tx <= IDLE;
                end
            endcase

			case (state_rx)
				RX_STATE_START: begin
					if (!rx_r || sample != 0) sample <= sample + 1;
					if (sample == SAMPLE_COUNT) begin
						sample <= 0;
						state_rx <= RX_STATE_DATA;
					end
				end
				RX_STATE_DATA: begin
					sample <= sample == SAMPLE_COUNT ? 0 : sample + 1;
					if (sample == SAMPLE_SAMPLE) begin
						scratch[bitpos_rx[2:0]] <= rx_r;
						bitpos_rx <= bitpos_rx + 1;
					end
					if (bitpos_rx == 8 && sample == SAMPLE_COUNT) state_rx <= RX_STATE_STOP;
				end
				RX_STATE_STOP: begin
					if (sample == SAMPLE_COUNT || (sample >= SAMPLE_REMEDY && !rx_r)) begin
						state_rx <= RX_STATE_START;
						data_rx <= scratch;
						sample <= rx_r == 1 ? 0 : 1; // every cycle matters... or not?
						bitpos_rx <= 0;
						scratch <= 0;
					end else begin
						sample <= sample + 1;
					end
				end
				default: state_rx <= RX_STATE_START;
			endcase
        end
    end

	// single-cycle pulse receive done indication
	wire wire_rx_state_stop = (state_rx == RX_STATE_STOP) && (sample == SAMPLE_COUNT || (sample >= SAMPLE_REMEDY && !rx_r));
	// "equivalent dequeue"
	wire wire_rx_reset = we && (a == 3'b001);
	always @ (posedge clk) begin
		if (rst) begin
			rx_new <= 0;
		end else begin
			if (wire_rx_state_stop) rx_new <= 1;
			else if (wire_rx_reset) rx_new <= 0;
		end
	end

	always @ (posedge clk) begin
		rxnew <= wire_rx_state_stop;
	end
	assign rxdata = data_rx;
	assign irq = rxnew;
endmodule
