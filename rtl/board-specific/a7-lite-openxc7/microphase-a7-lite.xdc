## Clock Signal
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports sysclk]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} -add [get_ports sysclk]


## LEDs
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {led[1]}]

## Buttons
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN W1 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]

## HDMI out
#set_property -dict { PACKAGE_PIN AA4   IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_cec }] #IO_L11N_T1_SRCC_34 Sch=hdmi_tx_cec
set_property -dict {PACKAGE_PIN L20 IOSTANDARD TMDS_33} [get_ports TMDSn_clock]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD TMDS_33} [get_ports TMDSp_clock]
#set_property -dict { PACKAGE_PIN AB13  IOSTANDARD LVCMOS25 } [get_ports { hdmi_tx_hpd }] #IO_L3N_T0_DQS_13 Sch=hdmi_tx_hpd
#set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_rscl }] #IO_L6P_T0_34 Sch=hdmi_tx_rscl
#set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_rsda }] #IO_L6N_T0_VREF_34 Sch=hdmi_tx_rsda
set_property -dict {PACKAGE_PIN K22 IOSTANDARD TMDS_33} [get_ports {TMDSn[0]}]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD TMDS_33} [get_ports {TMDSp[0]}]
set_property -dict {PACKAGE_PIN J21 IOSTANDARD TMDS_33} [get_ports {TMDSn[1]}]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD TMDS_33} [get_ports {TMDSp[1]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD TMDS_33} [get_ports {TMDSn[2]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD TMDS_33} [get_ports {TMDSp[2]}]

## UART
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports uart_rx]


## SD card
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports sd_sck]
#set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports sd_ncd]
set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS33} [get_ports sd_cmd]
set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS33} [get_ports sd_dat0]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports sd_dat1]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS33} [get_ports sd_dat2]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS33} [get_ports sd_dat3]
#set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 } [get_ports { sd_reset }] #IO_L11N_T1_SRCC_14 Sch=sd_reset


## Configuration options, can be used for all designs
#set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property CFGBVS VCCO [current_design]

#set_property SLEW FAST [get_ports {ddr3_dq[0]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[0]}]
#set_property PACKAGE_PIN G2 [get_ports {ddr3_dq[0]}]

#set_property SLEW FAST [get_ports {ddr3_dq[1]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[1]}]
#set_property PACKAGE_PIN H4 [get_ports {ddr3_dq[1]}]

#set_property SLEW FAST [get_ports {ddr3_dq[2]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[2]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[2]}]
#set_property PACKAGE_PIN H5 [get_ports {ddr3_dq[2]}]

#set_property SLEW FAST [get_ports {ddr3_dq[3]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[3]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[3]}]
#set_property PACKAGE_PIN J1 [get_ports {ddr3_dq[3]}]

#set_property SLEW FAST [get_ports {ddr3_dq[4]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[4]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[4]}]
#set_property PACKAGE_PIN K1 [get_ports {ddr3_dq[4]}]

#set_property SLEW FAST [get_ports {ddr3_dq[5]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[5]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[5]}]
#set_property PACKAGE_PIN H3 [get_ports {ddr3_dq[5]}]

#set_property SLEW FAST [get_ports {ddr3_dq[6]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[6]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[6]}]
#set_property PACKAGE_PIN H2 [get_ports {ddr3_dq[6]}]

#set_property SLEW FAST [get_ports {ddr3_dq[7]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[7]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[7]}]
#set_property PACKAGE_PIN J5 [get_ports {ddr3_dq[7]}]

#set_property SLEW FAST [get_ports {ddr3_dq[8]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[8]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[8]}]
#set_property PACKAGE_PIN E3 [get_ports {ddr3_dq[8]}]

#set_property SLEW FAST [get_ports {ddr3_dq[9]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[9]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[9]}]
#set_property PACKAGE_PIN B2 [get_ports {ddr3_dq[9]}]

#set_property SLEW FAST [get_ports {ddr3_dq[10]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[10]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[10]}]
#set_property PACKAGE_PIN F3 [get_ports {ddr3_dq[10]}]

