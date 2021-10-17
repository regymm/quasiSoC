/**
 * File              : mmapper.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.24
 * Last Modified Date: 2021.01.24
 */
`timescale 1ns / 1ps
// pCPU memory address mapper (or "bus")

module mmapper
    (
        (*mark_debug = "true"*)input [31:0]a,
        (*mark_debug = "true"*)input [31:0]d,
        (*mark_debug = "true"*)input we,
        (*mark_debug = "true"*)input rd,
        (*mark_debug = "true"*)output reg [31:0]spo,
        (*mark_debug = "true"*)output reg ready,

        // 1024*32(8KB) boot rom: 0xf0000000 to 0xf00007fc
        output reg [9:0]bootm_a,
		output reg bootm_rd,
        input [31:0]bootm_spo,
		input bootm_ready,

        // 4096*32(32KB) distributed memory: 0x10000000 to 0x10007ffc
        output reg [31:0]distm_a,
        output reg [31:0]distm_d,
        output reg distm_we,
		output reg distm_rd,
        input [31:0]distm_spo,
		input distm_ready,

		// cache
        output reg [31:0]cache_a,
        output reg [31:0]cache_d,
        output reg cache_we,
        output reg cache_rd,
        input [31:0]cache_spo,
        input cache_ready,

		// 8MB PSRAM: 0x20000000 to 0x21fffffc

        //// special devices:
        //// counter 0x50000000
        //// RNG 0x50000004
        //// this should be moved into cp0
        //output reg [1:0]special_a = 0,
        //output reg [31:0]special_d = 0,
        //output reg special_we = 0,
        //input [31:0]special_spo,


        // MMIO devices (slow)
        // 
        // gpio: 0x92000000
        output reg [3:0]gpio_a,
        output reg [31:0]gpio_d,
        output reg gpio_we,
        input [31:0]gpio_spo,

        // uart: 0x93000000
        output reg [2:0]uart_a,
        output reg [31:0]uart_d,
        output reg uart_we,
        input [31:0]uart_spo,

        // vram: 0x9400000 to 0x9400
        output reg [31:0]video_a = 0,
        output reg [31:0]video_d = 0,
        output reg video_we = 0,
        input [31:0]video_spo,

        // SD card control: 0x96000000
        output reg [31:0]sd_a,
        output reg [31:0]sd_d,
        output reg sd_we,
        //output reg sd_rd,
        input [31:0]sd_spo,
        //input sd_ready,

		// CH375b: 0x97000000
		output reg [2:0]usb_a,
		output reg [31:0]usb_d,
		output reg usb_we,
		input [31:0]usb_spo,

        // interrupt unit: 0x98000000
        output reg [2:0]int_a,
        output reg [31:0]int_d,
        output reg int_we,
        input [31:0]int_spo,
        
		// serialboot: 0x99000000
		output reg [2:0]sb_a,
		output reg [31:0]sb_d,
		output reg sb_we,
		input [31:0]sb_spo,
		input sb_ready,

		// PS2 keyboard: 0x9a000000
		input [31:0]ps2_spo,

		// timer control: 0x9b000000
		output reg [2:0]t_a,
		output reg [31:0]t_d,
		output reg t_we,
		input [31:0]t_spo,


		// "ethernet": 0x9c000000
		output reg [31:0]eth_a,
		output reg [31:0]eth_d,
		output reg eth_we,
		input [31:0]eth_spo,

        // 0xe0000000 MMU control

        output reg irq
    );

    always @ (*) begin 
        bootm_a = a[11:2];
        distm_a = {2'b0, a[31:2]};
        distm_d = d;
		cache_a = a;
		cache_d = d;
        gpio_a = a[5:2];
        gpio_d = d;
        uart_a = a[4:2];
        uart_d = d;
		sb_a = a[4:2];
		sb_d = d;
        video_a = a;
        video_d = d;
        sd_a = a[31:0];
        sd_d = d;
		usb_a = a[4:2];
		usb_d = d;
        int_a = a[4:2];
        int_d = d;
		t_a = a[4:2];
		t_d = d;
		eth_a = a;
		eth_d = d;
    end

    always @ (*) begin
        distm_we = 0;
		distm_rd = 0;
		cache_we = 0;
		cache_rd = 0;
        gpio_we = 0;
        uart_we = 0;
		sb_we = 0;
        video_we = 0;
        sd_we = 0;
		usb_we = 0;
        int_we = 0;
		bootm_rd = 0;
		t_we = 0;
		eth_we = 0;
        irq = 0;
        spo = 0;
        ready = 1;
        if (a[31:28] == 4'h1) begin
            distm_we = we;
			distm_rd = rd;
            spo = distm_spo;
			ready = distm_ready;
        end else if (a[31:28] == 4'h2) begin
            cache_we = we;
            cache_rd = rd;
            spo = cache_spo;
			ready = cache_ready;
        end else if (a[31:28] == 4'h9) begin
            case (a[27:24])
                4'h2: begin
                    spo = gpio_spo;
                    gpio_we = we;
                end
                4'h3: begin
                    spo = uart_spo;
                    uart_we = we;
                end
                4'h4: begin
                    spo = video_spo;
                    video_we = we;
                end
                4'h6: begin
                    spo = sd_spo;
                    sd_we = we;
                end
                4'h7: begin
                    spo = usb_spo;
                    usb_we = we;
				end
				4'h8: begin
					spo = int_spo;
					int_we = we;
                end
				4'h9: begin
					spo = sb_spo;
					sb_we = we;
					ready = sb_ready;
				end
				4'ha: begin
					spo = ps2_spo;
				end
				4'hb: begin
					spo = t_spo;
					t_we = we;
				end
				4'hc: begin
					spo = eth_spo;
					eth_we = we;
				end
                default: irq = 1;
            endcase
        end else if (a[31:28] == 4'hf) begin
			bootm_rd = rd;
            spo = bootm_spo;
			ready = bootm_ready;
        end
        else irq = 1;
    end
endmodule
