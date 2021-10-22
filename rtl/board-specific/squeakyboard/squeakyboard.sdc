#create_clock -period 20.000 [get_nets sysclk]
#create_generated_clock -name c62d5 -source [get_pins clocking_xc7_inst/clk1_62d5] -divide_by 16 -multiply_by 20 -add -master_clock sysclk [get_pins clocking_xc7_inst/clk1_62d5]
#create_generated_clock -name c125 -source [get_pins clocking_xc7_inst/clk2_125] -divide_by 8 -multiply_by 20 -add -master_clock sysclk [get_pins clocking_xc7_inst/clk2_125]
#set_property PHASESHIFT_MODE WAVEFORM [get_cells -hierarchical *adv*]
create_clock -period 20 sysclk
create_clock -period 16 clk_main
create_clock -period 8 clk_mem
#create_clock -period 40 clk_hdmi_25
#create_clock -period 4 clk_hdmi_250
#create_clock -period 20 clk_2x
