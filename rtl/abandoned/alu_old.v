`timescale 1ns / 1ps
// ALU
// 2020 COD Lab1
// ustcpetergu

module alu
    #(parameter WIDTH = 32)
    (
        input [2:0]m, // selection
        input [WIDTH-1:0]a, b, // input
        output reg [WIDTH-1:0]y, // result
        output reg zf, // zero flag
        output reg cf, // carry out flag: WIDTH bit
        output reg of, // overflow flag
        output wire sf // sign flag: WIDTH-1 sign bit
    );

    assign sf = y[WIDTH-1];

    always @ (*) begin
        y = 0; zf = 0; cf = 0; of = 0;
        case(m)
            3'b000: begin // add
                {cf, y} = a + b;
                of = (!a[WIDTH-1] & !b[WIDTH-1] & y[WIDTH-1]) |
                 (a[WIDTH-1] & b[WIDTH-1] & !y[WIDTH-1]);
                zf = (y == 0);
            end
            3'b001: begin // sub
                {cf, y} = a - b;
                of = (!a[WIDTH-1] & b[WIDTH-1] & y[WIDTH-1]) |
                 (a[WIDTH-1] & !b[WIDTH-1] & !y[WIDTH-1]);
                zf = (y == 0);
            end
            3'b010: begin // and
                y = a & b;
                zf = (y == 0);
            end
            3'b011: begin // or
                y = a | b;
                zf = (y == 0);
            end
            3'b100: begin // xor
                y = a ^ b;
                zf = (y == 0);
            end
            3'b101: begin // sll
                y = b << a;
            end
            3'b110: begin // srl
                y = b >> a;
            end
            default: begin // error
            end
        endcase
    end
endmodule
