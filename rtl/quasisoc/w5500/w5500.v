/**
 * File              : w5500.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.07.24
 * Last Modified Date: 2021.07.24
 */

`timescale 1ns / 1ps
//`define SIMULATION
// w5500 hardware tcpip ethernet module
// SPI host here, FDM mode(fixed data length)

module w5500_fdm
	(
		input clk, 
		input rst,

		input [31:0]a,
		input [31:0]d,
		input we,
		output [31:0]spo,

		input intn,
		output rstn,
		output sclk, 
		output scsn, 
		output mosi, 
		input miso,

		output reg irq = 0
	);

	wire [31:0]data = {d[7:0], d[15:8], d[23:16], d[31:24]};
	reg [31:0]regspo;
	assign spo = regspo;

	reg sclk_reg = 0;
	reg rstn_reg = 0;
	assign scsn = 0; // FDM mode
	assign rstn = rstn_reg;
	assign sclk = sclk_reg;
	//assign mosi = 0;
	
	reg [2:0]fdm_len; // 1, 2, 4 bytes
	// SPI payload: 16bit addr, 8bit control, 8xNbit data, MSB first
	reg [15:0]spi_addr;
	reg [7:0]spi_ctrl; // block select(5), R/W(1), OP mode(2)
	reg [31:0]spi_data; // [31:24] for byte 1, ..., [7:0] for byte 4

	always @ (posedge clk) begin
		if (we) begin case (a[4:2])
			3'b000: spi_addr <= data[15:0];
			3'b001: spi_ctrl <= data[7:0];
			3'b010: spi_data <= d; // data inverted here!
			3'b011: fdm_len <= data[2:0];
			3'b100: ; // begin writing
			default: ;
		endcase end
	end
	reg [31:0]spo_reg;
	assign spo = spo_reg;
	always @ (*) begin
		spo_reg = 0;
		case (a[4:2])
			3'b101: spo_reg = {7'b0, (state == IDLE), 24'b0};
			3'b110: spo_reg = {recvbits[7:0], recvbits[15:8], recvbits[23:16], recvbits[31:24]};
			3'b111: spo_reg = {7'b0, intn, 24'b0};
			default: spo_reg = 0;
		endcase
	end

	localparam INIT = 0;
	localparam RST= 1;
	localparam IDLE = 2;
	localparam XFER = 3;
	reg [3:0]state = RST;

	//localparam BOOT_COUNTER_RST = 400;
	//localparam BOOT_COUNTER = 800;
	localparam BOOT_COUNTER_RST = 40000;
	localparam BOOT_COUNTER = 80000;
	reg [19:0]boot_counter;

	reg [7:0]sendcnt_max;
	reg [7:0]sendcnt;
	wire [55:0]sendbits = {spi_addr, spi_ctrl, spi_data};
	reg [31:0]recvbits;

	assign mosi = sendbits[55 - sendcnt];

    always @(posedge clk) begin
		if(rst) begin // >500us reset, >1ms wait after reset
			sclk_reg <= 0;
			boot_counter <= BOOT_COUNTER_RST;
			state <= RST;
			rstn_reg <= 0;
        end
        else case(state)
				RST: begin
					if (boot_counter == 0) begin
						state <= INIT;
						boot_counter <= BOOT_COUNTER;
						rstn_reg <= 1;
					end else boot_counter <= boot_counter - 1;
				end
                INIT: begin
                    if(boot_counter == 0) state <= IDLE;
                    else boot_counter <= boot_counter - 1;
                end
                IDLE: begin
					sclk_reg <= 0;
					if (we & a[4:2] == 3'b100) begin
						state <= XFER;
						sendcnt_max <= 16 + 8 + {2'b0, fdm_len, 3'b0};
						sendcnt <= 0;
						recvbits <= 0;
					end
                end
				XFER: begin
					// sendcnt should be ready
					// sclk should be zero
					if (sendcnt < sendcnt_max)
						sclk_reg <= ~sclk_reg;
					if (sclk_reg) begin
						if (sendcnt == sendcnt_max - 1)
							state <= IDLE;
						// send data, don't care if it's a read
						sendcnt <= sendcnt + 1;
					end else if (sendcnt >= 16 + 8) begin
						// recv data, odn't care if writing
						recvbits <= {recvbits[30:0], miso};
					end
				end
		endcase
    end
endmodule
