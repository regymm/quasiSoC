`timescale 1ns / 1ps
// pComputer 8*512 fifo, simultaneous enqueue/dequeue

module fifo
    (
        input clk, rst,
        input [7:0]din,
        input enqueue, 
        input dequeue,
        output [7:0]dout,
        output full,
        output empty,
        output reg [8:0]count = 0
    );

    //reg [7:0]din0 = 0;
    //reg enqueue0 = 0;
    //reg dequeue0 = 0;
    //always @ (posedge clk) begin
        //din0 <= din;
        //enqueue0 <= enqueue;
        //dequeue0 <= dequeue;
    //end


    reg [8:0]head = 9'b0;
    reg [8:0]tailp1 = 9'b0;

    assign full = (count == 9'b111111111);
    assign empty = (count == 9'b0);
    wire enq_real = enqueue & (count != 9'b111111111);
    wire deq_real = dequeue & (count != 9'b0);

    //reg we = 0;
    wire we = enq_real;
    reg [8:0]deq_a = 0;
    reg [8:0]enq_a = 0;
    fifo_ram fifo_ram_inst (
        .clk(clk),
        .we(we),
        .a(enq_a),
        .d(din),
        .dpra(deq_a),
        //.spo(dout),
        .dpo(dout)
    );

    always @ (posedge clk) begin
        if (rst) begin
            head <= 0;
            tailp1 <= 1;
            count <= 0;
            deq_a <= 0;
            enq_a <= 0;
        end
        else begin
            if (deq_real) begin
                deq_a <= head;
                head <= head + 1;
            end
            if (enq_real) begin
                enq_a <= tailp1;
                tailp1 <= tailp1 + 1;
            end

            count <= count - {8'b0, deq_real} + {8'b0, enq_real};
        end
    end
endmodule

