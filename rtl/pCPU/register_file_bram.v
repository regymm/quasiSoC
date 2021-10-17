`timescale 1ns / 1ps
// pCPU regfile based on bram
// save resources, but no r/w forwarding

module register_file_bram
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

	wire [31:0]rd0_ram;
	wire [31:0]rd1_ram;
	reg ra0iszero;
	reg ra1iszero;

	always @ (posedge clk) begin
		ra0iszero <= ra0 == 0;
		ra1iszero <= ra1 == 0;
	end

	assign rd0 = ra0iszero ? 0 : rd0_ram;
	assign rd1 = ra1iszero ? 0 : rd1_ram;

	simple_ram #(.WIDTH(32), .DEPTH(5)) reg1 (
		.clk(clk),
		.a(we ? wa : ra0),
		.d(wd),
		.we(we),
		.spo(rd0_ram)
	);
	simple_ram #(.WIDTH(32), .DEPTH(5)) reg2 (
		.clk(clk),
		.a(we ? wa : ra1),
		.d(wd),
		.we(we),
		.spo(rd1_ram)
	);
endmodule

