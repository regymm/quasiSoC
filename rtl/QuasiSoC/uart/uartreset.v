/**
 * File              : uartreset.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2021.04.25
 * Last Modified Date: 2021.10.17
 */

// generate reset signal when a certain character is
// sent via UART several times
// with this and serialboot, everything on the board
// can be controlled by computer w/o pressing buttons

module uartreset #(
		parameter RESET_CHARACTER = 82, // "R"
		parameter RESET_COUNT = 10
	)(
		input clk,

		(*mark_debug = "true"*) input [7:0]uart_data,
		(*mark_debug = "true"*) input uart_ready,

		(*mark_debug = "true"*) output uart_rst
	);
	reg [7:0]count = 0;
	reg uart_rst_reg = 0;
	always @ (posedge clk) begin
		if (uart_ready) begin
			if (uart_data == RESET_CHARACTER) begin
				if (count >= RESET_COUNT) begin
					uart_rst_reg <= 1;
					//count <= 0;
				end else count <= count + 1;
			end else begin
				count <= 0;
				uart_rst_reg <= 0;
			end
		end
	end
	assign uart_rst = uart_rst_reg;
endmodule
