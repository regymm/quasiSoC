`timescale 1ns / 1ps
// pComputer top simu
`define SIMULATION

module top_simu();
    reg clk = 0;
    reg [1:0]sw = 0;
    reg [1:0]btn = 0;
    wire [3:0]led;
    wire sd_dat0 = 0;
    //wire sd_dat0 = 1;
	wire psram_ce;
	wire psram_mosi;
	wire psram_miso;
	wire psram_sio2;
	wire psram_sio3;
	wire psram_sclk;
	reg ch375_tx;

	reg eth_intn = 1;
	wire eth_rstn;
	wire eth_sclk;
	wire eth_scsn;
	wire eth_mosi;
	reg eth_miso = 1;

    pcpu_main pcpu_main_inst
    (
        .sysclk(clk),
        .btn(btn),
        .led(led),
		.sw(sw),
        .sd_dat0(sd_dat0),
		.psram_ce(psram_ce),
		.psram_mosi(psram_mosi),
		.psram_miso(psram_miso),
		.psram_sio2(psram_sio2),
		.psram_sio3(psram_sio3),
		.psram_sclk(psram_sclk),
		.eth_intn(eth_intn),
		.eth_rstn(eth_rstn),
		.eth_sclk(eth_sclk),
		.eth_scsn(eth_scsn),
		.eth_mosi(eth_mosi),
		.eth_miso(eth_miso)
		//.ch375_tx(ch375_tx)
	);
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
		ch375_tx = 1;
        //#400
        sw = 2'b01;
		btn = 2'b11;
        //btn = 4'b0000;
        //#2000
        //sw = 2'b10;
        #4000
        sw = 2'b00;
		btn = 2'b00;

        //#10
        //btn = 4'b0000;

        //#1000
        //btn = 4'b0010;

        #22000
		#200000;
		$finish;
        #50000

		ch375_tx = 0;
		#52088
		ch375_tx = 1;
		#52088
		ch375_tx = 0;
		#52088
		ch375_tx = 1;
		#52088
		ch375_tx = 0;
		#52088
		ch375_tx = 1;
		#52088
		ch375_tx = 0;
		#52088
		ch375_tx = 1;
		#52088
		ch375_tx = 1;
		#52088
		ch375_tx = 1;

        #100000
		//sw = 2'b01;
		#4000
		sw = 2'b00;
		#200000;
        $finish;
    end
    
endmodule
