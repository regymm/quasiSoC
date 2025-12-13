#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : axi_bd_module_gen.py
# License           : GPL-3.0-or-later
# Author            : Peter Gu <github.com/regymm>
# Date              : 2024.10.30
# Last Modified Date: 2024.10.30

FILE = 'axilxbar_bd_module.v'
NM = 2 # number of masters
NS = 39 # number of slaves
AW = 32 # addr width
DW = 32 # data width
SLAVE_ADDR = ''' {
} '''
SLAVE_MASK = '''
{(NS){ 32'hFFFF0000 }}
'''
def axi_bd_module_gen(FILE, NM, NS, AW, DW, SLAVE_ADDR, SLAVE_MASK, MODULE_NAME):
    with open(FILE, 'w') as f:
        f.write(f'''module { MODULE_NAME } #(
        // parameter NM = {NM},
        // parameter NS = {NS}
    ''')

        f.write(''')(
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_clk, ASSOCIATED_BUSIF ''')
        for i in range(NM):
            f.write(f's_axi_{i}:')
        for i in range(NS):
            f.write(f'm_axi_{i}')
            if i != NS-1:
                f.write(':')
        f.write(''', ASSOCIATED_RESET s_axi_aresetn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_clk CLK" *)
    input wire S_AXI_ACLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    input wire S_AXI_ARESETN,''')
        for i in range(NS):
            f.write(f'''
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} AWVALID" *)
    output wire M_AXI_{i}_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} AWREADY" *)
    input wire M_AXI_{i}_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} AWADDR" *)
    output wire [{AW}-1:0] M_AXI_{i}_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} AWPROT" *)
    output wire [2:0] M_AXI_{i}_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} WVALID" *)
    output wire M_AXI_{i}_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} WREADY" *)
    input wire M_AXI_{i}_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} WDATA" *)
    output wire [{DW}-1:0] M_AXI_{i}_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} WSTRB" *)
    output wire [{int(DW/8)}-1:0] M_AXI_{i}_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} BVALID" *)
    input wire M_AXI_{i}_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} BREADY" *)
    output wire M_AXI_{i}_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} BRESP" *)
    input wire [1:0] M_AXI_{i}_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} ARVALID" *)
    output wire M_AXI_{i}_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} ARREADY" *)
    input wire M_AXI_{i}_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} ARADDR" *)
    output wire [{AW}-1:0] M_AXI_{i}_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} ARPROT" *)
    output wire [2:0] M_AXI_{i}_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} RVALID" *)
    input wire M_AXI_{i}_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} RREADY" *)
    output wire M_AXI_{i}_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} RRESP" *)
    input wire [1:0] M_AXI_{i}_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_{i} RDATA" *)
    input wire [{DW}-1:0] M_AXI_{i}_RDATA,
    ''')
        for i in range(NM):
            f.write(f'''
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} AWVALID" *)
    input wire S_AXI_{i}_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} AWREADY" *)
    output wire S_AXI_{i}_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} AWADDR" *)
    input wire [{AW}-1:0] S_AXI_{i}_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} AWPROT" *)
    input wire [2:0] S_AXI_{i}_AWPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} WVALID" *)
    input wire S_AXI_{i}_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} WREADY" *)
    output wire S_AXI_{i}_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} WDATA" *)
    input wire [{DW}-1:0] S_AXI_{i}_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} WSTRB" *)
    input wire [{int(DW/8)}-1:0] S_AXI_{i}_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} BVALID" *)
    output wire S_AXI_{i}_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} BREADY" *)
    input wire S_AXI_{i}_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} BRESP" *)
    output wire [1:0] S_AXI_{i}_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} ARVALID" *)
    input wire S_AXI_{i}_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} ARREADY" *)
    output wire S_AXI_{i}_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} ARADDR" *)
    input wire [{AW}-1:0] S_AXI_{i}_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} ARPROT" *)
    input wire [2:0] S_AXI_{i}_ARPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} RVALID" *)
    output wire S_AXI_{i}_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} RREADY" *)
    input wire S_AXI_{i}_RREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} RRESP" *)
    output wire [1:0] S_AXI_{i}_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_{i} RDATA" *)
    output wire [{DW}-1:0] S_AXI_{i}_RDATA
    ''')
            if i != NM-1:
                f.write(',\n')
        f.write(f''');
    axilxbar #(
    .C_AXI_DATA_WIDTH({ DW }),
    .C_AXI_ADDR_WIDTH({ AW }),
    .NM({ NM }),
    .NS({ NS }),
    .SLAVE_ADDR({ SLAVE_ADDR }),
    .SLAVE_MASK({ SLAVE_MASK })
    ) axilxbar_inst (
    ''');
        for sig in ['AWVALID', 'AWREADY', 'AWADDR', 'AWPROT', 'WVALID', 'WREADY', 'WDATA', 'WSTRB', 'BVALID', 'BREADY', 'BRESP', 'ARVALID', 'ARREADY', 'ARADDR', 'ARPROT', 'RVALID', 'RREADY', 'RDATA', 'RRESP']:
            f.write(f".S_AXI_{sig}({{{''.join(['S_AXI_' + str(i) + '_' + sig + ',' for i in range(NM)][::-1])[:-1]}}}),\n")
        for sig in ['AWVALID', 'AWREADY', 'AWADDR', 'AWPROT', 'WVALID', 'WREADY', 'WDATA', 'WSTRB', 'BVALID', 'BREADY', 'BRESP', 'ARVALID', 'ARREADY', 'ARADDR', 'ARPROT', 'RVALID', 'RREADY', 'RDATA', 'RRESP']:
            f.write(f".M_AXI_{sig}({{{''.join(['M_AXI_' + str(i) + '_' + sig + ',' for i in range(NS)][::-1])[:-1]}}}),\n")

        f.write( f'''
    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN)
    );
    endmodule
    ''')
        f.close()


if __name__ == '__main__':
    # main memory: 0xxxxxxx
    # MMIO: 1xxxxxxx
    # spare memory: 2xxxxxxx (unused)
    # Others: fxxxxxxx (unused)
    axi_bd_module_gen('xbar_4_4_quasisoc.v', 4, 2, 32, 32, "{32'h10000000, 32'h00000000}", "{32'h30000000, 32'hf0000000}", 'xbar_4_4_quasisoc')
