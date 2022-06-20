`timescale 1ps / 100fs
// pComputer top simu
`define SIMULATION

module top_simu ();
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

	wire tx;
	reg rx = 1;

	parameter SIMULATION = "TRUE";


	localparam DQ_WIDTH = 16;
	localparam DQS_WIDTH = 2;
	localparam ROW_WIDTH = 13;
	localparam BANK_WIDTH = 3;
	localparam CKE_WIDTH = 1;
	localparam CK_WIDTH = 1;
	localparam CS_WIDTH = 1;
	localparam DM_WIDTH = 2;
	localparam ODT_WIDTH = 1;
	localparam nCS_PER_RANK = 1;
	wire [DQ_WIDTH-1:0]                ddr2_dq_fpga;
	wire [DQS_WIDTH-1:0]               ddr2_dqs_p_fpga;
	wire [DQS_WIDTH-1:0]               ddr2_dqs_n_fpga;
	wire [ROW_WIDTH-1:0]               ddr2_addr_fpga;
	wire [BANK_WIDTH-1:0]              ddr2_ba_fpga;
	wire                               ddr2_ras_n_fpga;
	wire                               ddr2_cas_n_fpga;
	wire                               ddr2_we_n_fpga;
	wire [CKE_WIDTH-1:0]               ddr2_cke_fpga;
	wire [CK_WIDTH-1:0]                ddr2_ck_p_fpga;
	wire [CK_WIDTH-1:0]                ddr2_ck_n_fpga;

	wire [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr2_cs_n_fpga;

	wire [DM_WIDTH-1:0]                ddr2_dm_fpga;

	wire [ODT_WIDTH-1:0]               ddr2_odt_fpga;

	ddr2_model u_comp_ddr2
	(
	 .ck      (ddr2_ck_p_fpga),
	 .ck_n    (ddr2_ck_n_fpga),
	 .cke     (ddr2_cke_fpga),
	 .cs_n    (ddr2_cs_n_fpga),
	 .ras_n   (ddr2_ras_n_fpga),
	 .cas_n   (ddr2_cas_n_fpga),
	 .we_n    (ddr2_we_n_fpga),
	 .dm_rdqs (ddr2_dm_fpga),
	 .ba      (ddr2_ba_fpga),
	 .addr    (ddr2_addr_fpga),
	 .dq      (ddr2_dq_fpga),
	 .dqs     (ddr2_dqs_p_fpga),
	 .dqs_n   (ddr2_dqs_n_fpga),
	 .rdqs_n  (),
	 .odt     (ddr2_odt_fpga)
	 );

    quasi_main pcpu_main_inst
    (
        .sysclk(clk),
        .btn(btn),
        .led(led),
		.sw(sw),

		 .ddr2_dq              (ddr2_dq_fpga),
		 .ddr2_dqs_n           (ddr2_dqs_n_fpga),
		 .ddr2_dqs_p           (ddr2_dqs_p_fpga),

		 .ddr2_addr            (ddr2_addr_fpga),
		 .ddr2_ba              (ddr2_ba_fpga),
		 .ddr2_ras_n           (ddr2_ras_n_fpga),
		 .ddr2_cas_n           (ddr2_cas_n_fpga),
		 .ddr2_we_n            (ddr2_we_n_fpga),
		 .ddr2_ck_p            (ddr2_ck_p_fpga),
		 .ddr2_ck_n            (ddr2_ck_n_fpga),
		 .ddr2_cke             (ddr2_cke_fpga),
		 .ddr2_cs_n            (ddr2_cs_n_fpga),

		 .ddr2_dm              (ddr2_dm_fpga),

		 .ddr2_odt             (ddr2_odt_fpga),

        //.sd_dat0(sd_dat0),

		//.psram_ce(psram_ce),
		//.psram_mosi(psram_mosi),
		//.psram_miso(psram_miso),
		//.psram_sio2(psram_sio2),
		//.psram_sio3(psram_sio3),
		//.psram_sclk(psram_sclk),

		//.eth_intn(eth_intn),
		//.eth_rstn(eth_rstn),
		//.eth_sclk(eth_sclk),
		//.eth_scsn(eth_scsn),
		//.eth_mosi(eth_mosi),
		//.eth_miso(eth_miso),
		.uart_rx(rx),
		.uart_tx(tx)
		//.uart_rx_2(1)
		//.ch375_tx(ch375_tx)
	);
    
    initial begin
        clk = 0;
        forever #5000 clk = ~clk;
    end

    initial begin
		ch375_tx = 1;
        //#400
        sw = 2'b01;
		btn = 2'b11;
        //btn = 4'b0000;
        //#2000
        //sw = 2'b10;
        #4000000
        sw = 2'b00;
		btn = 2'b00;

        //#10
        //btn = 4'b0000;

        //#1000
        //btn = 4'b0010;

        #22000000
		rx = 0;
		#30
		rx = 1;
		//#200000000;
		#2500000000.0;
		$finish;
        #50000000

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
		//#200000;
        $finish;
    end
    
endmodule
