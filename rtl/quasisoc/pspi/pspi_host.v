/**
 * File              : pspi_host.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2020.11.25
 * Last Modified Date: 2024.04.13
 */
`timescale 1ns / 1ps
// A simple spi-like interface for mid-speed data transfer
// Used in FPGAOL for "persistent storage" emulation
// 
// guests detect sck posedge, so shift out data on negedge

module pspi_host #(
	parameter PSPI_WIDTH = 8
)(
        input clk,
        input rst,
        input [31:0]a,
        input [31:0]d,
        input we,
		input rd,
        output [31:0]spo,
		output ready,

		output reg sck,
		output reg [PSPI_WIDTH-1:0]mosi,
		input [PSPI_WIDTH-1:0]miso
    );

	(* mark_debug = "true" *) reg [31:0]pspo;
	assign spo = {pspo[7:0], pspo[15:8], pspo[23:16], pspo[31:24]};
	(* mark_debug = "true" *) reg [31:0]pd;
	(* mark_debug = "true" *) reg [31:0]pa; // depend on ZYNQ AXI address
	reg pwe;
	reg [5:0]shiftcnt;
	reg [7:0]rstcnt;

	reg [PSPI_WIDTH-1:0]miso_r;
	always @ (posedge clk) begin
		miso_r <= miso;
	end

    reg [4:0]clkcounter = 0;
    always @ (posedge clk) begin
        clkcounter <= clkcounter + 1;
    end
    wire clk_pulse_slow = (clkcounter[2:0] == 0); // ~8 MHz would be OK

	(* mark_debug = "true" *) reg [3:0]pstate;
	localparam RST = 0;
	localparam IDLE = 1;
	localparam STARTSIGN = 2;
	localparam RDWR = 3;
	localparam ADDR = 4;
	localparam WDATA = 5;
	localparam WAIT = 6;
	localparam RDATA = 7;

	localparam CNT_MAX = 32 / PSPI_WIDTH - 1;

	assign ready = !(rd | we) & pstate == IDLE;

    always @ (posedge clk) begin
		// do not send sck when idle, it'll reset the bus
		if (clk_pulse_slow) sck <= pstate == IDLE ? 1'b1 : ~sck;
        if (rst) begin
			mosi <= 32'hFFFFFFFF;
			pstate <= RST;
			rstcnt <= 0;
		end else begin
			case (pstate)
				RST: begin // reset bus by >~256 sck with mosi[0] high
					rstcnt <= rstcnt + 1;
					if (rstcnt == 8'hFF) pstate <= IDLE;
				end
				IDLE: begin
					mosi <= 32'hFFFFFFFF;
					if (rd | we) begin
						pwe <= we;
						pd <= {d[7:0], d[15:8], d[23:16], d[31:24]};
						pa <= {8'b01, a[23:0]};
						pstate <= STARTSIGN;
					end
				end
				STARTSIGN: begin
					if (clk_pulse_slow) begin
						if (sck) begin
							mosi <= 32'hFFFFFFFE;
							pstate <= RDWR;
						end
					end
				end
				RDWR: begin
					if (clk_pulse_slow) begin
						if (sck) begin
							mosi <= {{31{1'b1}}, pwe ? 1'b1 : 1'b0};
							pstate <= ADDR;
							shiftcnt <= CNT_MAX;
						end
					end
				end
				ADDR: begin
					if (clk_pulse_slow) begin
						if (sck) begin
							shiftcnt <= shiftcnt - 1;
							pa <= {pa[31-PSPI_WIDTH:0], {PSPI_WIDTH{1'b0}}};
							mosi <= pa[31:32-PSPI_WIDTH];
							if (shiftcnt == 0) begin
								shiftcnt <= CNT_MAX;
								pstate <= pwe ? WDATA : WAIT;
							end
						end
					end
				end
				WDATA: begin
					if (clk_pulse_slow) begin
						if (sck) begin
							shiftcnt <= shiftcnt - 1;
							pd <= {pd[31-PSPI_WIDTH:0], {PSPI_WIDTH{1'b0}}};
							mosi <= pd[31:32-PSPI_WIDTH];
							if (shiftcnt == 0) begin
								pstate <= WAIT;
							end
						end
					end
				end
				WAIT: begin
					if (clk_pulse_slow) begin
						if (sck) begin
							shiftcnt <= CNT_MAX;
							mosi <= 32'hFFFFFFFF;
							if (!miso_r[0]) pstate <= pwe ? IDLE : RDATA;
						end
					end
				end
				RDATA: begin
					if (clk_pulse_slow) begin
						if (!sck) begin // only here is read, so shift at posedge
							pspo <= {pspo[31-PSPI_WIDTH:0], miso_r};
							shiftcnt <= shiftcnt - 1;
							if (shiftcnt == 0) begin
								pstate <= IDLE;
							end
						end
					end
				end
			endcase
		end
    end

endmodule
