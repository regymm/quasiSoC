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

        input [31:0]a,
        input [31:0]d,
        input we,
        input rd,
        output reg [31:0]spo,
        output reg ready,

		output [AXI4_IDLEN-1:0]m_axi_awid,
		output [AXI4_ADDRLEN-1:0]m_axi_awaddr,
		output [7:0]m_axi_awlen,
		output [2:0]m_axi_awsize,
		output [1:0]m_axi_awburst,
		output [1:0]m_axi_awlock,
		output [3:0]m_axi_awcache,
		output [2:0]m_axi_awprot,
		output [3:0]m_axi_awqos,
		output m_axi_awvalid,
		input m_axi_awready,

		output [AXI4_IDLEN-1:0]m_axi_wid,
		output [AXI4_DATALEN-1:0]m_axi_wdata,
		output [3:0]m_axi_wstrb,
		output m_axi_wlast,
		output m_axi_wvalid,
		input m_axi_wready,

		output [AXI4_IDLEN-1:0]m_axi_bid,
		input m_axi_bready,
		input [1:0]m_axi_bresp,
		input m_axi_bvalid,

		output [AXI4_IDLEN-1:0]m_axi_arid,
		output [AXI4_ADDRLEN-1:0]m_axi_araddr,
		output [7:0]m_axi_arlen,
		output [2:0]m_axi_arsize,
		output [1:0]m_axi_arburst,
		output [1:0]m_axi_arlock,
		output [3:0]m_axi_arcache,
		output [2:0]m_axi_arprot,
		output [3:0]m_axi_arqos,
		output m_axi_arvalid,
		input m_axi_arready,

		output m_axi_rready,
		input [AXI4_IDLEN-1:0]m_axi_rid,
		input [AXI4_DATALEN-1:0]m_axi_rdata,
		input [1:0]m_axi_rresp,
		input m_axi_rlast,
		input m_axi_rvalid,

        output reg irq
    );

    always @ (*) begin 
    end

    always @ (posedge clk) begin
    end
endmodule
