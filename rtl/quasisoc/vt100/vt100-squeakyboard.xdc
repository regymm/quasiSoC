set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports sysclk]
create_clock -period 20.000 [get_nets sysclk]
set_property PHASESHIFT_MODE WAVEFORM [get_cells -hierarchical *adv*]

set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property PULLUP true [get_ports {sw[0]}]
set_property PULLUP true [get_ports {sw[1]}]

set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports rx]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports tx]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports tx_up]

set_property -dict {PACKAGE_PIN W20 IOSTANDARD TMDS_33} [get_ports TMDSn_clock]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD TMDS_33} [get_ports TMDSp_clock]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD TMDS_33} [get_ports {TMDSn[0]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD TMDS_33} [get_ports {TMDSp[0]}]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports {TMDSn[1]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports {TMDSp[1]}]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD TMDS_33} [get_ports {TMDSn[2]}]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD TMDS_33} [get_ports {TMDSp[2]}]


connect_debug_port u_ila_0/probe1 [get_nets [list {vt100_inst/rv_v_rd[0]} {vt100_inst/rv_v_rd[1]} {vt100_inst/rv_v_rd[2]} {vt100_inst/rv_v_rd[3]} {vt100_inst/rv_v_rd[4]} {vt100_inst/rv_v_rd[5]} {vt100_inst/rv_v_rd[6]} {vt100_inst/rv_v_rd[7]} {vt100_inst/rv_v_rd[8]} {vt100_inst/rv_v_rd[9]} {vt100_inst/rv_v_rd[10]} {vt100_inst/rv_v_rd[11]} {vt100_inst/rv_v_rd[12]} {vt100_inst/rv_v_rd[13]} {vt100_inst/rv_v_rd[14]} {vt100_inst/rv_v_rd[15]} {vt100_inst/rv_v_rd[16]} {vt100_inst/rv_v_rd[17]} {vt100_inst/rv_v_rd[18]} {vt100_inst/rv_v_rd[19]} {vt100_inst/rv_v_rd[20]} {vt100_inst/rv_v_rd[21]} {vt100_inst/rv_v_rd[22]} {vt100_inst/rv_v_rd[23]} {vt100_inst/rv_v_rd[24]} {vt100_inst/rv_v_rd[25]} {vt100_inst/rv_v_rd[26]} {vt100_inst/rv_v_rd[27]} {vt100_inst/rv_v_rd[28]} {vt100_inst/rv_v_rd[29]} {vt100_inst/rv_v_rd[30]} {vt100_inst/rv_v_rd[31]}]]


