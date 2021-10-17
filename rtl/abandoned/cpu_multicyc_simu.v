`timescale 1ns / 1ps
// CPU, mmapper, bootrom simulation

module cpu_multicyc_simu();
    reg clk = 0;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
endmodule
