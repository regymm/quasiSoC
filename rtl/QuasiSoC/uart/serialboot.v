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
// added fifo to support "slow" memory: a full cache miss wait
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

	// cpu's bus
	input [31:0]a_cpu,
	input [31:0]d_cpu,
	input we_cpu,
	input rd_cpu,
	output [31:0]spo_cpu,
	output ready_cpu,

	// port to memory -- with override of this
	// module when serialbooting
	output [31:0]a_mem,
	output [31:0]d_mem,
	output we_mem,
	output rd_mem,
	input [31:0]spo_mem,
	input ready_mem,

	(*mark_debug = "true"*)input [7:0]uart_data,
	(*mark_debug = "true"*)input uart_ready
	);

	reg [31:0]sb_a;
	reg [31:0]sb_d;
	reg sb_we;
	wire override;

	assign a_mem = override ? sb_a : a_cpu;
	assign d_mem = override ? sb_d : d_cpu;
	assign we_mem = override ? sb_we : we_cpu;
	assign rd_mem = rd_cpu;
	assign spo_cpu = spo_mem;
	assign ready_cpu = ready_mem;

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

	wire fifoenq;
	wire fifodeq;
	wire [31:0]fifodin;
	wire [31:0]fifodout;
	wire fifoempty;
	wire fifofull; // should never happen
	myfifo #(
		.WIDTH(32),
		.DEPTH(1024)
	) myfifo_inst (
		.clk(clk),
		.rst(rst),
		.enq(fifoenq),
		.din(fifodeq),
		.deq(fifodin),
		.dout(fifodout),
		.empty(fifoempty),
		.full(fifofull)
	);

	assign fifoenq = began & uart_ready_prev & uart_byte_cnt == 0 & uart_data_valid;
	assign fifodin = {uart_byte[0], uart_byte[1], uart_byte[2], uart_byte[3], uart_byte[4], uart_byte[5], uart_byte[6], uart_byte[7]};

	reg began = 0;
	wire finish = uart_data == 8'h20;
	wire transferring = (began & !finish) | !fifoempty;

	assign override = transferring;
	
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
			began <= 0;
			state <= 0;
			sb_we <= 0;
		end else begin
			if (we & a == 3'b001)
				sb_a <= {d[7:0], d[15:8], d[23:16], d[31:24]};
			else if (transferring) begin
				case (state)
					0: begin if (!fifoempty & ready_mem) begin
							sb_we <= 1;
							sb_d <= fifodout;
							fifodeq <= 1;
							state <= 1;
					end end
					1: begin
						sb_we <= 0;
						sb_a <= sb_a + 4;
						fifodeq <= 0;
						state <= 0;
					end
					default: state <= 0;
				endcase
			end
			if (we & a == 3'b010)
				began <= 1;
			else if (finish)
				began <= 0;
		end
	end

	assign ready = !transferring & !we;
endmodule
