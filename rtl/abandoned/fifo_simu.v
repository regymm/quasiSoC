`timescale 1ns / 1ps
// pComputer FIFO simulation

module fifo_simu();
    reg clk;
    reg rst;

    reg [7:0]din = 0;
    reg enqueue = 0;
    reg dequeue = 0;
    fifo fifo_inst
    (
        .clk(clk),
        .rst(rst),
        .din(din),
        .enqueue(enqueue),
        .dequeue(dequeue)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        rst = 1;
        #10
        rst = 0;
        din = 9;
        enqueue = 1;
        #10
        din = 8;
        #10
        #10
        dequeue = 1;
        #10
        enqueue = 0;
        #80
        $finish;
    end

endmodule
