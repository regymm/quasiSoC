/**
 * File              : sdram.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2024.05.26
 * Last Modified Date: 2025.10.08
 */
`timescale 1ns / 1ps
`default_nettype wire

// a:
// 0x1000
// 0x1004
//
// data_address (DATA_WIDTH=8):
// 0x1000 -> 0x1000, 0x1001, 0x1002, 0x1003
// 0x1004 -> 0x1004, ...
//
// data_address (DATA_WIDTH=16):
// 0x1000 -> 0x800, 0x801
// 0x1004 -> 0x802, 0x803
//
// LSB(7:0) at low address
// ONLY 16-bit TESTED FOR NOW!

module sdram #(
	parameter DATA_WIDTH = 16,
    parameter DQM_WIDTH = 2,
    parameter BANK_ADDRESS_WIDTH = 2,
    parameter ROW_ADDRESS_WIDTH = 13,
    parameter COLUMN_ADDRESS_WIDTH = 9,

    parameter CAS_LATENCY = 3,
    parameter BURST_LENGTH = 2,

    parameter CLOCK_FREQ = 50000000,
    parameter INIT_WAIT_CYCLES = 9999,
    parameter REFRESH_WAIT_CYCLES = 390
) (
    input clk,
    input rst,

    input [31:0]a, // as convention, a is 32-bit aligned
    input [31:0]d,
    input we,
    input rd,
    output [31:0]spo,
    output ready,
    // only allow aligned access e.g. 4-byte on 0x4, 2-byte on 0x2, 1-byte on 0x3
    // for now, only allow 0x4 aligned, a.k.a. a[1:0] == 2'b00
    // row: a[12:0]
    // bank: a[15:13]
    // col: a[24:15]

    output wire ck,
	(* mark_debug = "true" *)output wire ce,
	(* mark_debug = "true" *)output reg [BANK_ADDRESS_WIDTH-1:0] ba,
	(* mark_debug = "true" *)output reg [ROW_ADDRESS_WIDTH-1:0] addr, // the larger of ROW or COLUMN ADDRESS WIDTH
	(* mark_debug = "true" *)output wire cs_n,
	(* mark_debug = "true" *)output wire ras_n,
	(* mark_debug = "true" *)output wire cas_n,
	(* mark_debug = "true" *)output wire we_n,
	(* mark_debug = "true" *)output reg [DQM_WIDTH-1:0] dqm = {DQM_WIDTH{1'b0}},
	(* mark_debug = "true" *)inout wire [DATA_WIDTH-1:0] dq
    );
    reg [31:0]a_reg = 0;
    reg [31:0]d_reg = 0;
    reg [31:0]spo_reg = 0;
    wire spo_shiftin;
    assign spo = spo_reg;
    reg we_reg = 0;
    reg rd_reg = 0;

    // wire [12:0]a_row = a_reg[14:2];
    // wire [1:0]a_bank = a_reg[16:15];
    // wire [9:0]a_col = a_reg[26:17]; // 8:0 actually, total 256 Mb, 2+13+9 bit address x 16-bit data
    wire [12:0]a_row = a_reg[22:10];
    wire [1:0]a_bank = a_reg[24:23];
    wire [8:0]a_col = {a_reg[9:2], 1'b0};

    assign ck = ~clk;

    // mt48lc16m16a2 datasheet page 43
    initial begin
        if (INIT_WAIT_CYCLES*1e6/CLOCK_FREQ < 100) $error("100us required for initialization."); //
        if (REFRESH_WAIT_CYCLES*1e6/CLOCK_FREQ > 7.813) $error("7.813us minimum interval required for refresh.");
        if (tRP*1e9/CLOCK_FREQ < 20) $error("tRP must be at least 20ns.");
        if (tRCD*1e9/CLOCK_FREQ < 20) $error("tRCD must be at least 20ns.");
        if (tRFC*1e9/CLOCK_FREQ < 66) $error("tRFC must be at least 66ns.");
        if (tRCD*1e9/CLOCK_FREQ < 20) $error("tRCD must be at least 20ns.");
        // tRP e.g. 20 ns, 2 cycles (1 spare)
        // tRFC e.g. 66 ns, 7 cycles (6 spare)
        // tMRD 2 cycles
        // tRCD e.g. 20 ns, 2 cydles (1 spare)
    end
    localparam tRP = 2 + 1;
    localparam tRCD = 2 + 1; // same as tRP
    localparam tRFC = 7 + 1;
    localparam tMRD = 2 + 1;
    localparam tWR = 2 + 1;
    localparam REFRESH_CYCLE = tRFC;
    localparam READ_CYCLE = tRCD + 4 + tRP-1; // burst length 2 or 4, finish before precharge and wait
    localparam WRITE_CYCLE = tRCD + (32/DATA_WIDTH) + tWR + tRP-1;
	(* mark_debug = "true" *)reg [15:0]cnt = 0;
	reg [1:0] rcnt = 0;

	localparam IDLE = 0;
	localparam INIT = 1;
	localparam READ = 2;
	localparam WRITE = 3;
	localparam REFRESH = 4;
	(* mark_debug = "true" *)reg [2:0]state = INIT;

    // CS# RAS# CAS# WE#
    localparam INHIBIT = 4'b1111;
    localparam NOP = 4'b0111;
    localparam AUTO_REFRESH = 4'b0001;
    localparam PRECHARGE = 4'b0010;
    localparam ACTIVATE = 4'b0011;
    localparam WRITE_CMD = 4'b0100;
    localparam READ_CMD = 4'b0101;
    localparam SET_MODE = 4'b0000;
    (* mark_debug = "true" *)reg [3:0]command = INHIBIT;

    always @ (posedge clk) begin
		if (rst) begin
			state <= INIT;
			cnt <= INIT_WAIT_CYCLES + tMRD + tRFC + tRFC + tRP + 2; // long enough
			rcnt <= REFRESH_WAIT_CYCLES;
		end else if (state == INIT) begin
            cnt <= cnt - 1;
            if (cnt == 0) begin
                state <= IDLE;
                rcnt <= REFRESH_WAIT_CYCLES;
            end
		end else if (state == IDLE) begin
            if (rd) begin
                state <= READ;
                cnt <= READ_CYCLE;
                a_reg <= a;
                rd_reg <= rd;
                we_reg <= 0;
                spo_reg <= 0;
            end else if (we) begin
                state <= WRITE;
                cnt <= WRITE_CYCLE;
                a_reg <= a;
                d_reg <= d;
                we_reg <= we;
                rd_reg <= 0;
            end else if (rcnt == 0) begin
                state <= REFRESH;
                cnt <= REFRESH_CYCLE;
                rcnt <= REFRESH_WAIT_CYCLES;
            end
		end else if (state == WRITE) begin
            cnt <= cnt - 1;
            if (cnt == 0) begin
                state <= IDLE;
                cnt <= REFRESH_WAIT_CYCLES;
                we_reg <= 0;
            end
        end else if (state == READ) begin
            cnt <= cnt - 1;
            if (cnt == 0) begin
                state <= IDLE;
                cnt <= REFRESH_WAIT_CYCLES;
                rd_reg <= 0;
            end
            if (spo_shiftin) begin
                spo_reg <= {spo_reg[(31-DATA_WIDTH):0], dq};
            end
        end else if (state == REFRESH) begin
            cnt <= cnt - 1;
            if (cnt == 0) begin
                rcnt <= REFRESH_WAIT_CYCLES;
                if (rd | rd_reg) begin
                    state <= READ;
                    cnt <= READ_CYCLE;
                end else if (we | we_reg) begin
                    state <= WRITE;
                    cnt <= WRITE_CYCLE;
                end else begin
                    state <= IDLE;
                end
            end
            if (rd | we) begin
                a_reg <= a;
                d_reg <= d;
                we_reg <= we;
                rd_reg <= rd;
                spo_reg <= 0;
            end
        end
        if (rcnt != 0) rcnt <= rcnt - 1;
    end

    always @ (*) begin
        command = INHIBIT;
        addr = 0;
        ba = 0;
        case (state)
            INIT: begin
                case (cnt)
                    tRP + tRFC + tRFC + tMRD: begin command = PRECHARGE; addr = 16'h0400; end
                    tRFC + tRFC + tMRD: command = AUTO_REFRESH;
                    tRFC + tMRD: command = AUTO_REFRESH;
                    // 000 0-Programmed burst length 00 011-CAS 3 0-sequential burst 001-burst length 2
                    tMRD: begin command = SET_MODE; addr = 16'h0031; end
                endcase
            end
            IDLE: ;
            READ: begin
                case (cnt)
                    tRCD + 4 + tRP-1: begin command = ACTIVATE; ba = a_bank; addr = a_row; end
                    4 + tRP-1: begin command = READ_CMD; ba = a_bank; addr = {5'b0, a_col}; end
                    tRP-1: begin command = PRECHARGE; ba = a_bank; end
                endcase
            end
            WRITE: begin
                case (cnt)
                    tRCD + (32/DATA_WIDTH) + tWR + tRP-1: begin command = ACTIVATE; ba = a_bank; addr = a_row; end
                    (32/DATA_WIDTH) + tWR + tRP-1: begin command = WRITE_CMD; ba = a_bank; addr = {5'b0, a_col}; end
                    tRP-1: begin command = PRECHARGE; ba = a_bank; end
                endcase
            end
            REFRESH: begin
                case (cnt)
                    tRFC: command = AUTO_REFRESH;
                endcase
            end
        endcase
    end
    assign dq = (state == WRITE & cnt >= 1 + tWR + tRP-1 & cnt <= (32/DATA_WIDTH) + tWR + tRP-1) ? d_reg >> (cnt[0] ? 16 : 0) : {DATA_WIDTH{1'bz}}; // TODO: change 16 to WIDTH-dependent
    assign ce = (rst | (state == INIT && cnt >= tMRD + tRFC + tRFC + tRP + 2*5)) ? 1'b0 : 1'b1;
    assign {cs_n, ras_n, cas_n, we_n} = command;
    assign spo_shiftin = (state == READ & cnt >= 4 + tRP-1 - CAS_LATENCY - (32/DATA_WIDTH) + 2 & cnt <= 4 + tRP-1 - CAS_LATENCY + 1);
    // assign ba = (command == ACTIVATE | command == WRITE_CMD | command == READ_CMD | command == PRECHARGE) ? a_reg[12:11] : 0;
    // assign addr = (command == ACTIVATE) ? a_reg[24:13] : (command == WRITE_CMD | command == READ_CMD) ? {4'b0, a_reg[10:2]} : 0;
    // precharge single bank, no auto precharge

	assign ready = (state == IDLE || state == REFRESH) & !(we | rd | we_reg | rd_reg);
endmodule
