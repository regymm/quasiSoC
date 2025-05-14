// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm

`timescale 1ns / 1ps

module lowmapper
    (
		input clk,
		input rst,

        input [31:0]a,
        input [31:0]d,
        input we,
        input rd,
        output [31:0]spo,
        output ready,

        // 1024*32(8KB) boot rom: 0xf0000000 to 0xf00007fc
        output reg [9:0]bootm_a,
		output bootm_rd,
        input [31:0]bootm_spo,
		input bootm_ready,

        // 4096*32(32KB) distributed memory: 0x10000000 to 0x10007ffc
        output reg [31:0]distm_a,
        output reg [31:0]distm_d,
        output distm_we,
		output distm_rd,
        input [31:0]distm_spo,
		input distm_ready,

		//// cache 0x20000000 to 0x7ffffffc
		////   8MB PSRAM: 0x20000000 to 0x207ffffc
		////   cache control: 0x30000000
        //output reg [31:0]cache_a,
        //output reg [31:0]cache_d,
        //output reg cache_we,
        //output reg cache_rd,
        //input [31:0]cache_spo,
        //input cache_ready,

        // gpio: 0x92000000
        output reg [3:0]gpio_a,
        output reg [31:0]gpio_d,
        output gpio_we,
        input [31:0]gpio_spo,
		//`ifdef AXI_GPIO_TEST
		output gpio_rd,
		input gpio_ready,
		//`endif

		// PSPI: 0xe0000000 to 0xefffffff
		output reg [31:0]pspi_a,
		output reg [31:0]pspi_d,
		output pspi_we,
		output pspi_rd,
		input [31:0]pspi_spo,
		input pspi_ready,

        // uart: 0x93000000
        output reg [2:0]uart_a,
        output reg [31:0]uart_d,
        output uart_we,
		output uart_rd,
        input [31:0]uart_spo,
		input uart_ready,

        // uart2: 0x9d000000
        output reg [2:0]uart2_a,
        output reg [31:0]uart2_d,
        output uart2_we,
		output uart2_rd,
        input [31:0]uart2_spo,
		input uart2_ready,

        // vram: 0x9400000 to 0x9400
        output reg [31:0]video_a = 0,
        output reg [31:0]video_d = 0,
        output video_we,
        input [31:0]video_spo,

        // SD card control: 0x96000000
        output reg [31:0]sd_a,
        output reg [31:0]sd_d,
        output sd_we,
        input [31:0]sd_spo,

		// CH375b: 0x97000000
		output reg [2:0]usb_a,
		output reg [31:0]usb_d,
		output usb_we,
		input [31:0]usb_spo,

        // interrupt unit(should be plic in future): 0x98000000
        output reg [2:0]int_a,
        output reg [31:0]int_d,
        output int_we,
        input [31:0]int_spo,
        
		// serialboot: 0x99000000
		output reg [2:0]sb_a,
		output reg [31:0]sb_d,
		output sb_we,
		input [31:0]sb_spo,
		input sb_ready,

		// PS2 keyboard: 0x9a000000
		input [31:0]ps2_spo,

		// timer(aclint): 0x9b000000
		output reg [15:0]t_a,
		output reg [31:0]t_d,
		output t_we,
		input [31:0]t_spo,

		// "ethernet": 0x9c000000
		output reg [31:0]eth_a,
		output reg [31:0]eth_d,
		output eth_we,
		input [31:0]eth_spo,

        output reg irq
    );

	reg [31:0]a_r;
	reg [31:0]d_r;
	reg we_r;
	reg rd_r;
	reg [31:0]required_spo;
	reg required_ready;

	wire [15:0]aid = a_r[31:16];

	reg state = 0;
	assign ready = (state == 0) & !(we | rd);
	assign spo = required_spo;

	always @ (posedge clk) begin
		if (rst) begin
			state <= 0;
		end else begin
			case (state)
				// latch request
				0: if (we | rd) begin
					state <= 1;
					a_r <= a;
					d_r <= d;
					we_r <= we;
					rd_r <= rd;
				end
				// issue r/w and wait till ready
				1: if (required_ready) state <= 0;
			endcase
		end
	end

	assign gpio_we = (state == 1 & aid == 16'h9200) ? we_r : 0;
	assign uart_we = (state == 1 & aid == 16'h1fe0) ? we_r : 0;
	assign uart_rd = (state == 1 & aid == 16'h1fe0) ? rd_r : 0;
	assign uart2_we = (state == 1 & aid == 16'h1fe2) ? we_r : 0;
	assign uart2_rd = (state == 1 & aid == 16'h1fe2) ? rd_r : 0;
	assign video_we = (state == 1 & aid == 16'h9400) ? we_r : 0;
	assign sd_we = (state == 1 & aid == 16'h9600) ? we_r : 0;
	assign usb_we = (state == 1 & aid == 16'h9700) ? we_r : 0;
	assign int_we = (state == 1 & aid == 16'h9800) ? we_r : 0;
	assign sb_we = (state == 1 & aid == 16'h9900) ? we_r : 0;
	assign t_we = (state == 1 & aid == 16'h9b00) ? we_r : 0;
	assign eth_we = (state == 1 & aid == 16'h9c00) ? we_r : 0;
	assign distm_we = (state == 1 & aid == 16'h1d00) ? we_r : 0;
	assign distm_rd = (state == 1 & aid == 16'h1d00) ? rd_r : 0;
	assign bootm_rd = (state == 1 & aid == 16'h1c00) ? rd_r : 0;
	assign pspi_rd = (state == 1 & aid == 16'he000) ? rd_r : 0;
	assign pspi_we = (state == 1 & aid == 16'he000) ? we_r : 0;

	always @ (posedge clk) begin
		if (state == 0 & (we | rd)) begin
			required_spo <= 0;
			required_ready <= 0;
		end else if (state == 1) begin
			case (aid)
				16'h9200: required_spo <= gpio_spo;
				16'h1fe0: begin required_spo <= uart_spo; required_ready <= uart_ready; end // loongson uart16500 
				16'h9400: required_spo <= video_spo; 
				16'h9600: required_spo <= sd_spo; 
				16'h9700: required_spo <= usb_spo; 
				16'h9800: required_spo <= int_spo; 
				16'h9900: begin required_spo <= sb_spo; required_ready <= sb_ready; end
				16'h9a00: required_spo <= ps2_spo;
				16'h9b00: required_spo <= t_spo; 
				16'h9c00: required_spo <= eth_spo;
				16'h1fe2: required_spo <= uart2_spo; // loongson uart16500
				16'h1c00: begin required_spo <= bootm_spo; required_ready <= bootm_ready; end // loongson bootrom
				16'h1d00: begin required_spo <= distm_spo; required_ready <= distm_ready; end // loongson ram
				16'he000: begin required_spo <= pspi_spo; required_ready <= pspi_ready; end
				default: begin required_spo <= 32'hdeadbeef; required_ready <= 1; end
			endcase
		end
	end

	// due to some old issues, addresses need to be tuned
    always @ (*) begin 
        bootm_a = a_r[11:2];
        distm_a = {2'b0, a_r[31:2]};
        distm_d = d_r;
		//cache_a = a_r;
		//cache_d = d_r;
        gpio_a = a_r[5:2];
        gpio_d = d_r;
        uart_a = a_r[4:2];
        uart_d = d_r;
        uart2_a = a_r[4:2];
        uart2_d = d_r;
		sb_a = a_r[4:2];
		sb_d = d_r;
        video_a = a_r;
        video_d = d_r;
        sd_a = a_r;
        sd_d = d_r;
		usb_a = a_r[4:2];
		usb_d = d_r;
        int_a = a_r[4:2];
        int_d = d_r;
		t_a = a_r[15:0];
		t_d = d_r;
		eth_a = a_r;
		eth_d = d_r;
		pspi_a = a_r;
		pspi_d = d_r;
    end

endmodule
