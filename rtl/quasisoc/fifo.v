/**
 * File              : fifo.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.07.02
 * Last Modified Date: 2022.07.02
 */

module myfifo
#(
	parameter WIDTH = 32,
	parameter DEPTH = 16
)
(
	input clk,
	input rst,

	input enq,
	input [WIDTH-1:0]din,
	input deq,
	output [WIDTH-1:0]dout,
	output empty,
	output full
);
	reg [$clog2(DEPTH)-1:0]head = 0;
	reg [$clog2(DEPTH)-1:0]tail = 0;
	assign empty = head == tail;
	assign full = tail+1 == head;

	reg [WIDTH-1:0]d[DEPTH-1:0];

	assign dout = d[head];

	always @ (posedge clk) begin
		if (rst) begin
			head <= 0;
			tail <= 0;
		end
		if (enq & (!full | deq)) begin
			tail <= tail + 1;
			d[tail] <= din;
		end
		if (deq & !empty) begin
			head <= head + 1;
		end
	end
endmodule
