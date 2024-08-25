`timescale 1ps/1ps
`include "quasi.vh"

module clocking_wizard_clk_wiz 

 (// Clock in ports
  // Clock out ports
  output        clk_main,
  output        clk_mem,
  output        clk_hdmi_25,
  output        clk_hdmi_2x,
  output        clk_mem_n,
  output        clk_ref,
  // Status and control signals
  input         reset,
  output        locked,
  input         clk_in1
 );
  // Input buffering
  //------------------------------------
wire clk_in1_clocking_wizard;
wire clk_in2_clocking_wizard;
  IBUF clkin1_ibufg
   (.O (clk_in1_clocking_wizard),
    .I (clk_in1));

  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        clk_main_clocking_wizard;
  wire        clk_mem_clocking_wizard;
  wire        clk_hdmi_25_clocking_wizard;
  wire        clk_hdmi_2x_clocking_wizard;
  wire        clk_mem_n_clocking_wizard;
  wire        clk_ref_clocking_wizard;
  wire        clk_out7_clocking_wizard;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clocking_wizard;
  wire        clkfbout_buf_clocking_wizard;
  wire        clkfboutb_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;
  wire        reset_high;

  PLLE2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
`ifdef OPENXC7
    .COMPENSATION         ("INTERNAL"),
`else
	.COMPENSATION         ("ZHOLD"),
`endif
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT        (20),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE       (16),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT1_DIVIDE       (4),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT2_DIVIDE       (40),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT3_DIVIDE       (20),
    .CLKOUT3_PHASE        (0.000),
    .CLKOUT3_DUTY_CYCLE   (0.500),
    .CLKOUT4_DIVIDE       (4),
    .CLKOUT4_PHASE        (90.000),
    .CLKOUT4_DUTY_CYCLE   (0.500),
    .CLKOUT5_DIVIDE       (5),
    .CLKOUT5_PHASE        (0.000),
    .CLKOUT5_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (10.000))
  plle2_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clocking_wizard),
    .CLKOUT0             (clk_main_clocking_wizard),
    .CLKOUT1             (clk_mem_clocking_wizard),
    .CLKOUT2             (clk_hdmi_25_clocking_wizard),
    .CLKOUT3             (clk_hdmi_2x_clocking_wizard),
    .CLKOUT4             (clk_mem_n_clocking_wizard),
    .CLKOUT5             (clk_ref_clocking_wizard),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clocking_wizard),
    .CLKIN1              (clk_in1_clocking_wizard),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Other control and status signals
    .LOCKED              (locked_int),
    .PWRDWN              (1'b0),
    .RST                 (reset_high));
  assign reset_high = reset; 

  assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

  BUFG clkf_buf
   (.O (clkfbout_buf_clocking_wizard),
    .I (clkfbout_clocking_wizard));

  BUFG clkout1_buf
   (.O   (clk_main),
    .I   (clk_main_clocking_wizard));


  BUFG clkout2_buf
   (.O   (clk_mem),
    .I   (clk_mem_clocking_wizard));

  BUFG clkout3_buf
   (.O   (clk_hdmi_25),
    .I   (clk_hdmi_25_clocking_wizard));

  BUFG clkout4_buf
   (.O   (clk_hdmi_2x),
    .I   (clk_hdmi_2x_clocking_wizard));

  BUFG clkout5_buf
   (.O   (clk_mem_n),
    .I   (clk_mem_n_clocking_wizard));

  BUFG clkout6_buf
   (.O   (clk_ref),
    .I   (clk_ref_clocking_wizard));

endmodule
