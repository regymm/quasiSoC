/**
 * File              : serialboot.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.04.17
 * Last Modified Date: 2021.04.17
 */

// transfer UART input directly into PSRAM
// CPU will hang waiting during the process
// 
// UART input format: hexadecimal 0-9a-fA-F, 
// any illegal character is skipped
// a blank(0x20) to end
//
// added fifo to support "slow" memory: a full cache miss wait
//
// after requesting UART boot, bus will be granted to this module
// until transfer ends. After which CPU begins next command IF
`timescale 1ns / 1ps

module serialboot
(
	input clk,
	input rst,

	// serialboot's control port
	input [2:0]s_a,
	input [31:0]s_d,
	input s_we,
	output s_ready,

	output reg m_req,
	input m_gnt,
	output reg [31:0]m_a,
	output reg [31:0]m_d,
	output reg m_we,
	output m_rd,
	output [31:0]m_spo,
	input m_ready,

	(*mark_debug = "true"*)input [7:0]uart_data,
	(*mark_debug = "true"*)input uart_ready
);
	assign m_rd = 0;
	assign s_ready = !s_we;

	// 0-9A-Fa-f
	reg [3:0]uart_data_bin;
	reg uart_data_valid;
	always @ (posedge clk) begin
		if (uart_data >= 8'h30 & uart_data <= 8'h39) begin
			uart_data_bin <= uart_data[3:0];
			uart_data_valid <= 1;
		end
		else if ((uart_data >= 8'h61 & uart_data <= 8'h66) | (uart_data >= 8'h41 & uart_data <= 8'h46)) begin
			uart_data_bin <= uart_data[3:0] + 9;
			uart_data_valid <= 1;
		end else begin
			uart_data_bin <= 4'hF;
			uart_data_valid <= 0;
		end
		//else if (uart_data == 8'h20) // space to end
			//uart_data_bin = 4'hE; // dummy
		//else uart_data_bin = 4'hF; // fail or end
	end

	reg uart_ready_prev;
	(*mark_debug = "true"*)reg uart_ready_prev_prev;
	always @ (posedge clk) begin
		uart_ready_prev <= uart_ready;
		uart_ready_prev_prev <= uart_ready_prev;
	end

	reg [2:0]uart_byte_cnt;
	reg [3:0]uart_byte[7:0];
	always @ (posedge clk) begin
		if (rst) begin
			uart_byte_cnt <= 0;
		end else begin
			if (uart_ready_prev & uart_data_valid) begin
				uart_byte[uart_byte_cnt] <= uart_data_bin;
				uart_byte_cnt <= uart_byte_cnt + 1;
			end
		end
	end

	(*mark_debug = "true"*)wire fifoenq;
	(*mark_debug = "true"*)reg fifodeq;
	(*mark_debug = "true"*)wire [31:0]fifodin;
	(*mark_debug = "true"*)wire [31:0]fifodout;
	(*mark_debug = "true"*)wire fifoempty;
	(*mark_debug = "true"*)wire fifofull; // should never happen
	myfifo #(
		.WIDTH(32),
		.DEPTH(1024)
	) myfifo_inst (
		.clk(clk),
		.rst(rst),
		.enq(fifoenq),
		.din(fifodin),
		.deq(fifodeq),
		.dout(fifodout),
		.empty(fifoempty),
		.full(fifofull)
	);

	// began means real transfer is already started
	// finish means begin to finish(not finished yet)
	wire began = m_req & m_gnt;
	wire finish = uart_data == 8'h20;
	wire transferring = (began & !finish) | !fifoempty | state == 1;

	assign fifoenq = began & uart_ready_prev & uart_byte_cnt == 0 & uart_data_valid;
	assign fifodin = {uart_byte[0], uart_byte[1], uart_byte[2], uart_byte[3],
		uart_byte[4], uart_byte[5], uart_byte[6], uart_byte[7]};

	// sb_we must be one cycle high
	// for the last byte, the uart_ready is () when space arrived
	//assign sb_we = uart_byte_cnt == 0 & uart_data_valid & uart_ready_prev & transferring;
	// mem_d can change -- it's latched in memory controller
	//assign mem_d = {uart_byte[6], uart_byte[7], uart_byte[4], uart_byte[5], uart_byte[2], uart_byte[3], uart_byte[0], uart_byte[1]};
	//assign sb_d = {uart_byte[0], uart_byte[1], uart_byte[2], uart_byte[3], uart_byte[4], uart_byte[5], uart_byte[6], uart_byte[7]};
	// mem_a can change, too

	reg [1:0]state = 0;


	always @ (posedge clk) begin
		if (rst) begin
			m_req <= 0;
			state <= 0;
			m_we <= 0;
		end else begin
			if (s_we & s_a == 3'b001)
				m_a <= {s_d[7:0], s_d[15:8], s_d[23:16], s_d[31:24]};
			else if (transferring) begin
				case (state)
					0: if (!fifoempty & m_ready) begin
							m_we <= 1;
							m_d <= fifodout;
							fifodeq <= 1;
							state <= 1;
					end
					1: begin
						m_we <= 0;
						m_a <= m_a + 4;
						fifodeq <= 0;
						state <= 0;
					end
					//default: state <= 0;
				endcase
			end

			if (s_we & s_a == 3'b010)
				m_req <= 1;
			else if (began & !transferring)
				m_req <= 0;
		end
	end
endmodule
