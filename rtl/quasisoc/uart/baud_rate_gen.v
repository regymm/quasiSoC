// this is copied from github
/*
 * Hacky baud rate generator to divide a 50MHz clock into a 115200 baud
 * rx/tx pair where the rx clcken oversamples by 16x.
 */
`include "quasi.vh"

module baud_rate_gen
	#(
		parameter CLOCK_FREQ = 0,
		parameter BAUD_RATE = 0,
		parameter SAMPLE_MULTIPLIER = 16
	)
    (
        input wire clk,
        input rst,
        output wire rxclk_en,
        output wire txclk_en
    );

    parameter RX_ACC_MAX = CLOCK_FREQ / (BAUD_RATE * SAMPLE_MULTIPLIER) + 1;
    parameter TX_ACC_MAX = CLOCK_FREQ / BAUD_RATE;
    parameter RX_ACC_WIDTH = 20;
    parameter TX_ACC_WIDTH = 20;
    //parameter RX_ACC_WIDTH = $clog2(RX_ACC_MAX);
    //parameter TX_ACC_WIDTH = $clog2(TX_ACC_MAX);
    reg [RX_ACC_WIDTH - 1:0] rx_acc = 0;
    reg [TX_ACC_WIDTH - 1:0] tx_acc = 0;

    assign rxclk_en = (rx_acc == 0);
    assign txclk_en = (tx_acc == 0);

    always @(posedge clk) begin
        if (rst) rx_acc <= 1;
        else if (rx_acc == RX_ACC_MAX[RX_ACC_WIDTH - 1:0])
            rx_acc <= 0;
        else
            rx_acc <= rx_acc + 1;
    end

    always @(posedge clk) begin
        if (rst) tx_acc <= 1;
        else if (tx_acc == TX_ACC_MAX[TX_ACC_WIDTH - 1:0])
            tx_acc <= 0;
        else
            tx_acc <= tx_acc + 1;
    end

endmodule
