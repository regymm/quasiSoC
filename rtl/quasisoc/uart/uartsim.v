/**
 * File              : uartsimu.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.24
 * Last Modified Date: 2023.02.18
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

module uart_sim
    (
        input clk,
        input rst,

        input rx,
		input rxsim_en,
		input [7:0]rxsim_data,
        output reg tx = 1,

        input [2:0]a,
        input [31:0]d,
        input we,
        output reg [31:0]spo,

        output reg irq = 0,

		output reg rxnew = 0, // not supported in sim
		output reg [7:0]rxdata = 0 // not supported in sim
    );

	wire [7:0]data = d[31:24];

    reg [7:0]data_rx = 0;
	reg rx_new = 0;

    always @ (*) begin
        if (a == 3'b000) spo = {data_rx, 24'b0};
        else if (a == 3'b001) spo = {7'b0, rx_new, 24'b0};
        else if (a == 3'b010) spo = {7'b0, 1'b1, 24'b0};
        else spo = 32'b0;
    end

    always @ (posedge clk) begin
		if (we & (a == 3'b000)) begin
			$write("%c", data);
			$fflush();
		end
		// we assume input is not very fast
		if (we & (a == 3'b001)) begin
			rx_new <= 0;
		end else if (rxsim_en) begin
			rx_new <= 1;
			data_rx <= rxsim_data;
		end
    end
endmodule
