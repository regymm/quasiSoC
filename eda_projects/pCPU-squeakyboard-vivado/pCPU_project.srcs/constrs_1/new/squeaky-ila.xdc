

connect_debug_port u_ila_0/clk [get_nets [list clock_wizard_inst/inst/clk_main]]




















create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clocking_xc7_inst/clk1_62d5]]
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
connect_debug_port u_ila_0/probe2 [get_nets [list {mmapper_inst/spo[0]} {mmapper_inst/spo[1]} {mmapper_inst/spo[2]} {mmapper_inst/spo[3]} {mmapper_inst/spo[4]} {mmapper_inst/spo[5]} {mmapper_inst/spo[6]} {mmapper_inst/spo[7]} {mmapper_inst/spo[8]} {mmapper_inst/spo[9]} {mmapper_inst/spo[10]} {mmapper_inst/spo[11]} {mmapper_inst/spo[12]} {mmapper_inst/spo[13]} {mmapper_inst/spo[14]} {mmapper_inst/spo[15]} {mmapper_inst/spo[16]} {mmapper_inst/spo[17]} {mmapper_inst/spo[18]} {mmapper_inst/spo[19]} {mmapper_inst/spo[20]} {mmapper_inst/spo[21]} {mmapper_inst/spo[22]} {mmapper_inst/spo[23]} {mmapper_inst/spo[24]} {mmapper_inst/spo[25]} {mmapper_inst/spo[26]} {mmapper_inst/spo[27]} {mmapper_inst/spo[28]} {mmapper_inst/spo[29]} {mmapper_inst/spo[30]} {mmapper_inst/spo[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {timer_inst/mtimel[0]} {timer_inst/mtimel[1]} {timer_inst/mtimel[2]} {timer_inst/mtimel[3]} {timer_inst/mtimel[4]} {timer_inst/mtimel[5]} {timer_inst/mtimel[6]} {timer_inst/mtimel[7]} {timer_inst/mtimel[8]} {timer_inst/mtimel[9]} {timer_inst/mtimel[10]} {timer_inst/mtimel[11]} {timer_inst/mtimel[12]} {timer_inst/mtimel[13]} {timer_inst/mtimel[14]} {timer_inst/mtimel[15]} {timer_inst/mtimel[16]} {timer_inst/mtimel[17]} {timer_inst/mtimel[18]} {timer_inst/mtimel[19]} {timer_inst/mtimel[20]} {timer_inst/mtimel[21]} {timer_inst/mtimel[22]} {timer_inst/mtimel[23]} {timer_inst/mtimel[24]} {timer_inst/mtimel[25]} {timer_inst/mtimel[26]} {timer_inst/mtimel[27]} {timer_inst/mtimel[28]} {timer_inst/mtimel[29]} {timer_inst/mtimel[30]} {timer_inst/mtimel[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 32 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {mmapper_inst/d[0]} {mmapper_inst/d[1]} {mmapper_inst/d[2]} {mmapper_inst/d[3]} {mmapper_inst/d[4]} {mmapper_inst/d[5]} {mmapper_inst/d[6]} {mmapper_inst/d[7]} {mmapper_inst/d[8]} {mmapper_inst/d[9]} {mmapper_inst/d[10]} {mmapper_inst/d[11]} {mmapper_inst/d[12]} {mmapper_inst/d[13]} {mmapper_inst/d[14]} {mmapper_inst/d[15]} {mmapper_inst/d[16]} {mmapper_inst/d[17]} {mmapper_inst/d[18]} {mmapper_inst/d[19]} {mmapper_inst/d[20]} {mmapper_inst/d[21]} {mmapper_inst/d[22]} {mmapper_inst/d[23]} {mmapper_inst/d[24]} {mmapper_inst/d[25]} {mmapper_inst/d[26]} {mmapper_inst/d[27]} {mmapper_inst/d[28]} {mmapper_inst/d[29]} {mmapper_inst/d[30]} {mmapper_inst/d[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 32 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {riscv_multicyc_inst/privilege_inst/mstatus[0]} {riscv_multicyc_inst/privilege_inst/mstatus[1]} {riscv_multicyc_inst/privilege_inst/mstatus[2]} {riscv_multicyc_inst/privilege_inst/mstatus[3]} {riscv_multicyc_inst/privilege_inst/mstatus[4]} {riscv_multicyc_inst/privilege_inst/mstatus[5]} {riscv_multicyc_inst/privilege_inst/mstatus[6]} {riscv_multicyc_inst/privilege_inst/mstatus[7]} {riscv_multicyc_inst/privilege_inst/mstatus[8]} {riscv_multicyc_inst/privilege_inst/mstatus[9]} {riscv_multicyc_inst/privilege_inst/mstatus[10]} {riscv_multicyc_inst/privilege_inst/mstatus[11]} {riscv_multicyc_inst/privilege_inst/mstatus[12]} {riscv_multicyc_inst/privilege_inst/mstatus[13]} {riscv_multicyc_inst/privilege_inst/mstatus[14]} {riscv_multicyc_inst/privilege_inst/mstatus[15]} {riscv_multicyc_inst/privilege_inst/mstatus[16]} {riscv_multicyc_inst/privilege_inst/mstatus[17]} {riscv_multicyc_inst/privilege_inst/mstatus[18]} {riscv_multicyc_inst/privilege_inst/mstatus[19]} {riscv_multicyc_inst/privilege_inst/mstatus[20]} {riscv_multicyc_inst/privilege_inst/mstatus[21]} {riscv_multicyc_inst/privilege_inst/mstatus[22]} {riscv_multicyc_inst/privilege_inst/mstatus[23]} {riscv_multicyc_inst/privilege_inst/mstatus[24]} {riscv_multicyc_inst/privilege_inst/mstatus[25]} {riscv_multicyc_inst/privilege_inst/mstatus[26]} {riscv_multicyc_inst/privilege_inst/mstatus[27]} {riscv_multicyc_inst/privilege_inst/mstatus[28]} {riscv_multicyc_inst/privilege_inst/mstatus[29]} {riscv_multicyc_inst/privilege_inst/mstatus[30]} {riscv_multicyc_inst/privilege_inst/mstatus[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 32 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {timer_inst/mtimecmpl[0]} {timer_inst/mtimecmpl[1]} {timer_inst/mtimecmpl[2]} {timer_inst/mtimecmpl[3]} {timer_inst/mtimecmpl[4]} {timer_inst/mtimecmpl[5]} {timer_inst/mtimecmpl[6]} {timer_inst/mtimecmpl[7]} {timer_inst/mtimecmpl[8]} {timer_inst/mtimecmpl[9]} {timer_inst/mtimecmpl[10]} {timer_inst/mtimecmpl[11]} {timer_inst/mtimecmpl[12]} {timer_inst/mtimecmpl[13]} {timer_inst/mtimecmpl[14]} {timer_inst/mtimecmpl[15]} {timer_inst/mtimecmpl[16]} {timer_inst/mtimecmpl[17]} {timer_inst/mtimecmpl[18]} {timer_inst/mtimecmpl[19]} {timer_inst/mtimecmpl[20]} {timer_inst/mtimecmpl[21]} {timer_inst/mtimecmpl[22]} {timer_inst/mtimecmpl[23]} {timer_inst/mtimecmpl[24]} {timer_inst/mtimecmpl[25]} {timer_inst/mtimecmpl[26]} {timer_inst/mtimecmpl[27]} {timer_inst/mtimecmpl[28]} {timer_inst/mtimecmpl[29]} {timer_inst/mtimecmpl[30]} {timer_inst/mtimecmpl[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 30 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {mmapper_inst/a[2]} {mmapper_inst/a[3]} {mmapper_inst/a[4]} {mmapper_inst/a[5]} {mmapper_inst/a[6]} {mmapper_inst/a[7]} {mmapper_inst/a[8]} {mmapper_inst/a[9]} {mmapper_inst/a[10]} {mmapper_inst/a[11]} {mmapper_inst/a[12]} {mmapper_inst/a[13]} {mmapper_inst/a[14]} {mmapper_inst/a[15]} {mmapper_inst/a[16]} {mmapper_inst/a[17]} {mmapper_inst/a[18]} {mmapper_inst/a[19]} {mmapper_inst/a[20]} {mmapper_inst/a[21]} {mmapper_inst/a[22]} {mmapper_inst/a[23]} {mmapper_inst/a[24]} {mmapper_inst/a[25]} {mmapper_inst/a[26]} {mmapper_inst/a[27]} {mmapper_inst/a[28]} {mmapper_inst/a[29]} {mmapper_inst/a[30]} {mmapper_inst/a[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 2 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {riscv_multicyc_inst/privilege_inst/state[0]} {riscv_multicyc_inst/privilege_inst/state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {riscv_multicyc_inst/privilege_inst/mepc[0]} {riscv_multicyc_inst/privilege_inst/mepc[1]} {riscv_multicyc_inst/privilege_inst/mepc[2]} {riscv_multicyc_inst/privilege_inst/mepc[3]} {riscv_multicyc_inst/privilege_inst/mepc[4]} {riscv_multicyc_inst/privilege_inst/mepc[5]} {riscv_multicyc_inst/privilege_inst/mepc[6]} {riscv_multicyc_inst/privilege_inst/mepc[7]} {riscv_multicyc_inst/privilege_inst/mepc[8]} {riscv_multicyc_inst/privilege_inst/mepc[9]} {riscv_multicyc_inst/privilege_inst/mepc[10]} {riscv_multicyc_inst/privilege_inst/mepc[11]} {riscv_multicyc_inst/privilege_inst/mepc[12]} {riscv_multicyc_inst/privilege_inst/mepc[13]} {riscv_multicyc_inst/privilege_inst/mepc[14]} {riscv_multicyc_inst/privilege_inst/mepc[15]} {riscv_multicyc_inst/privilege_inst/mepc[16]} {riscv_multicyc_inst/privilege_inst/mepc[17]} {riscv_multicyc_inst/privilege_inst/mepc[18]} {riscv_multicyc_inst/privilege_inst/mepc[19]} {riscv_multicyc_inst/privilege_inst/mepc[20]} {riscv_multicyc_inst/privilege_inst/mepc[21]} {riscv_multicyc_inst/privilege_inst/mepc[22]} {riscv_multicyc_inst/privilege_inst/mepc[23]} {riscv_multicyc_inst/privilege_inst/mepc[24]} {riscv_multicyc_inst/privilege_inst/mepc[25]} {riscv_multicyc_inst/privilege_inst/mepc[26]} {riscv_multicyc_inst/privilege_inst/mepc[27]} {riscv_multicyc_inst/privilege_inst/mepc[28]} {riscv_multicyc_inst/privilege_inst/mepc[29]} {riscv_multicyc_inst/privilege_inst/mepc[30]} {riscv_multicyc_inst/privilege_inst/mepc[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list cpu_eip]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list cpu_eip_reply]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list riscv_multicyc_inst/privilege_inst/int_pending]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list interrupt_unit_inst/int_reply]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list riscv_multicyc_inst/privilege_inst/interrupt]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list riscv_multicyc_inst/tip]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list mmapper_inst/we]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list riscv_multicyc_inst/privilege_inst/mode_reg_n_0]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_main]