#set_property SLEW FAST [get_ports {ddr3_dq[11]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[11]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[11]}]
#set_property PACKAGE_PIN D2 [get_ports {ddr3_dq[11]}]

#set_property SLEW FAST [get_ports {ddr3_dq[12]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[12]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[12]}]
#set_property PACKAGE_PIN C2 [get_ports {ddr3_dq[12]}]

#set_property SLEW FAST [get_ports {ddr3_dq[13]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[13]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[13]}]
#set_property PACKAGE_PIN A1 [get_ports {ddr3_dq[13]}]

#set_property SLEW FAST [get_ports {ddr3_dq[14]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[14]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[14]}]
#set_property PACKAGE_PIN E2 [get_ports {ddr3_dq[14]}]

#set_property SLEW FAST [get_ports {ddr3_dq[15]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[15]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[15]}]
#set_property PACKAGE_PIN B1 [get_ports {ddr3_dq[15]}]

#set_property SLEW FAST [get_ports {ddr3_addr[14]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[14]}]
#set_property PACKAGE_PIN P6 [get_ports {ddr3_addr[14]}]

#set_property SLEW FAST [get_ports {ddr3_addr[13]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[13]}]
#set_property PACKAGE_PIN P2 [get_ports {ddr3_addr[13]}]

#set_property SLEW FAST [get_ports {ddr3_addr[12]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[12]}]
#set_property PACKAGE_PIN N4 [get_ports {ddr3_addr[12]}]

#set_property SLEW FAST [get_ports {ddr3_addr[11]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[11]}]
#set_property PACKAGE_PIN N5 [get_ports {ddr3_addr[11]}]

#set_property SLEW FAST [get_ports {ddr3_addr[10]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[10]}]
#set_property PACKAGE_PIN L5 [get_ports {ddr3_addr[10]}]

#set_property SLEW FAST [get_ports {ddr3_addr[9]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[9]}]
#set_property PACKAGE_PIN R1 [get_ports {ddr3_addr[9]}]

#set_property SLEW FAST [get_ports {ddr3_addr[8]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[8]}]
#set_property PACKAGE_PIN M6 [get_ports {ddr3_addr[8]}]

#set_property SLEW FAST [get_ports {ddr3_addr[7]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[7]}]
#set_property PACKAGE_PIN N2 [get_ports {ddr3_addr[7]}]

#set_property SLEW FAST [get_ports {ddr3_addr[6]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[6]}]
#set_property PACKAGE_PIN N3 [get_ports {ddr3_addr[6]}]

#set_property SLEW FAST [get_ports {ddr3_addr[5]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[5]}]
#set_property PACKAGE_PIN P1 [get_ports {ddr3_addr[5]}]

#set_property SLEW FAST [get_ports {ddr3_addr[4]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[4]}]
#set_property PACKAGE_PIN L6 [get_ports {ddr3_addr[4]}]

#set_property SLEW FAST [get_ports {ddr3_addr[3]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[3]}]
#set_property PACKAGE_PIN M1 [get_ports {ddr3_addr[3]}]

#set_property SLEW FAST [get_ports {ddr3_addr[2]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[2]}]
#set_property PACKAGE_PIN M3 [get_ports {ddr3_addr[2]}]

#set_property SLEW FAST [get_ports {ddr3_addr[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[1]}]
#set_property PACKAGE_PIN M5 [get_ports {ddr3_addr[1]}]

#set_property SLEW FAST [get_ports {ddr3_addr[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[0]}]
#set_property PACKAGE_PIN M2 [get_ports {ddr3_addr[0]}]

#set_property SLEW FAST [get_ports {ddr3_ba[2]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[2]}]
#set_property PACKAGE_PIN L4 [get_ports {ddr3_ba[2]}]

#set_property SLEW FAST [get_ports {ddr3_ba[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[1]}]
#set_property PACKAGE_PIN K6 [get_ports {ddr3_ba[1]}]

#set_property SLEW FAST [get_ports {ddr3_ba[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[0]}]
#set_property PACKAGE_PIN L3 [get_ports {ddr3_ba[0]}]

