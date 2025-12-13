// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm

`timescale 1ps/1ps

module mmcm_50_to_50 ( // 33.333 to 50
    input wire    resetn,
    input wire    clk_in1,
    output wire   clk_out1,
    output wire   locked
);
    wire clk_out1_mmcm;
    wire fb;
    wire fb_buf;
    MMCME2_ADV #(
        .BANDWIDTH            ("OPTIMIZED"),
        .CLKOUT4_CASCADE      ("FALSE"),
        .COMPENSATION         ("ZHOLD"),
        .STARTUP_WAIT         ("FALSE"),
        .DIVCLK_DIVIDE        (1),
        .CLKFBOUT_MULT_F      (30.000), // PLL 1000 MHz
        .CLKFBOUT_PHASE       (0.000),
        .CLKFBOUT_USE_FINE_PS ("FALSE"),
        .CLKOUT0_DIVIDE_F     (30.000), // 50 MHz -> 40 MHz
        .CLKOUT0_PHASE        (0.000),
        .CLKOUT0_DUTY_CYCLE   (0.500),
        .CLKOUT0_USE_FINE_PS  ("FALSE"),
        .CLKIN1_PERIOD        (20.000)
        ) mmcm_adv_inst (
        .CLKFBOUT            (fb),
        .CLKFBOUTB           (),
        .CLKOUT0             (clk_out1_mmcm),
        .CLKOUT0B            (),
        .CLKOUT1             (),
        .CLKOUT1B            (),
        .CLKOUT2             (),
        .CLKOUT2B            (),
        .CLKOUT3             (),
        .CLKOUT3B            (),
        .CLKOUT4             (),
        .CLKOUT5             (),
        .CLKOUT6             (),
        .CLKFBIN             (fb_buf),
        .CLKIN1              (clk_in1),
        .CLKIN2              (1'b0),
        .CLKINSEL            (1'b1),
        .DADDR               (7'h0),
        .DCLK                (1'b0),
        .DEN                 (1'b0),
        .DI                  (16'h0),
        .DO                  (),
        .DRDY                (),
        .DWE                 (1'b0),
        .PSCLK               (1'b0),
        .PSEN                (1'b0),
        .PSINCDEC            (1'b0),
        .PSDONE              (),
        .LOCKED              (locked),
        .CLKINSTOPPED        (),
        .CLKFBSTOPPED        (),
        .PWRDWN              (1'b0),
        .RST                 (~resetn));
    BUFG clkf_buf
        (.O (fb_buf),
        .I (fb));
    BUFG clkout1_buf
        (.O  (clk_out1),
        .I   (clk_out1_mmcm));
endmodule
