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
// UART input format: hexadecimal 0-9a-f, 
// any illegal character is skipped
// a blank(0x20) to end
//
// must keep sure memory writing is faster than
// uart input -- don't have UART CTS/RTS so 
// cannot handle faster input anyways
//
// cpu access to memory will pass through this 
// module, which is easier to require memory 
// module to have additional override functions

module serialboot(
	input clk,
	input rst,

	// serialboot's control port
	input [2:0]a,
	input [31:0]d,
	input we,
	output ready,

	// cpu(or cache)'s bus access of memory
	input burst_en_cpu,
	input [7:0]burst_length_cpu,
	input [31:0]a_cpu,
	input [31:0]d_cpu,
	input we_cpu,
	input rd_cpu,
	output [31:0]spo_cpu,
	output ready_cpu,

	// port to memory -- with override of this
	// module when serialbooting
	output burst_en_mem,
	output [7:0]burst_length_mem,
	output [31:0]a_mem,
	output [31:0]d_mem,
	output we_mem,
	output rd_mem,
	input [31:0]spo_mem,
	input ready_mem,

	(*mark_debug = "true"*)input [7:0]uart_data,
	(*mark_debug = "true"*)input uart_ready
	);

	wire [31:0]sb_a;
	wire [31:0]sb_d;
	wire sb_we;
	wire override;

	assign burst_en_mem = override ? 0 : burst_en_cpu;
	assign burst_length_mem = override ? 0 : burst_length_cpu;
	assign a_mem = override ? sb_a : a_cpu;
	assign d_mem = override ? sb_d : d_cpu;
	assign we_mem = override ? sb_we : we_cpu;
	assign rd_mem = rd_cpu;
	assign spo_cpu = spo_mem;
	assign ready_cpu = ready_mem;

	// TODO first avoid fake positive
	reg [3:0]uart_data_bin;
	reg uart_data_valid;
	always @ (*) begin
		uart_data_bin = 4'hF;
		uart_data_valid = 0;
		if (uart_data >= 8'h30 && uart_data <= 8'h39) begin
			uart_data_bin = uart_data[3:0];
			uart_data_valid = 1;
		end
		else if (uart_data >= 8'h61 && uart_data <= 8'h66) begin
			uart_data_bin = uart_data[3:0] + 9;
			uart_data_valid = 1;
		end
		//else if (uart_data == 8'h20) // space to end
			//uart_data_bin = 4'hE; // dummy
		//else uart_data_bin = 4'hF; // fail or end
	end

	reg began;
	wire finish = uart_data == 8'h20;

	reg [2:0]uart_byte_cnt;
	reg [3:0]uart_byte[7:0];
	always @ (posedge clk) begin
		if (rst) begin
			uart_byte_cnt <= 0;
		end else begin
			if (uart_ready && uart_data_valid) begin
				uart_byte[uart_byte_cnt] <= uart_data_bin;
				uart_byte_cnt <= uart_byte_cnt + 1;
			end
		end
	end
	reg uart_ready_prev;
	//(*mark_debug = "true"*)reg uart_ready_prev_prev;
	always @ (posedge clk) begin
		uart_ready_prev <= uart_ready;
		//uart_ready_prev_prev <= uart_ready_prev;
	end

	(*mark_debug = "true"*) reg [31:0]mem_start_addr;

	wire transferring = began && !finish;
	//assign mem_override = transferring;
	assign override = transferring;
	// sb_we must be one cycle high
	// for the last byte, the uart_ready is () when space arrived
	assign sb_we = uart_byte_cnt == 0 && uart_data_valid && uart_ready_prev && transferring;
	// mem_d can change -- it's latched in memory controller
	//assign mem_d = {uart_byte[6], uart_byte[7], uart_byte[4], uart_byte[5], uart_byte[2], uart_byte[3], uart_byte[0], uart_byte[1]};
	assign sb_d = {uart_byte[0], uart_byte[1], uart_byte[2], uart_byte[3], uart_byte[4], uart_byte[5], uart_byte[6], uart_byte[7]};
	// mem_a can change, too
	assign sb_a = mem_start_addr;
	// mem_ready is not used -- blind optimism

	always @ (posedge clk) begin
		if (rst) begin
			began <= 0;
		end else begin
			if (we && a == 3'b001)
				mem_start_addr <= {d[7:0], d[15:8], d[23:16], d[31:24]};
			else if (sb_we) begin
				mem_start_addr <= mem_start_addr + 4;
			end

			if (we && a == 3'b010)
				began <= 1;
			else if (finish)
				began <= 0;
		end
	end

	assign ready = !transferring;
endmodule
