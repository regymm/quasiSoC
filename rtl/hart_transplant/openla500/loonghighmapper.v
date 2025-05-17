// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm

`timescale 1ns / 1ps
// high mapper -- mux memory and MMIO slow devices apart
// should have good timing

module highmapper
    (
        (*mark_debug = "true"*)input [31:0]a,
        (*mark_debug = "true"*)input [31:0]d,
        (*mark_debug = "true"*)input [3:0]web,
        (*mark_debug = "true"*)input rd,
        (*mark_debug = "true"*)output reg [31:0]spo,
        (*mark_debug = "true"*)output reg ready,

        output reg [31:0]mem_a,
        output reg [31:0]mem_d,
        output reg [3:0]mem_web,
		output reg mem_rd,
        input [31:0]mem_spo,
		input mem_ready,

        output reg [31:0]mmio_a,
        output reg [31:0]mmio_d,
        output reg [3:0]mmio_web,
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
        mem_web = 0;
		mem_rd = 0;
		mmio_web = 0;
		mmio_rd = 0;
        spo = 0;
        ready = 1;
        if (a[31:28] == 4'h0) begin
            mem_web = web;
			mem_rd = rd;
            spo = mem_spo;
			ready = mem_ready;
        end else begin
            mmio_web = web;
            mmio_rd = rd;
            spo = mmio_spo;
			ready = mmio_ready;
        end
    end
endmodule
