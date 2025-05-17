// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm

`timescale 1ps/1ps

module mmcm_50_to_50 (
    input wire    resetn,
    input wire    clk_in1,
    output wire   clk_out1,
    output wire   locked
);
    assign clk_out1 = clk_in1;
    assign locked = 1'b1;
endmodule
