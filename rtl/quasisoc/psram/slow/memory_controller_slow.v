/**
 * File              : memory_controller.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.12.01
 * Last Modified Date: 2021.01.30
 */
// Memory controller

`timescale 1ns / 1ps

module memory_controller
	(
		input rst, 
		input clk, 

		input [21:0]a, 
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

	reg [31:0]regspo;
	wire [31:0]data = d;
	assign spo = regspo;
	//wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};
	//assign spo = {regspo[7:0], regspo[15:8], regspo[23:16], regspo[31:24]};

	reg ready_r = 0;
	assign ready = ready_r & !(rd | we);

	reg [21:0]rega;
	reg [7:0]regbuf[3:0];

	reg [5:0]count;

	reg m_rd; 
	reg m_rend; 
	reg m_we; 
	reg m_wend; 
	wire [23:0]m_a = {rega, 2'b0};
	wire [7:0]m_dout; 
	wire m_byte_available;
	wire [7:0]m_din = regbuf[count];
	wire m_ready_for_next_byte;
	wire m_ready;

    // slow clock
    reg [4:0]clkcounter = 0;
    always @ (posedge clk) begin
        if (rst) clkcounter <= 5'b0;
        else clkcounter <= clkcounter + 1;
    end
    wire clk_pulse_slow = (clkcounter[1:0] == 2'b0);

	psram_controller psram_controller_inst
	(
		.rst(rst), 
		.clk(clk), 
		.clk_pulse_slow(clk_pulse_slow),

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
    always @ (posedge clk) begin
		m_byte_available_old <= m_byte_available;
		m_ready_for_next_byte_old <= m_ready_for_next_byte;
    end
    wire byte_available_posedge = !m_byte_available_old & m_byte_available;
    wire ready_for_next_byte_posedge = !m_ready_for_next_byte_old & m_ready_for_next_byte;

	localparam	IDLE		=	0;
	localparam	WE_BEGIN	=	5;
	localparam	WE			=	10;
	localparam	RD_BEGIN	=	15;
	localparam	RD			=	20;
	reg [5:0]state;


	always @ (posedge clk) begin
		if (rst) begin
			m_rd <= 0; 
			m_rend <= 0;
			m_we <= 0;
			m_wend <= 0;
			state <= IDLE;
			ready_r <= m_ready;
		end else begin
			case (state)
				// go IDLE right after reset, but first memory operation will
				// hang until the psram is ready
				IDLE: begin
					if (we) begin
						state <= WE_BEGIN;
						ready_r <= 0;
					end else if (rd) begin
						state <= RD_BEGIN;
						ready_r <= 0;
					end else ready_r <= m_ready;
					rega <= a[21:0];
					regbuf[3] <= data[31:24];
					regbuf[2] <= data[23:16];
					regbuf[1] <= data[15:8];
					regbuf[0] <= data[7:0];
					m_wend <= 0;
					m_rend <= 0;
					count <= 4;
				end
				WE_BEGIN: begin
					if (m_ready) begin
						m_we <= 1;
						state <= WE;
					end
				end
				WE: begin
					m_we <= 0;
					if (ready_for_next_byte_posedge) count <= count - 1;
					if (count == 6'b111111) begin
						state <= IDLE;
						m_wend <= 1;
					end
				end
				RD_BEGIN: begin
					if (m_ready) begin
						m_rd <= 1;
						state <= RD;
					end
				end
				RD: begin
					m_rd <= 0;
					if (byte_available_posedge) begin
						count <= count - 1;
						regbuf[count - 1] <= m_dout;
					end
					if (count == 6'b000000) begin
						regspo <= {regbuf[3], regbuf[2], regbuf[1], regbuf[0]};
						state <= IDLE;
						m_rend <= 1;
					end
				end
			endcase
		end
	end
endmodule
