// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm
// Bridge AXI Lite to a block ram like interface
module axil2mm (
    input wire        s_axi_clk,
    input wire        s_axi_aresetn,
    // AXI Lite Write Address Channel
    (*mark_debug = "true"*)input wire [31:0] s_axi_awaddr,
    (*mark_debug = "true"*)input wire        s_axi_awvalid,
    (*mark_debug = "true"*)output wire       s_axi_awready,
    // AXI Lite Write Data Channel
    (*mark_debug = "true"*)input wire [31:0] s_axi_wdata,
    (*mark_debug = "true"*)input wire [3:0]  s_axi_wstrb,
    (*mark_debug = "true"*)input wire        s_axi_wvalid,
    (*mark_debug = "true"*)output reg        s_axi_wready,
    // AXI Lite Write Response
    (*mark_debug = "true"*)output reg [1:0]  s_axi_bresp,
    (*mark_debug = "true"*)output reg        s_axi_bvalid,
    (*mark_debug = "true"*)input wire        s_axi_bready,
    // AXI Lite Read Address Channel
    (*mark_debug = "true"*)input wire [31:0] s_axi_araddr,
    (*mark_debug = "true"*)input wire        s_axi_arvalid,
    (*mark_debug = "true"*)output wire       s_axi_arready,
    // AXI Lite Read Data Channel
    (*mark_debug = "true"*)output reg [31:0] s_axi_rdata,
    (*mark_debug = "true"*)output reg        s_axi_rvalid,
    (*mark_debug = "true"*)input wire        s_axi_rready,
    (*mark_debug = "true"*)output reg [1:0]  s_axi_rresp,
    // BRAM-like interface
    output reg [31:0] a,
    output reg [31:0] d,
    output reg        rd,
    output reg [3:0]  web,
    input wire [31:0] spo,
    input wire        ready,
    output wire       req,
    input wire        gnt,
    input wire        hrd
);
    assign req = 1;
    localparam IDLE = 2'b00;
    localparam WAIT_DATA = 2'b01;
    localparam WAIT_READY = 2'b10;
    localparam RESPOND = 2'b11;
    reg [1:0]write_state;
    reg [1:0]read_state;
    always @(posedge s_axi_clk) begin
        if (!s_axi_aresetn) begin
            // Write
            // s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 2'b00;
            web           <= 4'b0;
            a             <= 32'b0;
            d             <= 32'b0;
            write_state   <= IDLE;
            // Read
            // s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rdata   <= 32'b0;
            s_axi_rresp   <= 2'b00;
            rd            <= 0;
            read_state    <= IDLE;
        end else begin
            // Write FSM, prioritize write
            case (write_state)
                IDLE: begin
                    if (read_state == IDLE && s_axi_awvalid /*&& s_axi_wvalid*/) begin
                        // s_axi_awready <= 1;
                        s_axi_wready  <= 1;
                        // Latch write address and data
                        a <= s_axi_awaddr;
                        // d <= s_axi_wdata;
                        // web <= s_axi_wstrb;
                        write_state <= WAIT_DATA;
                    end
                end
                WAIT_DATA: begin
                    if (s_axi_wvalid) begin
                        d <= s_axi_wdata;
                        web <= s_axi_wstrb;
                        write_state <= WAIT_READY;
                        s_axi_wready  <= 0;
                    end
                end
                WAIT_READY: begin
                    // s_axi_awready <= 0;
                    web <= 4'b0;
                    if (ready) begin
                        s_axi_bvalid <= 1;
                        s_axi_bresp  <= 2'b00; // OKAY
                        write_state  <= RESPOND;
                    end
                end
                RESPOND: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 0;
                        write_state <= IDLE;
                    end
                end
            endcase
            // Read FSM
            case (read_state)
                IDLE: begin
                    if (write_state == IDLE && !(s_axi_awvalid) && s_axi_arvalid) begin
                        // s_axi_arready <= 1;
                        a <= s_axi_araddr;
                        rd <= 1;
                        read_state <= WAIT_READY;
                    end
                end
                WAIT_READY: begin
                    // s_axi_arready <= 0;
                    rd <= 0;
                    if (ready) begin
                        s_axi_rdata <= spo;
                        s_axi_rvalid <= 1;
                        s_axi_rresp  <= 2'b00; // OKAY
                        read_state <= RESPOND;
                    end
                end
                RESPOND: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 0;
                        read_state <= IDLE;
                    end
                end
            endcase
        end
    end
    assign s_axi_awready = write_state == IDLE && read_state == IDLE && s_axi_awvalid;
    assign s_axi_arready = read_state == IDLE && write_state == IDLE && !(s_axi_awvalid) && s_axi_arvalid;
endmodule