#set_property SLEW FAST [get_ports ddr3_ras_n]
#set_property IOSTANDARD SSTL15 [get_ports ddr3_ras_n]
#set_property PACKAGE_PIN J4 [get_ports ddr3_ras_n]

#set_property SLEW FAST [get_ports ddr3_cas_n]
#set_property IOSTANDARD SSTL15 [get_ports ddr3_cas_n]
#set_property PACKAGE_PIN K3 [get_ports ddr3_cas_n]

#set_property SLEW FAST [get_ports ddr3_we_n]
#set_property IOSTANDARD SSTL15 [get_ports ddr3_we_n]
#set_property PACKAGE_PIN L1 [get_ports ddr3_we_n]

#set_property SLEW FAST [get_ports ddr3_reset_n]
#set_property IOSTANDARD LVCMOS15 [get_ports ddr3_reset_n]
#set_property PACKAGE_PIN G1 [get_ports ddr3_reset_n]

#set_property SLEW FAST [get_ports {ddr3_cke}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cke}]
#set_property PACKAGE_PIN J6 [get_ports {ddr3_cke}]

#set_property SLEW FAST [get_ports {ddr3_odt}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_odt}]
#set_property PACKAGE_PIN K4 [get_ports {ddr3_odt}]

#set_property SLEW FAST [get_ports {ddr3_dm[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[0]}]
#set_property PACKAGE_PIN G3 [get_ports {ddr3_dm[0]}]

#set_property SLEW FAST [get_ports {ddr3_dm[1]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[1]}]
#set_property PACKAGE_PIN F1 [get_ports {ddr3_dm[1]}]

#set_property SLEW FAST [get_ports {ddr3_dqs_p[0]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_p[0]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[0]}]

#set_property SLEW FAST [get_ports {ddr3_dqs_n[0]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_n[0]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[0]}]
#set_property PACKAGE_PIN K2 [get_ports {ddr3_dqs_p[0]}]
#set_property PACKAGE_PIN J2 [get_ports {ddr3_dqs_n[0]}]

#set_property SLEW FAST [get_ports {ddr3_dqs_p[1]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_p[1]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[1]}]

#set_property SLEW FAST [get_ports {ddr3_dqs_n[1]}]
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_n[1]}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[1]}]
#set_property PACKAGE_PIN E1 [get_ports {ddr3_dqs_p[1]}]
#set_property PACKAGE_PIN D1 [get_ports {ddr3_dqs_n[1]}]

#set_property SLEW FAST [get_ports {ddr3_ck_p}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_p}]

#set_property SLEW FAST [get_ports {ddr3_ck_n}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_n}]
#set_property PACKAGE_PIN P5 [get_ports {ddr3_ck_p}]
#set_property PACKAGE_PIN P4 [get_ports {ddr3_ck_n}]

