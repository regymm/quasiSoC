//+FHDR-----------------------------------------------------------------
// (C) Copyright Loongson Technology Corporation Limited. All rights reserved
// Loongson Confidential Proprietary
//-FHDR-----------------------------------------------------------------
module soc_axi_sram_bridge#(
    parameter   BUS_WIDTH  = 32,
    parameter   DATA_WIDTH = 64, 
    parameter   CPU_WIDTH  = 32
)
(
    input  wire                     aclk     ,
    input  wire                     aresetn  ,
    output wire [BUS_WIDTH-1    :0] ram_raddr,
    input  wire [DATA_WIDTH-1   :0] ram_rdata,
    output wire                     ram_ren  ,
    output wire [BUS_WIDTH-1    :0] ram_waddr,
    output wire [DATA_WIDTH-1   :0] ram_wdata,
    output wire [DATA_WIDTH/8-1 :0] ram_wen  ,
    input  wire [BUS_WIDTH-1    :0] m_araddr ,
    input  wire [1              :0] m_arburst,
    input  wire [3              :0] m_arcache,
    input  wire [3              :0] m_arid   ,
    input  wire [3              :0] m_arlen  ,
    input  wire [1              :0] m_arlock ,
    input  wire [2              :0] m_arprot ,
    output wire                     m_arready,
    input  wire [2              :0] m_arsize ,
    input  wire                     m_arvalid,
    input  wire [BUS_WIDTH-1    :0] m_awaddr ,
    input  wire [1              :0] m_awburst,
    input  wire [3              :0] m_awcache,
    input  wire [3              :0] m_awid   ,
    input  wire [3              :0] m_awlen  ,
    input  wire [1              :0] m_awlock ,
    input  wire [2              :0] m_awprot ,
    output wire                     m_awready,
    input  wire [2              :0] m_awsize ,
    input  wire                     m_awvalid,
    output wire [3              :0] m_bid    ,
    input  wire                     m_bready ,
    output wire [1              :0] m_bresp  ,
    output wire                     m_bvalid ,
    output wire [DATA_WIDTH-1   :0] m_rdata  ,
    output wire [3              :0] m_rid    ,
    output wire                     m_rlast  ,
    input  wire                     m_rready ,
    output wire [1              :0] m_rresp  ,
    output wire                     m_rvalid ,
    input  wire [DATA_WIDTH-1   :0] m_wdata  ,
    input  wire [3              :0] m_wid    ,
    input  wire                     m_wlast  ,
    output wire                     m_wready ,
    input  wire [DATA_WIDTH/8-1 :0] m_wstrb  ,
    input  wire                     m_wvalid 
);
localparam ADDR_INCR_BASE=($clog2(DATA_WIDTH) - 3);

