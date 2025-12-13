/**
 * File              : quasi_loong_main_ivsim.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2025.10.07
 * Last Modified Date: 2025.10.07
 */
// iverilog "interactive" simulation for quasi_loong_main
`timescale 1ns / 1ps
`define SIMULATION

module top_simu ();
    reg clk = 0;
    reg [1:0]sw = 0;
    reg [1:0]btn = 0;
    wire [3:0]led;

    wire tx;
    reg rx = 1;
    
    wire tx_2;
    reg rx_2 = 1;
    
    // SD card signals
    reg sd_ncd = 1;
    reg sd_dat0 = 1;
    wire sd_dat1;
    wire sd_dat2;
    wire sd_dat3;
    wire sd_cmd;
    wire sd_sck;
    

    quasi_main_sim #(
        .SIMULATION(1),
        .INTERACTIVE_SIM(0)
    ) quasisoc_inst
    (
        .sysclk(clk),
        .btn(btn),
        .led(led),
        .sw(sw),

        .uart_rx(rx),
        .uart_tx(tx)
        
    );
    
    // Clock generation - 50MHz (20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, quasisoc_inst);
        
        // Initial state
        sw = 2'b01;
        btn = 2'b11;
        
        // Release reset after some time
        #10000
        sw = 2'b00;
        btn = 2'b00;

        // Run simulation for 200ms
        #200000000.0;
        $finish;
    end
endmodule

