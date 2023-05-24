/**
 * File              : vt100.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2023.05.23
 * Last Modified Date: 2023.05.23
 */

`timescale 1ns / 1ps

module vt100
	#(
		parameter CLOCK_FREQ = 62500000,
		parameter BAUD_RATE = 115200
	)
	(
		input clk,
		input rst,

		input rx,

		//input [31:0]i_a,
		//input [31:0]i_d,
		//input i_we,

		output [11:0]fb_a,
		output [15:0]fb_d,
		output fb_we
	);

	wire rxnew;
	wire [7:0]rxdata;
	uart_new #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE)
	) uart_vt100_rx (
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.rxnew(rxnew),
		.rxdata(rxdata)
	);

	wire nextchar;
	wire [7:0]charrecv;
	wire fifoempty;
	wire fifofull;
	vt100_ufifo vt100_ufifo_inst (
		.clk(clk),
		.enq(rxnew),
		.din(rxdata),
		.deq(nextchar),
		.dout(charrecv),
		.empty(fifoempty),
		.full(fifofull)
	);

	(*mark_debug = "true"*)wire [31:0]rv_v_a;
	(*mark_debug = "true"*)wire [31:0]rv_v_d;
	(*mark_debug = "true"*)wire rv_v_we;
	(*mark_debug = "true"*)wire rv_v_rd;
	(*mark_debug = "true"*)wire [31:0]rv_v_spo;

	// TODO: debloat
	riscv_multicyc #(
		.START_ADDR(32'h00000000)
	) riscv_vt100_controller (
		.clk(clk),
		.rst(rst),
		.tip(0),
		.sip(0),
		.eip(0),
		.gnt(1),
		.hrd(0),
		.a(rv_v_a),
		.d(rv_v_d),
		.we(rv_v_we),
		.rd(rv_v_rd),
		.spo(rv_v_spo),
		.ready(!(rv_v_rd | rv_v_we))
	);

	// 8 KB, 0x0000 to 0x1fff
	wire [31:0]rom_v_spo;
	clocked_rom #(
		.WIDTH(32),
		.DEPTH(11),
		.INIT("/home/petergu/quasiSoC/firmware/vt100/vt100.dat")
	) rom_vt100 (
		.clk(clk),
		.a(rv_v_a[12:2]),
		.rd(rv_v_rd),
		.spo(rom_v_spo),
		.ready()
	);

	// 8 KB, 0x4000 to 0x5fff
	wire [31:0]ram_v_spo;
	simple_ram #(
		.WIDTH(32),
		.DEPTH(11)
	) ram_vt100 (
		.clk(clk),
		.a(rv_v_a[12:2]),
		.d(rv_v_d),
		.we(rv_v_we & rv_v_a[15:14] == 2'b01),
		.rd(rv_v_rd),
		.spo(ram_v_spo),
		.ready()
	);

	assign nextchar = !rst & rv_v_we & rv_v_a[15:14] == 2'b10;
	assign fb_a = rv_v_a[13:2];
	assign fb_d = {rv_v_d[23:16], rv_v_d[31:24]};
	assign fb_we = rv_v_we & rv_v_a[15:14] == 2'b11;
	assign rv_v_spo = rv_v_a[15:14] == 2'b10 ? {charrecv, 7'b0, !fifoempty, 16'b0} :
						rv_v_a[15:14] == 2'b01 ? ram_v_spo: rom_v_spo;
	// 0x0000: ROM
	// 0x4000: RAM
	// 0x8000: UART FIFO
	// 0xC000: FB

endmodule

module vt100_ufifo // lamed uart fifo
(
	input clk,
	input enq,
	input [7:0]din,
	input deq,
	output [7:0]dout,
	output empty,
	output full
);
	reg [3:0]head = 0;
	reg [3:0]tail = 0;
	assign empty = head == tail;
	assign full = tail+4'b1 == head;

	reg [7:0]d[15:0]; // 32(31 used) buffer

	assign dout = d[head];

	always @ (posedge clk) begin
		if (enq & !full) begin
			tail <= tail + 4'b1;
			d[tail] <= din;
		end
		if (deq & !empty) begin
			head <= head + 4'b1;
		end
	end
endmodule

