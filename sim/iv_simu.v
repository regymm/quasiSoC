/**
 * File              : iv_simu.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2023.02.18
 * Last Modified Date: 2023.02.18
 */
// iverilog "interactive" simulation
`timescale 1ns / 1ns
`define SIMULATION

module top_simu ();
    reg clk = 0;
    reg [1:0]sw = 0;
    reg [1:0]btn = 0;
    wire [3:0]led;

	wire tx;
	reg rx = 1;

    quasi_main #(
	) quasisoc_inst
    (
        .sysclk(clk),
        .btn(btn),
        .led(led),
		.sw(sw),

		.uart_rx(rx),
		.uart_tx(tx)
	);
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
		$dumpfile("wave.vcd");
		$dumpvars(0, quasisoc_inst);
        sw = 2'b01;
		btn = 2'b11;
        #4000
        sw = 2'b00;
		btn = 2'b00;

		#2000000.0;
		$finish;
    end
endmodule
