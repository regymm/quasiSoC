/**
 * File              : mm2axi4.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2022.05.20
 * Last Modified Date: 2022.05.20
 */
`timescale 1ns / 1ps
// pCPU memory address mapper (or "bus")

module mm2axi4
	#(
		parameter AXI4_IDLEN = 12,
		parameter AXI4_ADDRLEN = 32,
		parameter AXI4_DATALEN = 32
	)
    (
		input clk,
		input rst,

		// CPU bus is fixed 32-bit
        input [31:0]a,
        input [31:0]d,
        input we,
        input rd,
        output reg [31:0]spo,
        output ready,

		output [AXI4_IDLEN-1:0]m_axi_awid,
		output reg [AXI4_ADDRLEN-1:0]m_axi_awaddr,
		output [7:0]m_axi_awlen,
		output [2:0]m_axi_awsize,
		output [1:0]m_axi_awburst,
		output [1:0]m_axi_awlock,
		output [3:0]m_axi_awcache,
		output [2:0]m_axi_awprot,
		output [3:0]m_axi_awqos,
		output reg m_axi_awvalid,
		input m_axi_awready,

		output [AXI4_IDLEN-1:0]m_axi_wid,
		output reg [AXI4_DATALEN-1:0]m_axi_wdata,
		output [3:0]m_axi_wstrb,
		output reg m_axi_wlast,
		output reg m_axi_wvalid,
		input m_axi_wready,

		input [AXI4_IDLEN-1:0]m_axi_bid,
		output reg m_axi_bready,
		input [1:0]m_axi_bresp,
		input m_axi_bvalid,

		output [AXI4_IDLEN-1:0]m_axi_arid,
		output reg [AXI4_ADDRLEN-1:0]m_axi_araddr,
		output [7:0]m_axi_arlen,
		output [2:0]m_axi_arsize,
		output [1:0]m_axi_arburst,
		output [1:0]m_axi_arlock,
		output [3:0]m_axi_arcache,
		output [2:0]m_axi_arprot,
		output [3:0]m_axi_arqos,
		output reg m_axi_arvalid,
		input m_axi_arready,

		output reg m_axi_rready,
		input [AXI4_IDLEN-1:0]m_axi_rid,
		input [AXI4_DATALEN-1:0]m_axi_rdata,
		input [1:0]m_axi_rresp,
		input m_axi_rlast,
		input m_axi_rvalid,

        output reg irq = 0
    );
	
	// TODO: check if work in >64 bit axi...

	// WRITE
	assign m_axi_awid = 0;
	assign m_axi_awlen = 8'b0;
	assign m_axi_awsize = 3'b010;
	assign m_axi_awburst = 2'b01;
	assign m_axi_awlock = 0;
	assign m_axi_awcache = 4'b0011;
	assign m_axi_awprot = 3'b000;
	assign m_axi_awqos = 0;

	assign m_axi_wid = 0;
	assign m_axi_wstrb = 4'b1111;

	// READ 
	//// signal that matters: 
	////  araddr, rdata
	assign m_axi_arid = 0;
	assign m_axi_arlen = 8'b0;
	assign m_axi_arsize = 3'b010; // 32-bit
	assign m_axi_arburst = 2'b01; // INCR, doesn't matter
	assign m_axi_arlock = 0;
	assign m_axi_arcache = 4'b0011;
	assign m_axi_arprot = 3'b000;
	assign m_axi_arqos = 0;


    //always @ (*) begin 
		//m_axi_arvalid = 0;
		//if (state == RDBEGIN) begin
			//m_axi_arvalid = 1;
		//end
    //end

	localparam IDLE = 0;
	localparam RDBEGIN = 1;
	localparam WEBEGIN = 2;
	reg [3:0]state = IDLE;

    always @ (posedge clk) begin
		if (rst) begin
			state <= IDLE;
			m_axi_awvalid <= 0;
			m_axi_wvalid <= 0;
			m_axi_bready <= 0;
			m_axi_arvalid <= 0;
			m_axi_rready <= 0;
		end else if (state == IDLE) begin
			if (rd) begin
				state <= RDBEGIN;
				m_axi_araddr <= a;
				m_axi_arvalid <= 1;
				m_axi_rready <= 1;
			end else if (we) begin
				state <= WEBEGIN;
				m_axi_awaddr <= a;
				m_axi_wdata <= d;
				m_axi_awvalid <= 1;
				m_axi_wvalid <= 1;
				m_axi_wlast <= 1;
				m_axi_bready <= 1;
			end
		end else if (state == RDBEGIN) begin
			if (m_axi_arready) begin
				m_axi_arvalid <= 0;
			end
			if (m_axi_rvalid) begin
				spo <= m_axi_rdata;
				m_axi_rready <= 0;
				state <= IDLE;
				// m_axi_rlast should be 1
			end
		end else if (state == WEBEGIN) begin
			if (m_axi_awready) begin
				m_axi_awvalid <= 0;
			end
			if (m_axi_wready) begin
				m_axi_wvalid <= 0;
				m_axi_wlast <= 0;
			end
			if (m_axi_bvalid) begin
				m_axi_bready <= 0;
				state <= IDLE;
			end
		end
    end

	assign ready = state == IDLE & !(we | rd);
endmodule
