/**
 * File              : ch375b.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.21
 * Last Modified Date: 2021.01.21
 */

`timescale 1ns / 1ps
// CH375b Serial Driver, another UART
//
// write 0x00: transmit command data
// read 0x00: received data
// write 0x01: reset receiving status
// read 0x01: new data received?
// write 0x02: transmit data data
// read 0x02: transmit done?
// *need to x4 these addresses in assembly!
`include "quasi.vh"

module ch375b
	#(
		parameter CLOCK_FREQ = 0,
		parameter BAUD_RATE = 0
	)
    (
        input clk,
        input rst,

        input [2:0]a,
        input [31:0]d,
        input we,
        (*mark_debug = "true"*)output reg [31:0]spo,

        output reg irq = 0,

        output ch375_rx, // tx
        input ch375_tx, // rx
		input ch375_nint
    );

	wire rx;
	reg tx = 1;
	assign ch375_rx = tx;
	assign rx = ch375_tx;

	wire [7:0]data = d[31:24];

    wire rxclk_en;
    wire txclk_en;
    baud_rate_gen #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.SAMPLE_MULTIPLIER(16)
	) baud_rate_gen_inst
    (
        .clk(clk),
        .rst(rst),
        .rxclk_en(rxclk_en),
        .txclk_en(txclk_en)
    );

    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam DATA = 3'b010;
	localparam DATA_SEL = 3'b011;
    localparam STOP = 3'b100;
    reg [2:0]state_tx = IDLE;
    reg [7:0]data_tx = 8'h00;
    reg [2:0]bitpos_tx = 3'b0;

    localparam RX_STATE_START = 2'b01;
    localparam RX_STATE_DATA = 2'b10;
    localparam RX_STATE_SKIP = 2'b00;
    localparam RX_STATE_STOP = 2'b11;
    reg [1:0]state_rx = RX_STATE_START;
    reg [3:0]sample = 0;
    reg [3:0]bitpos_rx = 0;
    reg [7:0]scratch = 8'b0;
	reg cmd_or_data = 1'b1;

    reg read_enabled = 0;
    (*mark_debug = "true"*)reg [7:0]data_rx = 0;
	(*mark_debug = "true"*)reg rx_new = 0;

    always @ (*) begin
        if (a == 3'b000) spo = {data_rx, 24'b0};
        else if (a == 3'b001) spo = {7'b0, rx_new, 24'b0};
        else if (a == 3'b010) spo = {7'b0, (state_tx == IDLE), 24'b0};
        else if (a == 3'b011) spo = {7'b0, ch375_nint, 24'b0};
        else spo = 32'b0;
    end
	always @ (posedge clk) begin
		if (rst) irq <= 0;
		else if (state_rx == RX_STATE_STOP & irq == 0) irq <= 1;
		else irq <= 0;
	end
    always @ (posedge clk) begin
        if (rst) begin
            tx <= 1'b1;
            data_tx <= 0;
            state_tx <= IDLE;
            bitpos_tx <= 3'b0;
			cmd_or_data <= 1'b1;

            data_rx <= 0;
			rx_new <= 0;
            read_enabled <= 0;
            state_rx <= RX_STATE_START;
            sample <= 0;
        end
        else begin
            case (state_tx)
                IDLE: if (we & (a == 3'b000 | a == 3'b010)) begin
                    data_tx <= data;
                    state_tx <= START;
                    bitpos_tx <= 3'b0;
					cmd_or_data <= ~a[1];
				end
                START: if (txclk_en) begin
                    tx <= 1'b0;
                    state_tx <= DATA;
                end
                DATA: if (txclk_en) begin
                    if (bitpos_tx == 3'h7) state_tx <= DATA_SEL;
                    else bitpos_tx <= bitpos_tx + 1;
                    tx <= data_tx[bitpos_tx];
                end
				DATA_SEL: if (txclk_en) begin
					// this bit means command or data
					tx <= cmd_or_data; 
					state_tx <= STOP;
				end
                STOP: if (txclk_en) begin
                    tx <= 1'b1;
                    state_tx <= IDLE;
                end
            endcase

			if (we & a == 3'b001) begin
				rx_new <= 0;
			end

            if (rxclk_en) begin
                case (state_rx)
                    RX_STATE_START: begin
                        if (!rx || sample != 0) sample <= sample + 1;
                        if (sample == 15) begin
                            state_rx <= RX_STATE_DATA;
                            bitpos_rx <= 0;
                            sample <= 0;
                            scratch <= 0;
                        end
                    end
                    RX_STATE_DATA: begin
                        sample <= sample + 1;
                        if (sample == 8) begin
                            scratch[bitpos_rx[2:0]] <= rx;
                            bitpos_rx <= bitpos_rx + 1;
                        end
						// this chip has 9 data bits
                        if (bitpos_rx == 8 && sample == 15) state_rx <= RX_STATE_SKIP;
                    end
					RX_STATE_SKIP: begin
						sample <= sample + 1;
						if (sample == 15) state_rx <= RX_STATE_STOP;
					end
                    RX_STATE_STOP: begin
                        if (sample == 15 || (sample >= 8 && !rx)) begin
                            state_rx <= RX_STATE_START;
                            data_rx <= scratch;
							rx_new <= 1;
                            sample <= 0;
                        end else begin
                            sample <= sample + 1;
                        end
                    end
                    default: state_rx <= RX_STATE_START;
                endcase
            end
        end
    end
endmodule
