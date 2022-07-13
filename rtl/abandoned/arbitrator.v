/**
 * File              : arbitrator.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.03.26
 * Last Modified Date: 2021.03.26
 */
`timescale 1ns / 1ps
// pCPU bus arbitrator
// demux cpu, gpu, dbu and connect to mmapper

module arbitrator
    (
		input clk,
		input rst,

        input [31:0]cpu_a,
        input [31:0]cpu_d,
        input cpu_we,
        input cpu_rd,
        output reg [31:0]cpu_spo,
        output reg cpu_ready = 1,
        output reg cpu_grant = 0,

        input [31:0]gpu_a,
        input [31:0]gpu_d,
        input gpu_we,
        input gpu_rd,
        output reg [31:0]gpu_spo,
        output reg gpu_ready = 1,
        output reg gpu_grant = 0,

        input [31:0]dbu_a,
        input [31:0]dbu_d,
        input dbu_we,
        input dbu_rd,
        output reg [31:0]dbu_spo,
        output reg dbu_ready = 1,
        output reg dbu_grant = 0,

        (*mark_debug = "true"*)output reg [31:0]a,
        (*mark_debug = "true"*)output reg [31:0]d,
        (*mark_debug = "true"*)output reg we,
		(*mark_debug = "true"*)output reg rd,
        (*mark_debug = "true"*)input [31:0]spo,
		(*mark_debug = "true"*)input ready
    );

    always @ (*) begin 
    end

    always @ (posedge clk) begin
		if (rst) begin
		end else begin
		end
    end
endmodule
