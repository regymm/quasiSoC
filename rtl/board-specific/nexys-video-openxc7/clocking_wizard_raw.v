
// file: clocking_wizard.v
// 
// (c) Copyright 2008 - 2013 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_main____62.500______0.000______50.0______144.481_____98.575
// _clk_mem___250.000______0.000______50.0______110.209_____98.575
// clk_hdmi_25____25.000______0.000______50.0______175.402_____98.575
// clk_hdmi_2x____50.000______0.000______50.0______151.636_____98.575
// clk_mem_n___250.000_____90.000______50.0______110.209_____98.575
// _clk_ref___200.000______0.000______50.0______114.829_____98.575
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________100.000____________0.010

`timescale 1ps/1ps

(* CORE_GENERATION_INFO = "clocking_wizard,clk_wiz_v6_0_3_0_0,{component_name=clocking_wizard,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,enable_axi=0,feedback_source=FDBK_AUTO,PRIMITIVE=PLL,num_out_clk=6,clkin1_period=10.000,clkin2_period=10.000,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,feedback_type=SINGLE,CLOCK_MGR_TYPE=NA,manual_override=false}" *)

module clocking_wizard 
 (
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
 // Clock in ports
  input         clk_in1
 );

  clocking_wizard_clk_wiz inst
  (
  // Clock out ports  
  .clk_main(clk_main),
  .clk_mem(clk_mem),
  .clk_hdmi_25(clk_hdmi_25),
  .clk_hdmi_2x(clk_hdmi_2x),
  .clk_mem_n(clk_mem_n),
  .clk_ref(clk_ref),
  // Status and control signals               
  .reset(reset), 
  .locked(locked),
 // Clock in ports
  .clk_in1(clk_in1)
  );

endmodule
