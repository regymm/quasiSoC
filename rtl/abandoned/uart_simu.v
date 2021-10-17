`timescale 1ns / 1ps
// pComputer UART simulation


module uart_simu();
    reg clk;
    reg rst;
    reg txclk_en = 1;

    reg [1:0]a = 0;
    reg [31:0]d = 0;
    reg we = 0;
    reg rx = 0;
    wire [31:0]spo;
    wire tx;
    uart uart_inst
    (
        .clk_50M(clk),
        .rxclk_en(0),
        .txclk_en(txclk_en),
        .rst(rst),

        .a(a),
        .d(d),
        .we(we),
        .spo(spo),

        .rx(rx),
        .tx(tx)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    //initial begin
        //txclk_en = 0;
        //forever #25 txclk_en = ~txclk_en;
    //end
    initial begin
        rst = 1;
        #10
        rst = 0;
        a = 2'b00;
        we = 0;

        #10
        d = 48;
        we = 1;
        #10
        d = 65;
        #20
        d = 97;
        #10
        we = 0;
        a = 2'b10;
        #1000
        $finish;
    end
endmodule
