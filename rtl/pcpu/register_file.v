`timescale 1ns / 1ps
// pCPU regfile with debug port

module register_file
    #(parameter WIDTH = 32)
    (
        input clk,
        input [4:0]ra0,
        input [4:0]ra1,
        input [4:0]wa,
        input we,
        input [WIDTH-1:0]wd,
        output [WIDTH-1:0]rd0,
        output [WIDTH-1:0]rd1
    );
    reg [WIDTH-1:0]regfile[31:0];
    initial $readmemh("/home/petergu/MyHome/quasiSoC/pcpu/regfile.dat", regfile);
	assign rd0 = ra0 == 5'b0 ? 0 : regfile[ra0];
	assign rd1 = ra1 == 5'b0 ? 0 : regfile[ra1];
    always @ (posedge clk) begin
		if (we) regfile[wa] <= wd;
    end
endmodule

