`timescale 1ns / 1ps
// pComputer TOP module

module top
    (
        input sysclk,
        //input rst,
        
        input [1:0]sw,
        output wire led4_b,
        output wire led4_g,
        output wire led4_r,
        output wire led5_b,
        output wire led5_g,
        output wire led5_r,
        output wire [3:0]led,
        input [3:0]btn
    );

    wire rst = sw[0];

    wire clk_main = sysclk;
    //clk_wiz_0 clk_wiz_0_inst
    //(
        //.reset(rst),
        //.sysclk(sysclk),
        //.clk_main(clk_main)
    //);

    wire [31:0]a;
    wire [31:0]d;
    wire we;
    wire [31:0]spo;
    cpu_multi_cycle cpu_multi_cycle_inst
    (
        .clk(clk_main),
        .rst(rst),
        .a(a),
        .d(d),
        .we(we),
        .spo(spo)
    );

    wire [31:0]bootm_a;
    wire [31:0]bootm_d;
    wire bootm_we;
    wire [31:0]bootm_spo;
    wire [31:0]mainm_a;
    wire [31:0]mainm_d;
    wire mainm_we;
    wire [31:0]mainm_spo;
    wire [31:0]gpio_a;
    wire [31:0]gpio_d;
    wire gpio_we;
    wire [31:0]gpio_spo;
    mmapper mmapper_inst
    (
        .a(a),
        .d(d),
        .we(we),
        .spo(spo),

        .bootm_a(bootm_a),
        .bootm_d(bootm_d),
        .bootm_we(bootm_we),
        .bootm_spo(bootm_spo),

        .mainm_a(mainm_a),
        .mainm_d(mainm_d),
        .mainm_we(mainm_we),
        .mainm_spo(mainm_spo),

        .gpio_a(gpio_a),
        .gpio_d(gpio_d),
        .gpio_we(gpio_we),
        .gpio_spo(gpio_spo)
    );

    bootrom bootrom_inst
    (
        .a(bootm_a),
        .spo(bootm_spo)
    );

    main_memory main_memory_inst
    (
        .clk(clk_main),
        .a(mainm_a),
        .d(mainm_d),
        .we(mainm_we),
        .spo(mainm_spo)
    );

    gpio gpio_inst
    (
        .clk(clk_main),
        .a(gpio_a),
        .d(gpio_d),
        .we(gpio_we),
        .spo(gpio_spo),

        .btn(btn),
        .sw(sw),
        .led(led),
        .rgbled1({led4_b, led4_g, led4_r}),
        .rgbled2({led5_b, led5_g, led5_r})
    );

endmodule
