set_property -dict {PACKAGE_PIN D27 IOSTANDARD HSTL_II_18} [get_ports sysclk]
create_clock -period 20.000 -name clk_50m -waveform {0.000 5.000} -add [get_ports sysclk]

set_property -dict {PACKAGE_PIN W23 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports uart_tx]

set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN R24 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN C24 IOSTANDARD LVCMOS33} [get_ports {led[3]}]


##Buttons
set_property -dict {PACKAGE_PIN A23 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN B23 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]

# SDCard
set_property -dict {PACKAGE_PIN B29 IOSTANDARD LVCMOS33} [get_ports sd_dat3]
set_property -dict {PACKAGE_PIN B27 IOSTANDARD LVCMOS33} [get_ports sd_sck]
set_property -dict {PACKAGE_PIN C25 IOSTANDARD LVCMOS33} [get_ports sd_dat1]
set_property -dict {PACKAGE_PIN A27 IOSTANDARD LVCMOS33} [get_ports sd_dat2]
set_property -dict {PACKAGE_PIN C29 IOSTANDARD LVCMOS33} [get_ports sd_cmd]
set_property -dict {PACKAGE_PIN H30 IOSTANDARD LVCMOS33} [get_ports sd_dat0]
set_property -dict {PACKAGE_PIN B25 IOSTANDARD LVCMOS33} [get_ports sd_ncd]

# PSRAM is a shame on Kintex 7
set_property -dict {PACKAGE_PIN D23 IOSTANDARD LVCMOS33} [get_ports psram_ce]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports psram_miso]
# set_property -dict {PACKAGE_PIN W26 IOSTANDARD LVCMOS33} [get_ports psram_sio2]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33} [get_ports psram_sio2]
set_property -dict {PACKAGE_PIN A30 IOSTANDARD LVCMOS33} [get_ports psram_sio3]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports psram_sclk]
set_property -dict {PACKAGE_PIN B30 IOSTANDARD LVCMOS33} [get_ports psram_mosi]

##HDMI Tx
set_property -dict {PACKAGE_PIN G27 IOSTANDARD LVCMOS33} [get_ports TMDSn_clock]
set_property -dict {PACKAGE_PIN F26 IOSTANDARD LVCMOS33} [get_ports TMDSp_clock]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {TMDSn[0]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {TMDSp[0]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports {TMDSn[1]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports {TMDSp[1]}]
set_property -dict {PACKAGE_PIN G23 IOSTANDARD LVCMOS33} [get_ports {TMDSn[2]}]
set_property -dict {PACKAGE_PIN D24 IOSTANDARD LVCMOS33} [get_ports {TMDSp[2]}]

set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {m[0]}]
set_property -dict {PACKAGE_PIN H21 IOSTANDARD LVCMOS33} [get_ports {m[1]}]
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS33} [get_ports {m[2]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports {m[3]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {m[4]}]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports {m[5]}]
