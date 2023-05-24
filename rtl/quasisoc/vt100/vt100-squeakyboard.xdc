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
set_property port_width 12 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {fb_a[0]} {fb_a[1]} {fb_a[2]} {fb_a[3]} {fb_a[4]} {fb_a[5]} {fb_a[6]} {fb_a[7]} {fb_a[8]} {fb_a[9]} {fb_a[10]} {fb_a[11]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {vt100_inst/uart_vt100_rx/data_rx[0]} {vt100_inst/uart_vt100_rx/data_rx[1]} {vt100_inst/uart_vt100_rx/data_rx[2]} {vt100_inst/uart_vt100_rx/data_rx[3]} {vt100_inst/uart_vt100_rx/data_rx[4]} {vt100_inst/uart_vt100_rx/data_rx[5]} {vt100_inst/uart_vt100_rx/data_rx[6]} {vt100_inst/uart_vt100_rx/data_rx[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {vt100_inst/rv_v_spo[0]} {vt100_inst/rv_v_spo[1]} {vt100_inst/rv_v_spo[2]} {vt100_inst/rv_v_spo[3]} {vt100_inst/rv_v_spo[4]} {vt100_inst/rv_v_spo[5]} {vt100_inst/rv_v_spo[6]} {vt100_inst/rv_v_spo[7]} {vt100_inst/rv_v_spo[8]} {vt100_inst/rv_v_spo[9]} {vt100_inst/rv_v_spo[10]} {vt100_inst/rv_v_spo[11]} {vt100_inst/rv_v_spo[12]} {vt100_inst/rv_v_spo[13]} {vt100_inst/rv_v_spo[14]} {vt100_inst/rv_v_spo[15]} {vt100_inst/rv_v_spo[16]} {vt100_inst/rv_v_spo[17]} {vt100_inst/rv_v_spo[18]} {vt100_inst/rv_v_spo[19]} {vt100_inst/rv_v_spo[20]} {vt100_inst/rv_v_spo[21]} {vt100_inst/rv_v_spo[22]} {vt100_inst/rv_v_spo[23]} {vt100_inst/rv_v_spo[24]} {vt100_inst/rv_v_spo[25]} {vt100_inst/rv_v_spo[26]} {vt100_inst/rv_v_spo[27]} {vt100_inst/rv_v_spo[28]} {vt100_inst/rv_v_spo[29]} {vt100_inst/rv_v_spo[30]} {vt100_inst/rv_v_spo[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {vt100_inst/rxdata[0]} {vt100_inst/rxdata[1]} {vt100_inst/rxdata[2]} {vt100_inst/rxdata[3]} {vt100_inst/rxdata[4]} {vt100_inst/rxdata[5]} {vt100_inst/rxdata[6]} {vt100_inst/rxdata[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 32 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {vt100_inst/rv_v_d[0]} {vt100_inst/rv_v_d[1]} {vt100_inst/rv_v_d[2]} {vt100_inst/rv_v_d[3]} {vt100_inst/rv_v_d[4]} {vt100_inst/rv_v_d[5]} {vt100_inst/rv_v_d[6]} {vt100_inst/rv_v_d[7]} {vt100_inst/rv_v_d[8]} {vt100_inst/rv_v_d[9]} {vt100_inst/rv_v_d[10]} {vt100_inst/rv_v_d[11]} {vt100_inst/rv_v_d[12]} {vt100_inst/rv_v_d[13]} {vt100_inst/rv_v_d[14]} {vt100_inst/rv_v_d[15]} {vt100_inst/rv_v_d[16]} {vt100_inst/rv_v_d[17]} {vt100_inst/rv_v_d[18]} {vt100_inst/rv_v_d[19]} {vt100_inst/rv_v_d[20]} {vt100_inst/rv_v_d[21]} {vt100_inst/rv_v_d[22]} {vt100_inst/rv_v_d[23]} {vt100_inst/rv_v_d[24]} {vt100_inst/rv_v_d[25]} {vt100_inst/rv_v_d[26]} {vt100_inst/rv_v_d[27]} {vt100_inst/rv_v_d[28]} {vt100_inst/rv_v_d[29]} {vt100_inst/rv_v_d[30]} {vt100_inst/rv_v_d[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 16 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {fb_d[0]} {fb_d[1]} {fb_d[2]} {fb_d[3]} {fb_d[4]} {fb_d[5]} {fb_d[6]} {fb_d[7]} {fb_d[8]} {fb_d[9]} {fb_d[10]} {fb_d[11]} {fb_d[12]} {fb_d[13]} {fb_d[14]} {fb_d[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 32 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {vt100_inst/riscv_vt100_controller/pc[0]} {vt100_inst/riscv_vt100_controller/pc[1]} {vt100_inst/riscv_vt100_controller/pc[2]} {vt100_inst/riscv_vt100_controller/pc[3]} {vt100_inst/riscv_vt100_controller/pc[4]} {vt100_inst/riscv_vt100_controller/pc[5]} {vt100_inst/riscv_vt100_controller/pc[6]} {vt100_inst/riscv_vt100_controller/pc[7]} {vt100_inst/riscv_vt100_controller/pc[8]} {vt100_inst/riscv_vt100_controller/pc[9]} {vt100_inst/riscv_vt100_controller/pc[10]} {vt100_inst/riscv_vt100_controller/pc[11]} {vt100_inst/riscv_vt100_controller/pc[12]} {vt100_inst/riscv_vt100_controller/pc[13]} {vt100_inst/riscv_vt100_controller/pc[14]} {vt100_inst/riscv_vt100_controller/pc[15]} {vt100_inst/riscv_vt100_controller/pc[16]} {vt100_inst/riscv_vt100_controller/pc[17]} {vt100_inst/riscv_vt100_controller/pc[18]} {vt100_inst/riscv_vt100_controller/pc[19]} {vt100_inst/riscv_vt100_controller/pc[20]} {vt100_inst/riscv_vt100_controller/pc[21]} {vt100_inst/riscv_vt100_controller/pc[22]} {vt100_inst/riscv_vt100_controller/pc[23]} {vt100_inst/riscv_vt100_controller/pc[24]} {vt100_inst/riscv_vt100_controller/pc[25]} {vt100_inst/riscv_vt100_controller/pc[26]} {vt100_inst/riscv_vt100_controller/pc[27]} {vt100_inst/riscv_vt100_controller/pc[28]} {vt100_inst/riscv_vt100_controller/pc[29]} {vt100_inst/riscv_vt100_controller/pc[30]} {vt100_inst/riscv_vt100_controller/pc[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list fb_we]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list vt100_inst/rv_v_we]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list vt100_inst/uart_vt100_rx/rx_r]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list vt100_inst/rxnew]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
