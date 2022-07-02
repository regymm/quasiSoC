/**
 * File              : highmapper.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.07.02
 * Last Modified Date: 2022.07.02
 */
`timescale 1ns / 1ps
// high mapper -- mux memory and MMIO slow devices apart
// should have good timing

module highmapper
    (
		// coming from arb
        (*mark_debug = "true"*)input [31:0]a,
        (*mark_debug = "true"*)input [31:0]d,
        (*mark_debug = "true"*)input we,
        (*mark_debug = "true"*)input rd,
        (*mark_debug = "true"*)output reg [31:0]spo,
        (*mark_debug = "true"*)output reg ready,

		// main memory 0x00000000 - 0x7fffffff
        output reg [31:0]mem_a,
        output reg [31:0]mem_d,
        output reg mem_we,
		output reg mem_rd,
        input [31:0]mem_spo,
		input mem_ready,

		// beyond 0x80000000 for MMIO
        output reg [31:0]mmio_a,
        output reg [31:0]mmio_d,
        output reg mmio_we,
        output reg mmio_rd,
        input [31:0]mmio_spo,
        input mmio_ready
    );

    always @ (*) begin 
		mem_a = a;
		mem_d = d;
		mmio_a = a;
		mmio_d = d;
    end

    always @ (*) begin
        mem_we = 0;
		mem_rd = 0;
		mmio_we = 0;
		mmio_rd = 0;
        spo = 0;
        ready = 1;
        if (a[31]) begin
            mem_we = we;
			mem_rd = rd;
            spo = mem_spo;
			ready = mem_ready;
        end else begin
            mmio_we = we;
            mmio_rd = rd;
            spo = mmio_spo;
			ready = mmio_ready;
        end
    end
endmodule
