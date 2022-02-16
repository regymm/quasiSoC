## .xdc file for SqueakyBoard https://github.com/regymm/squeakyboard

## sysclk
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports sysclk]
create_clock -period 20.000 [get_nets sysclk]
set_property PHASESHIFT_MODE WAVEFORM [get_cells -hierarchical *adv*]
#create_generated_clock -name c62d5 -source [get_pins clocking_xc7_inst/clk1_62d5] -divide_by 16 -multiply_by 20 -add -master_clock sysclk [get_pins clocking_xc7_inst/clk1_62d5]
#create_generated_clock -name c125 -source [get_pins clocking_xc7_inst/clk2_125] -divide_by 8 -multiply_by 20 -add -master_clock sysclk [get_pins clocking_xc7_inst/clk2_125]

## buttons, switches and LEDs
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

# use a small resistor R71 R72 and use this to fix button unstable problem
set_property PULLUP true [get_ports {sw[0]}]
set_property PULLUP true [get_ports {sw[1]}]

## PMOD1
#set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports sd_cmd]
#set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports sd_sck]
#set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports sd_dat1]
#set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports sd_wp]
#set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports sd_dat3]
#set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports sd_dat0]
#set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports sd_dat2]
#set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports sd_ncd]

set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports p1p]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports p1n]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports p3p]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports p3n]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports p2p]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports p2n]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports p4p]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports p4n]

## PMOD2
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS33} [get_ports lcd_rs]; # 6
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports lcd_rd]; # 8
#set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports lcd_rs]; # 4
#set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports lcd_rst]; # 2
#set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports lcd_cs]; # 1
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports lcd_rst]; # 3
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports lcd_cs]; # 5
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports lcd_wr]; # 7
#
#set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS33} [get_ports p5p] # 6
#set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports p5n] # 8
#set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports io1] # 4
#set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports io2] # 2
#set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports io3] # 1
#set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports io4] # 3
#set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports io5] # 5
#set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports io6] # 7

# PMOD3
#set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports uart_tx_2]
#set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports uart_rx_2]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports lcd_d[0]]; # 1
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports lcd_d[1]]; # 2
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports lcd_d[7]]; # 3 ..
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports lcd_d[6]]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports lcd_d[4]]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports lcd_d[5]]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports lcd_d[2]]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports lcd_d[3]]; # 8
#set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports b31] # 1
#set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports b24] # 2
#set_property -dict {PACKAGE_PIN  IOSTANDARD LVCMOS33} [get_ports b21] # 3 ..
#set_property -dict {PACKAGE_PIN  IOSTANDARD LVCMOS33} [get_ports b34]
#set_property -dict {PACKAGE_PIN  IOSTANDARD LVCMOS33} [get_ports b32]
#set_property -dict {PACKAGE_PIN  IOSTANDARD LVCMOS33} [get_ports b23]
#set_property -dict {PACKAGE_PIN  IOSTANDARD LVCMOS33} [get_ports b22]
#set_property -dict {PACKAGE_PIN  IOSTANDARD LVCMOS33} [get_ports b33] # 8

## PMOD4+
#set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports q1p]
#set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports q1n]
#set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports q2p]
#set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports q2n]
#set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports q3p]
#set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports q3n]
#set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports q4p]
#set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports q4n]

# W5500-Lite
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports eth_scsn]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports eth_sclk]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports eth_mosi]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports eth_miso]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD LVCMOS33} [get_ports eth_rstn]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports eth_intn]

# HDMI
set_property -dict {PACKAGE_PIN W20 IOSTANDARD TMDS_33} [get_ports TMDSn_clock]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD TMDS_33} [get_ports TMDSp_clock]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD TMDS_33} [get_ports {TMDSn[0]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD TMDS_33} [get_ports {TMDSp[0]}]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports {TMDSn[1]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports {TMDSp[1]}]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD TMDS_33} [get_ports {TMDSn[2]}]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD TMDS_33} [get_ports {TMDSp[2]}]

# UART
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports uart_tx]

# CH375b
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports ch375_tx]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports ch375_rx]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports ch375_nint]
#set_property PULLUP TRUE [get_ports ch375_tx]

# USB PS2
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports ps2_clk]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports ps2_data]
#set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports ps2_clk]
#set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports ps2_data]
set_property PULLUP true [get_ports ps2_clk]
set_property PULLUP true [get_ports ps2_data]

# SD Card
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports sd_ncd]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports sd_dat0]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports sd_dat1]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports sd_dat2]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports sd_dat3]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports sd_cmd]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports sd_sck]

# PSRAM 1
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports psram_ce]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports psram_mosi]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports psram_miso]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports psram_sio2]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports psram_sio3]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports psram_sclk]





