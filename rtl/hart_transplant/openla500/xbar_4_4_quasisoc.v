module xbar_4_4_quasisoc (
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_clk, ASSOCIATED_BUSIF s_axi_0:s_axi_1:s_axi_2:s_axi_3:m_axi_0:m_axi_1, ASSOCIATED_RESET s_axi_aresetn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_clk CLK" *)
    input wire S_AXI_ACLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    input wire S_AXI_ARESETN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 AWVALID" *)
    output wire M_AXI_0_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 AWREADY" *)
    input wire M_AXI_0_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 AWADDR" *)
    output wire [32-1:0] M_AXI_0_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 AWPROT" *)
    output wire [2:0] M_AXI_0_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 WVALID" *)
    output wire M_AXI_0_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 WREADY" *)
    input wire M_AXI_0_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 WDATA" *)
    output wire [32-1:0] M_AXI_0_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 WSTRB" *)
    output wire [4-1:0] M_AXI_0_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 BVALID" *)
    input wire M_AXI_0_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 BREADY" *)
    output wire M_AXI_0_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 BRESP" *)
    input wire [1:0] M_AXI_0_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 ARVALID" *)
    output wire M_AXI_0_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 ARREADY" *)
    input wire M_AXI_0_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 ARADDR" *)
    output wire [32-1:0] M_AXI_0_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 ARPROT" *)
    output wire [2:0] M_AXI_0_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 RVALID" *)
    input wire M_AXI_0_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 RREADY" *)
    output wire M_AXI_0_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 RRESP" *)
    input wire [1:0] M_AXI_0_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_0 RDATA" *)
    input wire [32-1:0] M_AXI_0_RDATA,
    
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 AWVALID" *)
    output wire M_AXI_1_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 AWREADY" *)
    input wire M_AXI_1_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 AWADDR" *)
    output wire [32-1:0] M_AXI_1_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 AWPROT" *)
    output wire [2:0] M_AXI_1_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 WVALID" *)
    output wire M_AXI_1_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 WREADY" *)
    input wire M_AXI_1_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 WDATA" *)
    output wire [32-1:0] M_AXI_1_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 WSTRB" *)
    output wire [4-1:0] M_AXI_1_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 BVALID" *)
    input wire M_AXI_1_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 BREADY" *)
    output wire M_AXI_1_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 BRESP" *)
    input wire [1:0] M_AXI_1_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 ARVALID" *)
    output wire M_AXI_1_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 ARREADY" *)
    input wire M_AXI_1_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 ARADDR" *)
    output wire [32-1:0] M_AXI_1_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 ARPROT" *)
    output wire [2:0] M_AXI_1_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 RVALID" *)
    input wire M_AXI_1_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 RREADY" *)
    output wire M_AXI_1_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 RRESP" *)
    input wire [1:0] M_AXI_1_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_1 RDATA" *)
    input wire [32-1:0] M_AXI_1_RDATA,
    
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 AWVALID" *)
    input wire S_AXI_0_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 AWREADY" *)
    output wire S_AXI_0_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 AWADDR" *)
    input wire [32-1:0] S_AXI_0_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 AWPROT" *)
    input wire [2:0] S_AXI_0_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 WVALID" *)
    input wire S_AXI_0_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 WREADY" *)
    output wire S_AXI_0_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 WDATA" *)
    input wire [32-1:0] S_AXI_0_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 WSTRB" *)
    input wire [4-1:0] S_AXI_0_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 BVALID" *)
    output wire S_AXI_0_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 BREADY" *)
    input wire S_AXI_0_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 BRESP" *)
    output wire [1:0] S_AXI_0_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 ARVALID" *)
    input wire S_AXI_0_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 ARREADY" *)
    output wire S_AXI_0_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 ARADDR" *)
    input wire [32-1:0] S_AXI_0_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 ARPROT" *)
    input wire [2:0] S_AXI_0_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 RVALID" *)
    output wire S_AXI_0_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 RREADY" *)
    input wire S_AXI_0_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 RRESP" *)
    output wire [1:0] S_AXI_0_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_0 RDATA" *)
    output wire [32-1:0] S_AXI_0_RDATA
    ,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 AWVALID" *)
    input wire S_AXI_1_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 AWREADY" *)
    output wire S_AXI_1_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 AWADDR" *)
    input wire [32-1:0] S_AXI_1_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 AWPROT" *)
    input wire [2:0] S_AXI_1_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 WVALID" *)
    input wire S_AXI_1_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 WREADY" *)
    output wire S_AXI_1_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 WDATA" *)
    input wire [32-1:0] S_AXI_1_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 WSTRB" *)
    input wire [4-1:0] S_AXI_1_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 BVALID" *)
    output wire S_AXI_1_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 BREADY" *)
    input wire S_AXI_1_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 BRESP" *)
    output wire [1:0] S_AXI_1_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 ARVALID" *)
    input wire S_AXI_1_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 ARREADY" *)
    output wire S_AXI_1_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 ARADDR" *)
    input wire [32-1:0] S_AXI_1_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 ARPROT" *)
    input wire [2:0] S_AXI_1_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 RVALID" *)
    output wire S_AXI_1_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 RREADY" *)
    input wire S_AXI_1_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 RRESP" *)
    output wire [1:0] S_AXI_1_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_1 RDATA" *)
    output wire [32-1:0] S_AXI_1_RDATA
    ,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 AWVALID" *)
    input wire S_AXI_2_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 AWREADY" *)
    output wire S_AXI_2_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 AWADDR" *)
    input wire [32-1:0] S_AXI_2_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 AWPROT" *)
    input wire [2:0] S_AXI_2_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 WVALID" *)
    input wire S_AXI_2_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 WREADY" *)
    output wire S_AXI_2_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 WDATA" *)
    input wire [32-1:0] S_AXI_2_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 WSTRB" *)
    input wire [4-1:0] S_AXI_2_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 BVALID" *)
    output wire S_AXI_2_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 BREADY" *)
    input wire S_AXI_2_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 BRESP" *)
    output wire [1:0] S_AXI_2_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 ARVALID" *)
    input wire S_AXI_2_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 ARREADY" *)
    output wire S_AXI_2_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 ARADDR" *)
    input wire [32-1:0] S_AXI_2_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 ARPROT" *)
    input wire [2:0] S_AXI_2_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 RVALID" *)
    output wire S_AXI_2_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 RREADY" *)
    input wire S_AXI_2_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 RRESP" *)
    output wire [1:0] S_AXI_2_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_2 RDATA" *)
    output wire [32-1:0] S_AXI_2_RDATA
    ,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 AWVALID" *)
    input wire S_AXI_3_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 AWREADY" *)
    output wire S_AXI_3_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 AWADDR" *)
    input wire [32-1:0] S_AXI_3_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 AWPROT" *)
    input wire [2:0] S_AXI_3_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 WVALID" *)
    input wire S_AXI_3_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 WREADY" *)
    output wire S_AXI_3_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 WDATA" *)
    input wire [32-1:0] S_AXI_3_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 WSTRB" *)
    input wire [4-1:0] S_AXI_3_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 BVALID" *)
    output wire S_AXI_3_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 BREADY" *)
    input wire S_AXI_3_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 BRESP" *)
    output wire [1:0] S_AXI_3_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 ARVALID" *)
    input wire S_AXI_3_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 ARREADY" *)
    output wire S_AXI_3_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 ARADDR" *)
    input wire [32-1:0] S_AXI_3_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 ARPROT" *)
    input wire [2:0] S_AXI_3_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 RVALID" *)
    output wire S_AXI_3_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 RREADY" *)
    input wire S_AXI_3_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 RRESP" *)
    output wire [1:0] S_AXI_3_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_3 RDATA" *)
    output wire [32-1:0] S_AXI_3_RDATA
    );
    axilxbar #(
    .C_AXI_DATA_WIDTH(32),
    .C_AXI_ADDR_WIDTH(32),
    .NM(4),
    .NS(2),
    .SLAVE_ADDR({32'h10000000, 32'h00000000}),
    .SLAVE_MASK({32'h30000000, 32'hf0000000})
    ) axilxbar_inst (
    .S_AXI_AWVALID({S_AXI_3_AWVALID,S_AXI_2_AWVALID,S_AXI_1_AWVALID,S_AXI_0_AWVALID}),
.S_AXI_AWREADY({S_AXI_3_AWREADY,S_AXI_2_AWREADY,S_AXI_1_AWREADY,S_AXI_0_AWREADY}),
.S_AXI_AWADDR({S_AXI_3_AWADDR,S_AXI_2_AWADDR,S_AXI_1_AWADDR,S_AXI_0_AWADDR}),
.S_AXI_AWPROT({S_AXI_3_AWPROT,S_AXI_2_AWPROT,S_AXI_1_AWPROT,S_AXI_0_AWPROT}),
.S_AXI_WVALID({S_AXI_3_WVALID,S_AXI_2_WVALID,S_AXI_1_WVALID,S_AXI_0_WVALID}),
.S_AXI_WREADY({S_AXI_3_WREADY,S_AXI_2_WREADY,S_AXI_1_WREADY,S_AXI_0_WREADY}),
.S_AXI_WDATA({S_AXI_3_WDATA,S_AXI_2_WDATA,S_AXI_1_WDATA,S_AXI_0_WDATA}),
.S_AXI_WSTRB({S_AXI_3_WSTRB,S_AXI_2_WSTRB,S_AXI_1_WSTRB,S_AXI_0_WSTRB}),
.S_AXI_BVALID({S_AXI_3_BVALID,S_AXI_2_BVALID,S_AXI_1_BVALID,S_AXI_0_BVALID}),
.S_AXI_BREADY({S_AXI_3_BREADY,S_AXI_2_BREADY,S_AXI_1_BREADY,S_AXI_0_BREADY}),
.S_AXI_BRESP({S_AXI_3_BRESP,S_AXI_2_BRESP,S_AXI_1_BRESP,S_AXI_0_BRESP}),
.S_AXI_ARVALID({S_AXI_3_ARVALID,S_AXI_2_ARVALID,S_AXI_1_ARVALID,S_AXI_0_ARVALID}),
.S_AXI_ARREADY({S_AXI_3_ARREADY,S_AXI_2_ARREADY,S_AXI_1_ARREADY,S_AXI_0_ARREADY}),
.S_AXI_ARADDR({S_AXI_3_ARADDR,S_AXI_2_ARADDR,S_AXI_1_ARADDR,S_AXI_0_ARADDR}),
.S_AXI_ARPROT({S_AXI_3_ARPROT,S_AXI_2_ARPROT,S_AXI_1_ARPROT,S_AXI_0_ARPROT}),
.S_AXI_RVALID({S_AXI_3_RVALID,S_AXI_2_RVALID,S_AXI_1_RVALID,S_AXI_0_RVALID}),
.S_AXI_RREADY({S_AXI_3_RREADY,S_AXI_2_RREADY,S_AXI_1_RREADY,S_AXI_0_RREADY}),
.S_AXI_RDATA({S_AXI_3_RDATA,S_AXI_2_RDATA,S_AXI_1_RDATA,S_AXI_0_RDATA}),
.S_AXI_RRESP({S_AXI_3_RRESP,S_AXI_2_RRESP,S_AXI_1_RRESP,S_AXI_0_RRESP}),
.M_AXI_AWVALID({M_AXI_1_AWVALID,M_AXI_0_AWVALID}),
.M_AXI_AWREADY({M_AXI_1_AWREADY,M_AXI_0_AWREADY}),
.M_AXI_AWADDR({M_AXI_1_AWADDR,M_AXI_0_AWADDR}),
.M_AXI_AWPROT({M_AXI_1_AWPROT,M_AXI_0_AWPROT}),
.M_AXI_WVALID({M_AXI_1_WVALID,M_AXI_0_WVALID}),
.M_AXI_WREADY({M_AXI_1_WREADY,M_AXI_0_WREADY}),
.M_AXI_WDATA({M_AXI_1_WDATA,M_AXI_0_WDATA}),
.M_AXI_WSTRB({M_AXI_1_WSTRB,M_AXI_0_WSTRB}),
.M_AXI_BVALID({M_AXI_1_BVALID,M_AXI_0_BVALID}),
.M_AXI_BREADY({M_AXI_1_BREADY,M_AXI_0_BREADY}),
.M_AXI_BRESP({M_AXI_1_BRESP,M_AXI_0_BRESP}),
.M_AXI_ARVALID({M_AXI_1_ARVALID,M_AXI_0_ARVALID}),
.M_AXI_ARREADY({M_AXI_1_ARREADY,M_AXI_0_ARREADY}),
.M_AXI_ARADDR({M_AXI_1_ARADDR,M_AXI_0_ARADDR}),
.M_AXI_ARPROT({M_AXI_1_ARPROT,M_AXI_0_ARPROT}),
.M_AXI_RVALID({M_AXI_1_RVALID,M_AXI_0_RVALID}),
.M_AXI_RREADY({M_AXI_1_RREADY,M_AXI_0_RREADY}),
.M_AXI_RDATA({M_AXI_1_RDATA,M_AXI_0_RDATA}),
.M_AXI_RRESP({M_AXI_1_RRESP,M_AXI_0_RRESP}),

    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN)
    );
    endmodule
    