set_property SLEW FAST [get_ports {ddr3_dq[0]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN B2 [get_ports {ddr3_dq[0]}]
# PadFunction: IO_L2P_T0_AD12P_35
set_property SLEW FAST [get_ports {ddr3_dq[1]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN F1 [get_ports {ddr3_dq[1]}]
# PadFunction: IO_L2N_T0_AD12N_35
set_property SLEW FAST [get_ports {ddr3_dq[2]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN B1 [get_ports {ddr3_dq[2]}]
# PadFunction: IO_L4P_T0_35
set_property SLEW FAST [get_ports {ddr3_dq[3]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN D2 [get_ports {ddr3_dq[3]}]
# PadFunction: IO_L4N_T0_35
set_property SLEW FAST [get_ports {ddr3_dq[4]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN C2 [get_ports {ddr3_dq[4]}]
# PadFunction: IO_L5P_T0_AD13P_35
set_property SLEW FAST [get_ports {ddr3_dq[5]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN F3 [get_ports {ddr3_dq[5]}]
# PadFunction: IO_L5N_T0_AD13N_35
set_property SLEW FAST [get_ports {ddr3_dq[6]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN A1 [get_ports {ddr3_dq[6]}]
# PadFunction: IO_L6P_T0_35
set_property SLEW FAST [get_ports {ddr3_dq[7]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN G1 [get_ports {ddr3_dq[7]}]
# PadFunction: IO_L1N_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[8]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[8]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN J5 [get_ports {ddr3_dq[8]}]
# PadFunction: IO_L2P_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[9]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[9]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN G2 [get_ports {ddr3_dq[9]}]
# PadFunction: IO_L2N_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[10]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[10]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN K1 [get_ports {ddr3_dq[10]}]
# PadFunction: IO_L4P_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[11]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[11]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN G3 [get_ports {ddr3_dq[11]}]
# PadFunction: IO_L4N_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[12]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[12]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN H2 [get_ports {ddr3_dq[12]}]
# PadFunction: IO_L5P_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[13]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[13]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN H5 [get_ports {ddr3_dq[13]}]
# PadFunction: IO_L5N_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[14]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[14]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN J1 [get_ports {ddr3_dq[14]}]
# PadFunction: IO_L6P_T0_34
set_property SLEW FAST [get_ports {ddr3_dq[15]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dq[15]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[15]}]
set_property PACKAGE_PIN H4 [get_ports {ddr3_dq[15]}]
# PadFunction: IO_L13P_T2_MRCC_35
set_property SLEW FAST [get_ports {ddr3_addr[14]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[14]}]
set_property PACKAGE_PIN N5 [get_ports {ddr3_addr[14]}]
# PadFunction: IO_L13N_T2_MRCC_35
set_property SLEW FAST [get_ports {ddr3_addr[13]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[13]}]
set_property PACKAGE_PIN L5 [get_ports {ddr3_addr[13]}]
# PadFunction: IO_L14P_T2_SRCC_35
set_property SLEW FAST [get_ports {ddr3_addr[12]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN L4 [get_ports {ddr3_addr[12]}]
# PadFunction: IO_L14N_T2_SRCC_35
set_property SLEW FAST [get_ports {ddr3_addr[11]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN P6 [get_ports {ddr3_addr[11]}]
# PadFunction: IO_L15P_T2_DQS_35
set_property SLEW FAST [get_ports {ddr3_addr[10]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN M2 [get_ports {ddr3_addr[10]}]
# PadFunction: IO_L15N_T2_DQS_35
set_property SLEW FAST [get_ports {ddr3_addr[9]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN L1 [get_ports {ddr3_addr[9]}]
# PadFunction: IO_L16P_T2_35
set_property SLEW FAST [get_ports {ddr3_addr[8]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN P2 [get_ports {ddr3_addr[8]}]
# PadFunction: IO_L16N_T2_35
set_property SLEW FAST [get_ports {ddr3_addr[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN K6 [get_ports {ddr3_addr[7]}]
# PadFunction: IO_L17P_T2_35
set_property SLEW FAST [get_ports {ddr3_addr[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN N2 [get_ports {ddr3_addr[6]}]
# PadFunction: IO_L17N_T2_35
set_property SLEW FAST [get_ports {ddr3_addr[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN J6 [get_ports {ddr3_addr[5]}]
# PadFunction: IO_L18P_T2_35
set_property SLEW FAST [get_ports {ddr3_addr[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN M5 [get_ports {ddr3_addr[4]}]
# PadFunction: IO_L18N_T2_35
set_property SLEW FAST [get_ports {ddr3_addr[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN K4 [get_ports {ddr3_addr[3]}]
# PadFunction: IO_L7P_T1_AD6P_35
set_property SLEW FAST [get_ports {ddr3_addr[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN K3 [get_ports {ddr3_addr[2]}]
# PadFunction: IO_L7N_T1_AD6N_35
set_property SLEW FAST [get_ports {ddr3_addr[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN M6 [get_ports {ddr3_addr[1]}]
# PadFunction: IO_L8P_T1_AD14P_35
set_property SLEW FAST [get_ports {ddr3_addr[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN P1 [get_ports {ddr3_addr[0]}]
# PadFunction: IO_L8N_T1_AD14N_35
set_property SLEW FAST [get_ports {ddr3_ba[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[2]}]
set_property PACKAGE_PIN M1 [get_ports {ddr3_ba[2]}]
# PadFunction: IO_L9P_T1_DQS_AD7P_35
set_property SLEW FAST [get_ports {ddr3_ba[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN R1 [get_ports {ddr3_ba[1]}]
# PadFunction: IO_L9N_T1_DQS_AD7N_35
set_property SLEW FAST [get_ports {ddr3_ba[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN J4 [get_ports {ddr3_ba[0]}]
# PadFunction: IO_L10P_T1_AD15P_35
set_property SLEW FAST [get_ports ddr3_ras_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_ras_n]
set_property PACKAGE_PIN M3 [get_ports ddr3_ras_n]
# PadFunction: IO_L10N_T1_AD15N_35
set_property SLEW FAST [get_ports ddr3_cas_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_cas_n]
set_property PACKAGE_PIN N3 [get_ports ddr3_cas_n]
# PadFunction: IO_L11P_T1_SRCC_35
set_property SLEW FAST [get_ports ddr3_we_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_we_n]
set_property PACKAGE_PIN L6 [get_ports ddr3_we_n]
# PadFunction: IO_L6N_T0_VREF_35
set_property SLEW FAST [get_ports ddr3_reset_n]
set_property IOSTANDARD LVCMOS15 [get_ports ddr3_reset_n]
set_property PACKAGE_PIN F4 [get_ports ddr3_reset_n]
# PadFunction: IO_L19P_T3_35
set_property SLEW FAST [get_ports ddr3_cke]
set_property IOSTANDARD SSTL15 [get_ports ddr3_cke]
set_property PACKAGE_PIN N4 [get_ports ddr3_cke]
# PadFunction: IO_L19N_T3_VREF_35
set_property SLEW FAST [get_ports ddr3_odt]
set_property IOSTANDARD SSTL15 [get_ports ddr3_odt]
set_property PACKAGE_PIN L3 [get_ports ddr3_odt]
# PadFunction: IO_L11N_T1_SRCC_35
#set_property SLEW FAST [get_ports {ddr3_cs_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cs_n}]
#set_property PACKAGE_PIN F4 [get_ports {ddr3_cs_n}]
# PadFunction: IO_L1P_T0_AD4P_35
set_property SLEW FAST [get_ports {ddr3_dm[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN E2 [get_ports {ddr3_dm[0]}]
# PadFunction: IO_L1P_T0_34
set_property SLEW FAST [get_ports {ddr3_dm[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[1]}]
set_property PACKAGE_PIN H3 [get_ports {ddr3_dm[1]}]
# PadFunction: IO_L3P_T0_DQS_AD5P_35
set_property SLEW FAST [get_ports {ddr3_dqs_p[0]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_p[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[0]}]
# PadFunction: IO_L3N_T0_DQS_AD5N_35
set_property SLEW FAST [get_ports {ddr3_dqs_n[0]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_n[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN E1 [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN D1 [get_ports {ddr3_dqs_n[0]}]
# PadFunction: IO_L3P_T0_DQS_34
set_property SLEW FAST [get_ports {ddr3_dqs_p[1]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_p[1]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[1]}]
# PadFunction: IO_L3N_T0_DQS_34
set_property SLEW FAST [get_ports {ddr3_dqs_n[1]}]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {ddr3_dqs_n[1]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[1]}]
set_property PACKAGE_PIN K2 [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN J2 [get_ports {ddr3_dqs_n[1]}]
# PadFunction: IO_L21P_T3_DQS_35
set_property SLEW FAST [get_ports ddr3_ck_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports ddr3_ck_p]
# PadFunction: IO_L21N_T3_DQS_35
set_property SLEW FAST [get_ports ddr3_ck_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports ddr3_ck_n]
set_property PACKAGE_PIN P5 [get_ports ddr3_ck_p]
set_property PACKAGE_PIN P4 [get_ports ddr3_ck_n]
