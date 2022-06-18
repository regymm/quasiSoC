/**
 * File              : memory_controller_burst.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.12.01
 * Last Modified Date: 2022.02.25
 */
// Memory controller
// burst mode: 
//  read: each single-cycle ready pulse means new 32bit data
//  write: each single-cycle ready pulse means new
//         data should be sent on d, 1 cycle later at least
//         TODO: new addr length!![1:0]
//  TODO: poor timing, reduce clk_mem domain logic
//  clk 62.5M, clk_mem 125M

`timescale 1ns / 1ps

module memory_controller_burst
	(
		input rst, 
		input clk, 
		input clk_mem,

		input burst_en,
		input [7:0]burst_length,

		input [23:0]a, 
		input [31:0]d, 
		input we, 
		input rd, 
		output [31:0]spo, 
		output ready, 

		output irq,

		output psram_ce, 
		inout psram_mosi, 
		inout psram_miso, 
		inout psram_sio2,
		inout psram_sio3,
		output psram_sclk
    );

	wire [31:0]data = d;

	reg [31:0]regspo;
	assign spo = regspo;
	//wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};
	//assign spo = {regspo[7:0], regspo[15:8], regspo[23:16], regspo[31:24]};

	reg ready_r = 0;
	reg ready_r_old = 0;
	reg ready_delay = 0;
	always @ (posedge clk_mem) begin
		ready_r_old <= ready_r;
		ready_delay = (ready_r & !ready_r_old);
	end
	//wire ready_slow = ready_r | ready_r_old;
	//reg ready_slow_reg;
	//always @ (posedge clk) begin
		//ready_slow_reg <= ready_slow;
	//end
	// TODO: this combinatorial may cause problem if 
	// rd/we and clk are not aligned
	//assign ready = ready_slow_reg & !(rd | we);
	assign ready = (ready_r | ready_delay) & !(rd | we);

	reg [23:0]rega;
	/*(*mark_debug = "true"*)*/reg [7:0]regbuf[3:0];

	reg regburst_en;
	reg [7:0]regburst_length;

	reg [5:0]count;

	reg m_rd = 0; 
	reg m_rend; 
	reg m_we = 0; 
	reg m_wend; 
	wire [23:0]m_a = rega;
	wire [7:0]m_dout; 
	wire m_byte_available;
	wire [7:0]m_din = regbuf[count];
	wire m_ready_for_next_byte;
	wire m_ready;

    //// slow clock
    //reg [4:0]clkcounter = 0;
    //always @ (posedge clk) begin
        //if (rst) clkcounter <= 5'b0;
        //else clkcounter <= clkcounter + 1;
    //end
    //wire clk_pulse_slow = (clkcounter[1:0] == 2'b0);

	psram_controller_fast psram_controller_fast_inst
	(
		.rst(rst), 
		.clk(clk), 
		.clk_mem(clk_mem), 
		//.clk_pulse_slow(clk_pulse_slow),

		.ce(psram_ce), 
		.mosi(psram_mosi), 
		.miso(psram_miso), 
		.sio2(psram_sio2),
		.sio3(psram_sio3),
		.sclk(psram_sclk), 

		.rd(m_rd), 
		.rend(m_rend), 
		.we(m_we), 
		.wend(m_wend), 
		.a(m_a), 
		.dout(m_dout), 
		.byte_available(m_byte_available), 
		.din(m_din), 
		.ready_for_next_byte(m_ready_for_next_byte), 

		.ready(m_ready)
	);

    reg m_byte_available_old = 0;
    reg m_ready_for_next_byte_old = 0;
	/*(*mark_debug = "true"*)*/reg byte_available_posedge;
	/*(*mark_debug = "true"*)*/reg ready_for_next_byte_posedge;
    always @ (posedge clk_mem) begin
		if (rst) begin
			m_byte_available_old <= 0;
			m_ready_for_next_byte_old <= 0;
		end else begin
			m_byte_available_old <= m_byte_available;
			m_ready_for_next_byte_old <= m_ready_for_next_byte;
		end
    end
	always @ (*) begin
		byte_available_posedge = !m_byte_available_old & m_byte_available;
		ready_for_next_byte_posedge = !m_ready_for_next_byte_old & m_ready_for_next_byte;
	end

	localparam	IDLE		=	0;
	localparam	WE_BEGIN	=	5;
	localparam	WE			=	10;
	localparam	RD_BEGIN	=	15;
	localparam	RD			=	20;
	/*(*mark_debug = "true"*)*/reg [5:0]state = IDLE;

	always @ (posedge clk_mem) begin
		if (state == IDLE | (state == WE & count == 0 & regburst_en & regburst_length != 0)) begin
			regbuf[3] <= data[31:24];
			regbuf[2] <= data[23:16];
			regbuf[1] <= data[15:8];
			regbuf[0] <= data[7:0];
		end else if (state == RD & byte_available_posedge) begin
			regbuf[count - 1] <= m_dout;
		end
		// the two cases shall not overlap
	end


	always @ (posedge clk_mem) begin
		if (rst) begin
			m_rd <= 0; 
			//m_rend <= 0;
			m_we <= 0;
			//m_wend <= 0;
			state <= IDLE;
			ready_r <= m_ready;
			//count <= 0;
		end else begin
			case (state)
				// go IDLE right after reset, but first memory operation will
				// hang until the psram is ready
				IDLE: begin
					if (we) begin
						state <= WE_BEGIN;
						ready_r <= 0;
						count <= 4;
						//regbuf_w <= 0;
					end else if (rd) begin
						state <= RD_BEGIN;
						ready_r <= 0;
						count <= 4;
						//regbuf_w <= 0;
					end else ready_r <= m_ready;
					regburst_en <= burst_en;
					regburst_length <= burst_length;
					rega <= a;
					//regbuf_w <= 1;
					m_wend <= 0;
					m_rend <= 0;
					//count <= 4;
				end
				WE_BEGIN: begin
					if (m_ready) begin
						m_we <= 1;
						state <= WE;
						//count <= 4;
					end
				end
				WE: begin
					m_we <= 0;
					if (ready_for_next_byte_posedge) begin
						count <= count - 1;
						if (count == 3 & regburst_en) begin
							// last element don't need additional ready -- no next element!
							if (regburst_length != 1)
								ready_r <= 1;
							regburst_length <= regburst_length - 1;
						end
					end else ready_r <= 0;
					if (count == 0) begin
						if (!regburst_en | (regburst_en & regburst_length == 0)) begin
							state <= IDLE;
							m_wend <= 1;
							// when return, m_ready still not, continue
							// wait in IDLE state
						end else begin
							state <= WE;
							count <= 4;
							// new value should present now
							// assignment in another always
						end
					end
					if (count == 0 & (!regburst_en | (regburst_en & regburst_length == 0))) begin
						state <= IDLE;
						m_wend <= 1;
					end
				end
				RD_BEGIN: begin
					if (m_ready) begin
						m_rd <= 1;
						state <= RD;
						//count <= 4;
					end
				end
				RD: begin
					m_rd <= 0;
					if (byte_available_posedge) begin
						count <= count - 1;
						//regbuf[count - 1] <= m_dout;
						// to avoid multidriven
					end
					if (count == 1 & 
						(!regburst_en | 
						regburst_en & regburst_length == 1))
						m_rend <= 1;
					if (count == 0) begin
						regspo <= {regbuf[3], regbuf[2], regbuf[1], regbuf[0]};
						if (regburst_en) begin
							regburst_length <= regburst_length - 1;
							if (regburst_length == 1)
								state <= IDLE;
							else begin
								state <= RD;
								count <= 4;
								ready_r <= 1;
							end
						end else begin
							state <= IDLE;
						end
					end else ready_r <= 0;
				end
			endcase
		end
	end
endmodule