connect_debug_port u_ila_0/probe0 [get_nets [list {fb_a[0]} {fb_a[1]} {fb_a[2]} {fb_a[3]} {fb_a[4]} {fb_a[5]} {fb_a[6]} {fb_a[7]} {fb_a[8]} {fb_a[9]} {fb_a[10]} {fb_a[11]}]]
connect_debug_port u_ila_0/probe5 [get_nets [list {fb_d[0]} {fb_d[1]} {fb_d[2]} {fb_d[3]} {fb_d[4]} {fb_d[5]} {fb_d[6]} {fb_d[7]} {fb_d[8]} {fb_d[9]} {fb_d[10]} {fb_d[11]} {fb_d[12]} {fb_d[13]} {fb_d[14]} {fb_d[15]}]]
connect_debug_port u_ila_0/probe7 [get_nets [list fb_we]]
connect_debug_port dbg_hub/clk [get_nets clk]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clock_wizard_inst/inst/clk_main]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {riscv_multicyc_inst/pc[0]} {riscv_multicyc_inst/pc[1]} {riscv_multicyc_inst/pc[2]} {riscv_multicyc_inst/pc[3]} {riscv_multicyc_inst/pc[4]} {riscv_multicyc_inst/pc[5]} {riscv_multicyc_inst/pc[6]} {riscv_multicyc_inst/pc[7]} {riscv_multicyc_inst/pc[8]} {riscv_multicyc_inst/pc[9]} {riscv_multicyc_inst/pc[10]} {riscv_multicyc_inst/pc[11]} {riscv_multicyc_inst/pc[12]} {riscv_multicyc_inst/pc[13]} {riscv_multicyc_inst/pc[14]} {riscv_multicyc_inst/pc[15]} {riscv_multicyc_inst/pc[16]} {riscv_multicyc_inst/pc[17]} {riscv_multicyc_inst/pc[18]} {riscv_multicyc_inst/pc[19]} {riscv_multicyc_inst/pc[20]} {riscv_multicyc_inst/pc[21]} {riscv_multicyc_inst/pc[22]} {riscv_multicyc_inst/pc[23]} {riscv_multicyc_inst/pc[24]} {riscv_multicyc_inst/pc[25]} {riscv_multicyc_inst/pc[26]} {riscv_multicyc_inst/pc[27]} {riscv_multicyc_inst/pc[28]} {riscv_multicyc_inst/pc[29]} {riscv_multicyc_inst/pc[30]} {riscv_multicyc_inst/pc[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {riscv_multicyc_inst/instruction[0]} {riscv_multicyc_inst/instruction[1]} {riscv_multicyc_inst/instruction[2]} {riscv_multicyc_inst/instruction[3]} {riscv_multicyc_inst/instruction[4]} {riscv_multicyc_inst/instruction[5]} {riscv_multicyc_inst/instruction[6]} {riscv_multicyc_inst/instruction[7]} {riscv_multicyc_inst/instruction[8]} {riscv_multicyc_inst/instruction[9]} {riscv_multicyc_inst/instruction[10]} {riscv_multicyc_inst/instruction[11]} {riscv_multicyc_inst/instruction[12]} {riscv_multicyc_inst/instruction[13]} {riscv_multicyc_inst/instruction[14]} {riscv_multicyc_inst/instruction[15]} {riscv_multicyc_inst/instruction[16]} {riscv_multicyc_inst/instruction[17]} {riscv_multicyc_inst/instruction[18]} {riscv_multicyc_inst/instruction[19]} {riscv_multicyc_inst/instruction[20]} {riscv_multicyc_inst/instruction[21]} {riscv_multicyc_inst/instruction[22]} {riscv_multicyc_inst/instruction[23]} {riscv_multicyc_inst/instruction[24]} {riscv_multicyc_inst/instruction[25]} {riscv_multicyc_inst/instruction[26]} {riscv_multicyc_inst/instruction[27]} {riscv_multicyc_inst/instruction[28]} {riscv_multicyc_inst/instruction[29]} {riscv_multicyc_inst/instruction[30]} {riscv_multicyc_inst/instruction[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {highmapper_inst/spo[0]} {highmapper_inst/spo[1]} {highmapper_inst/spo[2]} {highmapper_inst/spo[3]} {highmapper_inst/spo[4]} {highmapper_inst/spo[5]} {highmapper_inst/spo[6]} {highmapper_inst/spo[7]} {highmapper_inst/spo[8]} {highmapper_inst/spo[9]} {highmapper_inst/spo[10]} {highmapper_inst/spo[11]} {highmapper_inst/spo[12]} {highmapper_inst/spo[13]} {highmapper_inst/spo[14]} {highmapper_inst/spo[15]} {highmapper_inst/spo[16]} {highmapper_inst/spo[17]} {highmapper_inst/spo[18]} {highmapper_inst/spo[19]} {highmapper_inst/spo[20]} {highmapper_inst/spo[21]} {highmapper_inst/spo[22]} {highmapper_inst/spo[23]} {highmapper_inst/spo[24]} {highmapper_inst/spo[25]} {highmapper_inst/spo[26]} {highmapper_inst/spo[27]} {highmapper_inst/spo[28]} {highmapper_inst/spo[29]} {highmapper_inst/spo[30]} {highmapper_inst/spo[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {highmapper_inst/a[0]} {highmapper_inst/a[1]} {highmapper_inst/a[2]} {highmapper_inst/a[3]} {highmapper_inst/a[4]} {highmapper_inst/a[5]} {highmapper_inst/a[6]} {highmapper_inst/a[7]} {highmapper_inst/a[8]} {highmapper_inst/a[9]} {highmapper_inst/a[10]} {highmapper_inst/a[11]} {highmapper_inst/a[12]} {highmapper_inst/a[13]} {highmapper_inst/a[14]} {highmapper_inst/a[15]} {highmapper_inst/a[16]} {highmapper_inst/a[17]} {highmapper_inst/a[18]} {highmapper_inst/a[19]} {highmapper_inst/a[20]} {highmapper_inst/a[21]} {highmapper_inst/a[22]} {highmapper_inst/a[23]} {highmapper_inst/a[24]} {highmapper_inst/a[25]} {highmapper_inst/a[26]} {highmapper_inst/a[27]} {highmapper_inst/a[28]} {highmapper_inst/a[29]} {highmapper_inst/a[30]} {highmapper_inst/a[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 32 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {highmapper_inst/d[0]} {highmapper_inst/d[1]} {highmapper_inst/d[2]} {highmapper_inst/d[3]} {highmapper_inst/d[4]} {highmapper_inst/d[5]} {highmapper_inst/d[6]} {highmapper_inst/d[7]} {highmapper_inst/d[8]} {highmapper_inst/d[9]} {highmapper_inst/d[10]} {highmapper_inst/d[11]} {highmapper_inst/d[12]} {highmapper_inst/d[13]} {highmapper_inst/d[14]} {highmapper_inst/d[15]} {highmapper_inst/d[16]} {highmapper_inst/d[17]} {highmapper_inst/d[18]} {highmapper_inst/d[19]} {highmapper_inst/d[20]} {highmapper_inst/d[21]} {highmapper_inst/d[22]} {highmapper_inst/d[23]} {highmapper_inst/d[24]} {highmapper_inst/d[25]} {highmapper_inst/d[26]} {highmapper_inst/d[27]} {highmapper_inst/d[28]} {highmapper_inst/d[29]} {highmapper_inst/d[30]} {highmapper_inst/d[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list highmapper_inst/rd]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list highmapper_inst/ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list highmapper_inst/we]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_main]