wire [BUS_WIDTH+13-1    :0] ram_r_a_data               ;
reg  [BUS_WIDTH-1       :0] ram_r_a_data_araddr        ;
wire [BUS_WIDTH-1       :0] ram_r_a_data_araddr_fixed  ;
wire [BUS_WIDTH-1       :0] ram_r_a_data_araddr_incr   ;
wire [BUS_WIDTH-1       :0] ram_r_a_data_araddr_next   ;
wire                        ram_r_a_data_araddr_update ;
wire [BUS_WIDTH-1       :0] ram_r_a_data_araddr_wrap   ;
reg  [1                 :0] ram_r_a_data_arburst       ;
wire                        ram_r_a_data_arburst_fixed ;
wire                        ram_r_a_data_arburst_incr  ;
wire                        ram_r_a_data_arburst_wrap  ;
reg  [3                 :0] ram_r_a_data_arid          ;
reg  [3                 :0] ram_r_a_data_arlen         ;
wire                        ram_r_a_data_arlen_last    ;
reg  [2                 :0] ram_r_a_data_arsize        ;
wire                        ram_r_a_data_push          ;
wire                        ram_r_a_full               ;
wire                        ram_r_a_pop                ;
wire                        ram_r_a_push               ;
wire [BUS_WIDTH+13-1    :0] ram_r_a_push_data          ;
reg  [BUS_WIDTH+13-1    :0] ram_r_a_queue_datas        ;
wire [BUS_WIDTH-1       :0] ram_r_a_queue_datas_araddr ;
wire [1                 :0] ram_r_a_queue_datas_arburst;
wire [3                 :0] ram_r_a_queue_datas_arid   ;
wire [3                 :0] ram_r_a_queue_datas_arlen  ;
wire [2                 :0] ram_r_a_queue_datas_arsize ;
wire                        ram_r_a_queue_empty        ;
wire                        ram_r_a_queue_full         ;
wire                        ram_r_a_queue_pop          ;
wire                        ram_r_a_queue_push         ;
reg                         ram_r_a_queue_valid        ;
reg                         ram_r_a_valid              ;
wire [BUS_WIDTH-1       :0] ram_r_addr                 ;
wire                        ram_r_allow_out            ;
wire [DATA_WIDTH-1      :0] ram_r_data                 ;
wire                        ram_r_en                   ;
reg  [3                 :0] ram_r_rcur                 ;
wire                        ram_r_rcur_reset           ;
reg  [3                 :0] ram_r_rid                  ;
reg                         ram_r_rlast                ;
reg                         ram_r_rvalid               ;
wire [BUS_WIDTH+13-1    :0] ram_w_a_data               ;
reg  [BUS_WIDTH-1       :0] ram_w_a_data_awaddr        ;
wire [BUS_WIDTH-1       :0] ram_w_a_data_awaddr_fixed  ;
wire [BUS_WIDTH-1       :0] ram_w_a_data_awaddr_incr   ;
wire [BUS_WIDTH-1       :0] ram_w_a_data_awaddr_next   ;
wire                        ram_w_a_data_awaddr_update ;
wire [BUS_WIDTH-1       :0] ram_w_a_data_awaddr_wrap   ;
reg  [1                 :0] ram_w_a_data_awburst       ;
wire                        ram_w_a_data_awburst_fixed ;
wire                        ram_w_a_data_awburst_incr  ;
wire                        ram_w_a_data_awburst_wrap  ;
reg  [3                 :0] ram_w_a_data_awid          ;
reg  [3                 :0] ram_w_a_data_awlen         ;
reg  [2                 :0] ram_w_a_data_awsize        ;
wire                        ram_w_a_data_push          ;
wire                        ram_w_a_full               ;
wire                        ram_w_a_pop                ;
wire                        ram_w_a_push               ;
wire [BUS_WIDTH+13-1    :0] ram_w_a_push_data          ;
reg  [BUS_WIDTH+13-1    :0] ram_w_a_queue_datas        ;
wire [BUS_WIDTH-1       :0] ram_w_a_queue_datas_awaddr ;
wire [1                 :0] ram_w_a_queue_datas_awburst;
wire [3                 :0] ram_w_a_queue_datas_awid   ;
wire [3                 :0] ram_w_a_queue_datas_awlen  ;
wire [2                 :0] ram_w_a_queue_datas_awsize ;
wire                        ram_w_a_queue_empty        ;
wire                        ram_w_a_queue_full         ;
wire                        ram_w_a_queue_pop          ;
wire                        ram_w_a_queue_push         ;
reg                         ram_w_a_queue_valid        ;
reg                         ram_w_a_valid              ;
wire [BUS_WIDTH-1       :0] ram_w_addr                 ;
wire                        ram_w_allow_out            ;
reg  [3                 :0] ram_w_b_data               ;
wire                        ram_w_b_data_push          ;
wire                        ram_w_b_full               ;
wire                        ram_w_b_pop                ;
wire                        ram_w_b_push               ;
reg  [3                 :0] ram_w_b_queue_datas        ;
wire                        ram_w_b_queue_empty        ;
wire                        ram_w_b_queue_full         ;
wire                        ram_w_b_queue_pop          ;
wire                        ram_w_b_queue_push         ;
reg                         ram_w_b_queue_valid        ;
reg                         ram_w_b_valid              ;
wire                        ram_w_en                   ;
wire                        ram_w_go                   ;
wire [DATA_WIDTH/8-1    :0] ram_w_strb                 ;
reg  [DATA_WIDTH-1      :0] ram_w_wdata                ;
reg                         ram_w_wlast                ;
reg  [DATA_WIDTH/8-1    :0] ram_w_wstrb                ;
reg                         ram_w_wvalid               ;
assign m_arready                          = !ram_r_a_full;
assign m_awready                          = !ram_w_a_full;
assign m_bid                              =  ram_w_b_data;
assign m_bresp                            = 2'h0;
assign m_bvalid                           = ram_w_b_valid;
assign m_rdata                            = ram_rdata    ;
assign m_rid                              = ram_r_rid    ;
assign m_rlast                            = ram_r_rlast  ;
assign m_rresp                            = 2'h0;
assign m_rvalid                           = ram_r_rvalid;
assign m_wready                           = ram_w_allow_out || !ram_w_wvalid;
assign ram_r_a_data                       = {ram_r_a_data_arburst,ram_r_a_data_arsize,ram_r_a_data_arlen,ram_r_a_data_araddr,ram_r_a_data_arid};
assign ram_r_a_data_araddr_fixed          = ram_r_a_data_araddr;
assign ram_r_a_data_araddr_incr [ADDR_INCR_BASE-1:0]          = ram_r_a_data_araddr[ADDR_INCR_BASE-1:0];
assign ram_r_a_data_araddr_incr [BUS_WIDTH-1 :ADDR_INCR_BASE ] = ram_r_a_data_araddr[BUS_WIDTH-1:ADDR_INCR_BASE] + {{BUS_WIDTH-ADDR_INCR_BASE-1{1'b0}},1'b1};
assign ram_r_a_data_araddr_next           = {BUS_WIDTH{ram_r_a_data_arburst_fixed}} & ram_r_a_data_araddr_fixed
                                          | {BUS_WIDTH{ram_r_a_data_arburst_incr }} & ram_r_a_data_araddr_incr 
                                          | {BUS_WIDTH{ram_r_a_data_arburst_wrap }} & ram_r_a_data_araddr_wrap ;
assign ram_r_a_data_araddr_update        = ram_r_en && !ram_r_a_data_arlen_last;
assign ram_r_a_data_araddr_wrap   [ADDR_INCR_BASE-1 :0] = ram_r_a_data_araddr[ADDR_INCR_BASE-1 :0];
assign ram_r_a_data_araddr_wrap   [BUS_WIDTH-1:ADDR_INCR_BASE+4] = ram_r_a_data_araddr[BUS_WIDTH-1:ADDR_INCR_BASE+4];
assign ram_r_a_data_araddr_wrap   [ADDR_INCR_BASE+3 :ADDR_INCR_BASE] = ram_r_a_data_araddr[ADDR_INCR_BASE+3:ADDR_INCR_BASE] & ~ram_r_a_data_arlen | ram_r_a_data_arlen & ram_r_a_data_araddr[ADDR_INCR_BASE+3:ADDR_INCR_BASE] + 4'h1;
assign ram_r_a_data_arburst_fixed        = ram_r_a_data_arburst == 2'h0;
assign ram_r_a_data_arburst_incr         = ram_r_a_data_arburst == 2'h1;
assign ram_r_a_data_arburst_wrap         = ram_r_a_data_arburst == 2'h2;
assign ram_r_a_data_arlen_last           = ram_r_a_data_arlen == ram_r_rcur;
assign ram_r_a_data_push                 = ram_r_a_push && (ram_r_a_pop || !ram_r_a_valid);
assign ram_r_a_full                      = ram_r_a_queue_full;
assign ram_r_a_pop                       = ram_r_en  &&  ram_r_a_data_arlen_last;
assign ram_r_a_push                      = m_arvalid && !ram_r_a_full           ;
//assign ram_r_a_push_data                 = {m_arburst,m_arsize  ,m_arlen,m_araddr,m_arid};
assign ram_r_a_push_data                 = {m_araddr,m_arburst,m_arsize,m_arlen,m_arid};
assign ram_r_a_queue_datas_araddr        = ram_r_a_queue_datas[BUS_WIDTH-1+13:13];
assign ram_r_a_queue_datas_arburst       = ram_r_a_queue_datas[12            :11];
assign ram_r_a_queue_datas_arid          = ram_r_a_queue_datas[3             : 0];
assign ram_r_a_queue_datas_arlen         = ram_r_a_queue_datas[7             : 4];
assign ram_r_a_queue_datas_arsize        = ram_r_a_queue_datas[10            : 8];
assign ram_r_a_queue_empty               = !ram_r_a_queue_valid;
assign ram_r_a_queue_full                =  ram_r_a_queue_valid;
assign ram_r_a_queue_pop                 = ram_r_a_pop && !ram_r_a_queue_empty;
assign ram_r_a_queue_push                = ram_r_a_push && ram_r_a_valid &&   !ram_r_a_pop && !ram_r_a_queue_full;
assign ram_r_addr                        = ram_r_a_data_araddr;
assign ram_r_allow_out                   = m_rready || !m_rvalid;
assign ram_r_data                        = ram_rdata;
assign ram_r_en                          = ram_r_a_valid && ram_r_allow_out;
assign ram_r_rcur_reset                  = !aresetn || ram_r_a_pop;
assign ram_w_a_data                      = {ram_w_a_data_awaddr,ram_w_a_data_awburst,ram_w_a_data_awsize  ,ram_w_a_data_awlen,ram_w_a_data_awid};
assign ram_w_a_data_awaddr_fixed         = ram_w_a_data_awaddr;
assign ram_w_a_data_awaddr_incr   [ADDR_INCR_BASE-1 :0] = ram_w_a_data_awaddr[ADDR_INCR_BASE-1:0];
assign ram_w_a_data_awaddr_incr   [BUS_WIDTH-1:ADDR_INCR_BASE] = ram_w_a_data_awaddr[BUS_WIDTH-1:ADDR_INCR_BASE] + {{BUS_WIDTH-ADDR_INCR_BASE-1{1'b0}},1'b1};
assign ram_w_a_data_awaddr_next          = {BUS_WIDTH{ram_w_a_data_awburst_fixed}} & ram_w_a_data_awaddr_fixed
                                         | {BUS_WIDTH{ram_w_a_data_awburst_incr }} & ram_w_a_data_awaddr_incr 
                                         | {BUS_WIDTH{ram_w_a_data_awburst_wrap }} & ram_w_a_data_awaddr_wrap ;
assign ram_w_a_data_awaddr_update        = ram_w_en && !ram_w_wlast;
assign ram_w_a_data_awaddr_wrap   [ADDR_INCR_BASE-1 :0] = ram_w_a_data_awaddr[ADDR_INCR_BASE-1 :0];
assign ram_w_a_data_awaddr_wrap   [BUS_WIDTH-1:ADDR_INCR_BASE+4] = ram_w_a_data_awaddr[BUS_WIDTH-1:ADDR_INCR_BASE+4];
assign ram_w_a_data_awaddr_wrap   [ADDR_INCR_BASE+3:ADDR_INCR_BASE] = ram_w_a_data_awaddr[ADDR_INCR_BASE+3:ADDR_INCR_BASE] & ~ram_w_a_data_awlen | ram_w_a_data_awlen & ram_w_a_data_awaddr[ADDR_INCR_BASE+3:ADDR_INCR_BASE] + 4'h1;
assign ram_w_a_data_awburst_fixed        = ram_w_a_data_awburst == 2'h0;
assign ram_w_a_data_awburst_incr         = ram_w_a_data_awburst == 2'h1;
assign ram_w_a_data_awburst_wrap         = ram_w_a_data_awburst == 2'h2;
assign ram_w_a_data_push                 = ram_w_a_push && (ram_w_a_pop || !ram_w_a_valid);
assign ram_w_a_full                      = ram_w_a_queue_full;
assign ram_w_a_pop                       = ram_w_en  &&  ram_w_wlast ;
assign ram_w_a_push                      = m_awvalid && !ram_w_a_full;
assign ram_w_a_push_data                 = {m_awaddr,m_awburst,m_awsize  ,m_awlen,m_awid};
assign ram_w_a_queue_datas_awaddr        = ram_w_a_queue_datas[BUS_WIDTH-1+13:13];
assign ram_w_a_queue_datas_awburst       = ram_w_a_queue_datas[12            :11];
assign ram_w_a_queue_datas_awid          = ram_w_a_queue_datas[3             : 0];
assign ram_w_a_queue_datas_awlen         = ram_w_a_queue_datas[7             : 4];
assign ram_w_a_queue_datas_awsize        = ram_w_a_queue_datas[10            : 8];
assign ram_w_a_queue_empty               = !ram_w_a_queue_valid;
assign ram_w_a_queue_full                =  ram_w_a_queue_valid;
assign ram_w_a_queue_pop                 = ram_w_a_pop && !ram_w_a_queue_empty;
assign ram_w_a_queue_push                = ram_w_a_push && ram_w_a_valid &&   !ram_w_a_pop && !ram_w_a_queue_full;
assign ram_w_addr                        = ram_w_a_data_awaddr;
assign ram_w_allow_out                   = ram_w_a_valid && !ram_w_b_full;
assign ram_w_b_data_push                 = ram_w_b_push && (ram_w_b_pop || !ram_w_b_valid);
assign ram_w_b_full                      = ram_w_b_queue_full;
assign ram_w_b_pop                       = m_bready && ram_w_b_valid;
assign ram_w_b_push                      =  ram_w_a_pop        ;
assign ram_w_b_queue_empty               = !ram_w_b_queue_valid;
assign ram_w_b_queue_full                =  ram_w_b_queue_valid;
assign ram_w_b_queue_pop                 = ram_w_b_pop && !ram_w_b_queue_empty;
assign ram_w_b_queue_push                = ram_w_b_push && ram_w_b_valid &&   !ram_w_b_pop && !ram_w_b_queue_full;
assign ram_w_en                          = ram_w_wvalid && ram_w_allow_out && aresetn;
assign ram_w_go                          = m_wvalid && m_wready;
assign ram_w_strb                        = ram_w_wstrb;
assign ram_raddr                         = ram_r_addr ;
assign ram_ren                           = ram_r_en   ;
assign ram_waddr                         = ram_w_addr ;
assign ram_wdata                         = ram_w_wdata;
assign ram_wen                           = ram_w_strb & {DATA_WIDTH/8{ram_w_en}};
always@(posedge aclk)
begin
    if(ram_r_rcur_reset)
    begin
        ram_r_rcur<=4'h0;
    end
    else
    if(ram_r_en)
    begin
        ram_r_rcur<=ram_r_rcur + 4'h1;
    end
end
always@(posedge aclk)
begin
    if(ram_r_en)
    begin
        ram_r_rid<=ram_r_a_data_arid;
    end
end
always@(posedge aclk)
begin
    if(ram_r_en)
    begin
        ram_r_rlast<=ram_r_a_data_arlen_last;
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_r_rvalid<=1'h0;
    end
    else
    if(ram_r_en)
    begin
        ram_r_rvalid<=1'h1;
    end
    else
    if(m_rready)
    begin
        ram_r_rvalid<=1'h0;
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_r_a_valid<=1'h0;
    end
    else
    if(ram_r_a_push)
    begin
        ram_r_a_valid<=1'h1;
    end
    else
    if(ram_r_a_pop)
    begin
        ram_r_a_valid<=ram_r_a_queue_valid;
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_r_a_queue_valid<=1'h0;
    end
    else
    if(ram_r_a_queue_push)
    begin
        ram_r_a_queue_valid<=1'h1;
    end
    else
    if(ram_r_a_queue_pop)
    begin
        ram_r_a_queue_valid<=1'h0;
    end
end
always@(posedge aclk)
begin
    if(ram_r_a_queue_push)
    begin
        ram_r_a_queue_datas<=ram_r_a_push_data;
    end
end
always@(posedge aclk)
begin
    if(ram_r_a_data_push)
    begin
        ram_r_a_data_arburst<=m_arburst;
        ram_r_a_data_arid   <=m_arid   ;
        ram_r_a_data_arlen  <=m_arlen  ;
        ram_r_a_data_arsize <=m_arsize ;
    end
    else
    if(ram_r_a_pop)
    begin
        ram_r_a_data_arburst<=ram_r_a_queue_datas_arburst;
        ram_r_a_data_arid   <=ram_r_a_queue_datas_arid   ;
        ram_r_a_data_arlen  <=ram_r_a_queue_datas_arlen  ;
        ram_r_a_data_arsize <=ram_r_a_queue_datas_arsize ;
    end
end
always@(posedge aclk)
begin
    if(ram_r_a_data_push)
    begin
        ram_r_a_data_araddr<=m_araddr;
    end
    else
    if(ram_r_a_pop)
    begin
        ram_r_a_data_araddr<=ram_r_a_queue_datas_araddr;
    end
    else
    begin
        if(ram_r_a_data_araddr_update)
        begin
            ram_r_a_data_araddr<=ram_r_a_data_araddr_next;
        end
    end
end
always@(posedge aclk)
begin
    if(ram_w_go)
    begin
        ram_w_wdata<=m_wdata;
        ram_w_wlast<=m_wlast;
        ram_w_wstrb<=m_wstrb;
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_w_wvalid<=1'h0;
    end
    else
    if(ram_w_go)
    begin
        ram_w_wvalid<=1'h1;
    end
    else
    if(ram_w_en)
    begin
        ram_w_wvalid<=1'h0;
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_w_a_valid<=1'h0;
    end
    else
    if(ram_w_a_push)
    begin
        ram_w_a_valid<=1'h1;
    end
    else
    if(ram_w_a_pop)
    begin
        ram_w_a_valid<=ram_w_a_queue_valid;
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_w_a_queue_valid<=1'h0;
    end
    else
    if(ram_w_a_queue_push)
    begin
        ram_w_a_queue_valid<=1'h1;
    end
    else
    if(ram_w_a_queue_pop)
    begin
        ram_w_a_queue_valid<=1'h0;
    end
end
always@(posedge aclk)
begin
    if(ram_w_a_queue_push)
    begin
        ram_w_a_queue_datas<=ram_w_a_push_data;
    end
end
always@(posedge aclk)
begin
    if(ram_w_a_data_push)
    begin
        ram_w_a_data_awburst<=m_awburst;
        ram_w_a_data_awid   <=m_awid   ;
        ram_w_a_data_awlen  <=m_awlen  ;
        ram_w_a_data_awsize <=m_awsize ;
    end
    else
    if(ram_w_a_pop)
    begin
        ram_w_a_data_awburst<=ram_w_a_queue_datas_awburst;
        ram_w_a_data_awid   <=ram_w_a_queue_datas_awid   ;
        ram_w_a_data_awlen  <=ram_w_a_queue_datas_awlen  ;
        ram_w_a_data_awsize <=ram_w_a_queue_datas_awsize ;
    end
end
always@(posedge aclk)
begin
    if(ram_w_a_data_push)
    begin
        ram_w_a_data_awaddr<=m_awaddr;
    end
    else
    if(ram_w_a_pop)
    begin
        ram_w_a_data_awaddr<=ram_w_a_queue_datas_awaddr;
    end
    else
    begin
        if(ram_w_a_data_awaddr_update)
        begin
            ram_w_a_data_awaddr<=ram_w_a_data_awaddr_next;
        end
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_w_b_valid<=1'h0;
    end
    else
    if(ram_w_b_push)
    begin
        ram_w_b_valid<=1'h1;
    end
    else
    if(ram_w_b_pop)
    begin
        ram_w_b_valid<=ram_w_b_queue_valid;
    end
end
always@(posedge aclk)
begin
    if(!aresetn)
    begin
        ram_w_b_queue_valid<=1'h0;
    end
    else
    if(ram_w_b_queue_push)
    begin
        ram_w_b_queue_valid<=1'h1;
    end
    else
    if(ram_w_b_queue_pop)
    begin
        ram_w_b_queue_valid<=1'h0;
    end
end
always@(posedge aclk)
begin
    if(ram_w_b_queue_push)
    begin
        ram_w_b_queue_datas<=ram_w_a_data_awid;
    end
end
always@(posedge aclk)
begin
    if(ram_w_b_data_push)
    begin
        ram_w_b_data<=ram_w_a_data_awid;
    end
    else
    if(ram_w_b_pop)
    begin
        ram_w_b_data<=ram_w_b_queue_datas;
    end
end
endmodule // soc_axi_sram_bridge
