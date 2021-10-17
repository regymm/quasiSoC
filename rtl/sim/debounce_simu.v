`timescale 1ns / 1ps

module debounce_simu();
    reg clk;
    reg btn;

    wire o_state;
    debounce debounce_inst
    (
        .clk(clk),
        .i_btn(btn),
        .o_state(o_state)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin 
        btn = 0;
        #10
        btn = 1;
        #10
        btn = 0;
        #10
        btn = 1;
        #200
        btn = 0;
        #200
        $finish;
    end
endmodule
