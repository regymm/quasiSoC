/**
 * File              : alu.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2021.10.17
 * Last Modified Date: 2021.10.17
 */
`timescale 1ns / 1ps
// ALU with more operations
// 4 bit ALUm:
// 0000: add
// 1000: sub
// 0001: sll
// 0101: srl
// 1101: sra
// 0100: xor
// 0110: or
// 0111: and
// 1111: pass a
// 0010: slt
// 0011: sltu

module alu
    (
        input [3:0]m, // selection
        input [31:0]a, b, // input
        output reg [31:0]y // result
    );

	// zf: zero
	// cf: carry out, WIDTH bit
	// of: overflow
	// sf: sign, WIDTH-1

	wire signed [31:0]a_signed = a;
	wire [31:0]addition = a + b;
	wire [32:0]subtraction = a - b;
	wire sub_of = (!a[31] & b[31] & subtraction[31]) |
				 (a[31] & !b[31] & !subtraction[31]);
	wire sub_zf = (subtraction[31:0] == 32'h0);
    wire sub_sf = subtraction[31];
	wire sub_cf = subtraction[32];
	//reg cf;
    always @ (*) begin
        //y = 0; cf = 0; of = 0;
        case(m)
            4'b0000: // add
				y = addition[31:0];
                //{cf, y} = addition;
                //of = (!a[WIDTH-1] & !b[WIDTH-1] & y[WIDTH-1]) |
                 //(a[WIDTH-1] & b[WIDTH-1] & !y[WIDTH-1]);
            4'b1000: // sub
				y = subtraction[31:0];
                //{cf, y} = subtraction;
                //of = (!a[WIDTH-1] & b[WIDTH-1] & y[WIDTH-1]) |
                 //(a[WIDTH-1] & !b[WIDTH-1] & !y[WIDTH-1]);
            4'b0001: // sll
                y = a << b[4:0];
            4'b0101: // srl
                y = a >> b[4:0];
			4'b1101: // sra
				y = a_signed >>> b[4:0];
            4'b0100: // xor
                y = a ^ b;
            4'b0110: // or
                y = a | b;
			4'b1111: // pass a, for csrrw(i)
				y = a; 
            4'b0111: // and
                y = a & b;
			4'b0010: // slt
				y = {31'b0, (sub_of ^ sub_sf) & !sub_zf};
			4'b0011: // sltu
				y = {31'b0, sub_cf};
            default: begin // error
				y = 32'hDEADBEEF;
            end
        endcase
    end
endmodule
