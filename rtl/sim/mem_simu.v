`timescale 1ns / 1ps
// memory module simu
`define SIMULATION

module mem_simu();
    reg clk = 0;
	reg clk_mem = 0;
	wire psram_ce;
	wire psram_mosi;
	wire psram_miso;
	wire psram_sio2;
	wire psram_sio3;
	wire psram_sclk;

	reg rst;
	reg burst_en;
	reg [7:0]burst_length;
	reg [31:0]a;
	reg [31:0]d;
	reg we = 0;
	reg rd = 0;
	wire [31:0]spo;
	wire ready;

	memory_controller_burst memory_controller_burst_inst
	(
		.rst(rst),
		.clk(clk),
		.clk_mem(clk_mem),

		.burst_en(burst_en),
		.burst_length(burst_length),

		.a(a),
		.d(d),
		.we(we),
		.rd(rd),
		.spo(spo),
		.ready(ready),

		.psram_ce(psram_ce),
		.psram_mosi(psram_mosi),
		.psram_miso(psram_miso),
		.psram_sio2(psram_sio2),
		.psram_sio3(psram_sio3),
		.psram_sclk(psram_sclk)
	);
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        clk_mem = 0;
        forever #2.5 clk_mem = ~clk_mem;
    end

    initial begin
		#5
		burst_en = 0;
		burst_length = 0;
		a = 0;
		d = 0;
		we = 0;
		rd = 0;
		rst = 1;
		#20
		rst = 0;
		#2000
		burst_en = 1;
		burst_length = 5;
		a = 32'h2000abcd;
		d = 32'hdeadbeef;
		we = 0;
		rd = 1;
		#10
		burst_en = 0;
		burst_length = 0;
		a = 0;
		d = 0;
		we = 0;
		rd = 0;

        #4000
		burst_en = 1;
		burst_length = 7;
		a = 32'h2000abcd;
		d = 32'hdeadbeef;
		we = 1;
		rd = 0;
		#10
		burst_en = 0;
		burst_length = 0;
		a = 0;
		d = 0;
		we = 0;
		rd = 0;
		#4000
		burst_en = 0;
		burst_length = 0;
		a = 32'h2000abcd;
		d = 32'hdeadbeef;
		we = 1;
		rd = 0;
		#10
		we = 0;
		#4000
		$finish;
    end
    
endmodule
