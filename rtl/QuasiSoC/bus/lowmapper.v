/**
 * File              : lowmapper.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.07.02
 * Last Modified Date: 2022.07.02
 */
`timescale 1ns / 1ps
// low mapper -- mux various MMIO devices
// should not give burden on timing

module mmapper
    (
		input clk,
		input rst,

        (*mark_debug = "true"*)input [31:0]a,
        (*mark_debug = "true"*)input [31:0]d,
        (*mark_debug = "true"*)input we,
        (*mark_debug = "true"*)input rd,
        (*mark_debug = "true"*)output [31:0]spo,
        (*mark_debug = "true"*)output ready,

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
		`ifdef AXI_GPIO_TEST
		output gpio_rd,
		input gpio_ready,
		`endif

        // uart: 0x93000000
        output reg [2:0]uart_a,
        output reg [31:0]uart_d,
        output uart_we,
        input [31:0]uart_spo,

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

        //// 0xe0000000 MMU control

        output reg irq
    );

	reg [31:0]a_r;
	reg [31:0]d_r;
	reg we_r;
	reg rd_r;
	reg [31:0]required_spo;
	reg required_ready;

	wire [3:0]aid1 = a[31:28];
	wire [3:0]aid2 = a[27:24];

	reg [2:0]state = 0;
	assign ready = (state == 0) & !(we | rd);
	assign spo = required_spo;

	always @ (posedge clk) begin
		if (rst) begin
			state <= 0;
		end else begin
			case (state)
				// latch request
				0: begin if (we | rd) begin
					state <= 1;
					a_r <= a;
					d_r <= d;
					we_r <= we;
					rd_r <= rd;
				end end
				// wait...
				1: begin if (aid1 == 9) state <= 2;
					else state <= 3; end
				// issue r/w
				2: state <= 4;
				3: state <= 4;
				// wait for ready
				4: if (required_ready) state <= 0;
				default: state <= 0;
			endcase
		end
	end

	assign gpio_we = (state == 2 & aid2 == 2) ? we_r : 0;
	`ifdef AXI_GPIO_TEST
	assign gpio_rd = (state == 2 & aid2 == 2) ? rd_r : 0;
	`endif
	assign uart_we = (state == 2 & aid2 == 3) ? we_r : 0;
	assign video_we = (state == 2 & aid2 == 4) ? we_r : 0;
	assign sd_we = (state == 2 & aid2 == 6) ? we_r : 0;
	assign usb_we = (state == 2 & aid2 == 7) ? we_r : 0;
	assign int_we = (state == 2 & aid2 == 8) ? we_r : 0;
	assign sb_we = (state == 2 & aid2 == 9) ? we_r : 0;
	assign t_we = (state == 2 & aid2 == 4'hb) ? we_r : 0;
	assign eth_we = (state == 2 & aid2 == 4'hc) ? we_r : 0;
	assign distm_we = (state == 3 & aid1 == 1) ? we_r : 0;
	assign distm_rd = (state == 3 & aid1 == 1) ? rd_r : 0;
	assign bootm_rd = (state == 3 & aid1 == 4'hf) ? rd_r : 0;

	// update ready/spo every other cycle
	// hope this can save some timings
	reg [1:0]state2 = 0;
	always @ (posedge clk) begin
		case (state2)
			0: state2 <= aid1 == 9 ? 1 : 2;
			1: begin
				state2 <= 0;
				required_ready <= 1;
				case (aid2)
					2: begin
						required_spo <= gpio_spo;
						`ifdef AXI_GPIO_TEST
						required_ready <= gpio_ready;
						`endif
					end
					3: required_spo <= uart_spo; 
					4: required_spo <= video_spo; 
					6: required_spo <= sd_spo; 
					7: required_spo <= usb_spo; 
					8: required_spo <= int_spo; 
					9: begin required_spo <= sb_spo;  required_ready <= sb_ready; end
					4'ha: required_spo <= ps2_spo;
					4'hb: required_spo <= t_spo; 
					4'hc: required_spo <= eth_spo;
					default: required_spo <= 0;
				endcase
			end
			2: begin
				state2 <= 0;
				case (aid1)
					1: begin required_spo <= distm_spo; required_ready <= distm_ready; end
					4'hf: begin required_spo <= bootm_spo; required_ready <= bootm_ready; end
					default: begin required_spo <= 0; required_ready <= 1; end
				endcase
			end
			default: state2 <= 0;
		endcase
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
    end

endmodule
