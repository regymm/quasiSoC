/**
 * File              : uart16550.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/ustcpetergu>
 * Date              : 2021.01.24
 * Last Modified Date: 2025.04.20
 */
`timescale 1ns / 1ps
// pComputer UART
// a better version (arbitary input clk freq, fifo, ...)
// TODO: fifo? fifo w/ uartboot?
//
// write 0x00: transmit data -- (tx fifo enqueue)
// read 0x00: received data -- (first data in rx fifo)
// write 0x01: begin receiving -- (rx fifo dequeue, ignore empty)
// read 0x01: new data received? -- (rx fifo empty?)
// read 0x02: transmit done? -- (tx fifo full?)
// 0x03: 
// rxnew/rxdata: real-time, extra fifo required in serialboot
// *need to x4 these addresses in assembly!
//`include "quasi.vh"

module uart_16550
	#(
		parameter CLOCK_FREQ = 62500000,
        parameter RESET_BAUD_RATE = 9600,
        parameter FIFODEPTH = 16,
        parameter AXI = 0,
        parameter SIM = 0
		//parameter BAUD_RATE = 115200, 
	)
    (
        input clk,
        input rst,

        input rx,
        output tx,

        input [2:0]a,
        input [31:0]d,
        input rd,
        input we,
        output reg [31:0]spo,

        output irq,

        // for interactive simulation
        input rxsim_en,
        input [7:0]rxsim_data,

        // for uartboot and uartreset, unused for standard 16550
		output reg rxnew,
		output [7:0]rxdata
    );

	wire [7:0]data = d[31:24];

	(*mark_debug = "true"*) reg rx_r = 1;
	(*mark_debug = "true"*) reg tx_r = 1;

    // baud_rate = clock_freq / (16 * divisor_latch)
	//localparam SAMPLE_COUNT = CLOCK_FREQ / BAUD_RATE;
	//localparam SAMPLE_SAMPLE = SAMPLE_COUNT / 2;
	//localparam SAMPLE_REMEDY = SAMPLE_COUNT / 4;

    localparam TX_IDLE = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_DATA = 2'b10;
    localparam TX_STOP = 2'b11;
    reg [1:0]state_tx = IDLE;
    reg [7:0]data_tx = 8'h00;
    reg [2:0]bitpos_tx = 3'b0;

    localparam RX_STATE_START = 2'b01;
    localparam RX_STATE_START_REMEDY = 2'b00;
    localparam RX_STATE_DATA = 2'b10;
    localparam RX_STATE_STOP = 2'b11;
    (*mark_debug = "true"*) reg [1:0]state_rx = RX_STATE_START;
    (*mark_debug = "true"*) reg [15:0]sample = 0;
    reg [3:0]bitpos_rx = 0;
    (*mark_debug = "true"*) reg [7:0]tmp_rx = 8'b0;

    (*mark_debug = "true"*)wire [7:0]rbr; // R
    (*mark_debug = "true"*)wire [7:0]thr = data; // W
    (*mark_debug = "true"*)reg [7:0]ier = 0; // RW
    wire edssi = ier[3];
    wire elsi = ier[2];
    wire etbei = ier[1];
    wire erbfi = ier[0];
    (*mark_debug = "true"*)wire [7:0]iir = {fifoen, 2'b0, intid2, intpend}; // R
    // 011: receiver line status
    // 010: received data available
    // 110: character timeout
    // 001: THR empty
    // 000: modem status
    reg [2:0]intid2 = 0;
    reg intpend = 0;
    (*mark_debug = "true"*)reg [7:0]fcr = 0; // W
    wire rcvr_fifo_trigger_level = fcr[7:6];
    wire dma_mode = fcr[3];
    wire xmit_fifo_reset = fcr[2];
    wire rcvr_fifo_reset = fcr[1];
    wire fifoen = fcr[0]; // assume always enabled? 
    (*mark_debug = "true"*)reg [7:0]lcr = 0; // RW
    wire dlab = lcr[7]; // only this is used
    wire set_break = lcr[6]; // only classical 8-bit, 1 stop bit, no parity, no break
    wire sticky_parity = lcr[5];
    wire eps = lcr[4];
    wire pen = lcr[3];
    wire stb = lcr[2];
    wire [1:0]wls = lcr[1:0]; 
    (*mark_debug = "true"*)reg [7:0]mcr = 0; // RW
    wire loop = mcr[4];
    wire out2 = mcr[3];
    wire out1 = mcr[2];
    wire rts = mcr[1];
    wire dtr = mcr[0]; // in "modern" TX/RX only UART, only loopback used
    (*mark_debug = "true"*)wire [7:0]lsr = {
        error_in_rcvr_fifo,
        temt,
        thre,
        bi,
        fe,
        pe,
        oe,
        dr }; // R
    reg error_in_rcvr_fifo = 0;
    reg temt;
    reg thre;
    reg bi = 0; // break interrupt, unused
    reg fe = 0; // framing error, unused
    reg pe = 0; // parity error, unused
    reg oe; // overrun error
    reg dr; // data ready
    (*mark_debug = "true"*)wire [7:0]msr = 8'b10110000; // R
    // use dummy dcd, ri, dsr, cts = 1, 0, 1, 1
    (*mark_debug = "true"*)reg [7:0]spr = 0; // RW
    (*mark_debug = "true"*)reg [7:0]dll = 0; // RW
    (*mark_debug = "true"*)reg [7:0]dlm = 0; // RW
    // no pre-scaler division
    wire [15:0]dl = {dlm, dll};
    wire [19:0]tx_count = {dl, 4'b0}; // dl * 16
	reg  [19:0]tx_en_cnt = 0;
    wire txclk_en = tx_en_cnt == 0;
	always @ (posedge clk) begin
		if (rst) tx_en_cnt <= 0;
		else tx_en_cnt <= tx_en_cnt == tx_count ?
			0 : tx_en_cnt + 1;
	end
    wire [15:0]rx_count = dl;
    wire [15:0]rx_count_sample = rx_count/2;
    wire [15:0]rx_count_remedy = rx_count/4;

    // illegal reads/writes are automatically discarded
    wire tx_fifo_empty;
    wire tx_fifo_full;
    wire [7:0]tx_fifo_data;
    myfifo #(.WIDTH(8), .DEPTH(FIFODEPTH)) uart_16550_txfifo (
        .clk(clk),
        .rst(xmit_fifo_reset),
        .enq(we && a == 3'b000 && !dlab),
        .din(thr),
        .deq(state_tx == TX_IDLE && !tx_fifo_empty),
        .dout(tx_fifo_data),
        .empty(tx_fifo_empty),
        .full(tx_fifo_full)
    );
    wire rx_fifo_empty;
    wire rx_fifo_full;
    reg [7:0] rx_fifo_data;
    reg rx_fifo_enq;
    myfifo #(.WIDTH(8), .DEPTH(FIFODEPTH)) uart_16550_rxfifo (
        .clk(clk),
        .rst(rcvr_fifo_reset),
        .enq(rx_fifo_enq),
        .din(rx_fifo_data),
        .deq(rd && a == 3'b000 && !dlab),
        .dout(rbr),
        .empty(rx_fifo_empty),
        .full(rx_fifo_full)
    );
    
    // ordinary registe writes
    always @ (*) begin
        if      (a == 3'b000) spo = {dlab ? dll : rbr, 24'b0};
        else if (a == 3'b001) spo = {dlab ? dlm : ier, 24'b0};
        else if (a == 3'b010) spo = {iir, 24'b0};
        else if (a == 3'b011) spo = {lcr, 24'b0};
        else if (a == 3'b100) spo = {mcr, 24'b0};
        else if (a == 3'b101) spo = {lsr, 24'b0};
        else if (a == 3'b110) spo = {msr, 24'b0};
        else if (a == 3'b111) spo = {spr, 24'b0};
        else spo = 32'b0;
    end
    always @ (posedge clk) begin
        if (rst) begin
            tx_r <= 1'b1;
            state_tx <= TX_IDLE;
            data_tx <= 0;
            bitpos_tx <= 3'b0;

            state_rx <= RX_STATE_START;
            rx_fifo_data <= 0;
			bitpos_rx <= 0;
            sample <= 0;
			tmp_rx <= 0;

            ier <= 8'h0;
            fcr <= 8'h0;
            lcr <= 8'b00000011;
            mcr <= 8'h0;
            //lsr <= 8'b01100000;
            spr <= 8'h0;
            dll <= $floor(CLOCK_FREQ/(16*RESET_BAUD_RATE)) & 8'hFF;
            dlm <= ($floor(CLOCK_FREQ/(16*RESET_BAUD_RATE)) & 16'hFF00) >> 8;

            temt <= 0;
            thre <= 0;
            bi <= 0;
            fe <= 0;
            pe <= 0;
            oe <= 0;
            dr <= 0;
        end
        else begin
            // link status register
            if (rd && a == 3'b101) begin
                temt <= 0;
                thre <= 0;
                bi <= 0;
                fe <= 0;
                pe <= 0;
                oe <= 0;
                dr <= 0;
            end else begin
                if (tx_fifo_empty) begin
                    temt <= 1;
                    thre <= 1;
                end
                if (rx_fifo_full && rx_fifo_enq) begin
                    oe <= 1;
                end
                if (!rx_fifo_empty) begin
                    dr <= 1;
                end
            end
            // ordinary registe writes
            if (we) begin
                if      (a == 3'b000 && dlab)  dll <= data;
                else if (a == 3'b000 && !dlab) ; // TX Fifo Enq
                else if (a == 3'b001 && dlab)  dlm <= data;
                else if (a == 3'b001 && !dlab) ier <= data;
                else if (a == 3'b010)          fcr <= data;
                else if (a == 3'b100)          mcr <= data;
            end
            // TX and RX FSM, runs on its own
            case (state_tx)
                TX_IDLE: if (!tx_fifo_empty) begin
                    if (SIM == 1) begin
                        $write("%c", data);
                        $fflush();
                    end
                    data_tx <= tx_fifo_data;
                    state_tx <= TX_START;
                end
                TX_START: if (txclk_en) begin
                    tx_r <= 1'b0;
                    state_tx <= TX_DATA;
                    bitpos_tx <= 3'b0;
                end
                TX_DATA: if (txclk_en) begin
                    if (bitpos_tx == 3'h7) state_tx <= TX_STOP;
                    else bitpos_tx <= bitpos_tx + 1;
                    tx_r <= data_tx[bitpos_tx];
                end
                TX_STOP: if (txclk_en) begin
                    tx_r <= 1'b1;
                    state_tx <= TX_IDLE;
                end
            endcase
            if (SIM == 1) begin
			case (state_rx)
				RX_STATE_START: begin
                    rx_fifo_enq <= 0;
					if (!rx_r || sample != 0) sample <= sample + 1;
					if (sample == rx_count) begin
						sample <= 0;
                        bitpos_rx <= 0;
						tmp_rx <= 0;
						state_rx <= RX_STATE_DATA;
					end
				end
                RX_STATE_DATA: begin // sample is 0 when enter
					sample <= sample == rx_count ? 0 : sample + 1;
                    if (sample == rx_count/2) begin // sample half way in
						tmp_rx[bitpos_rx[2:0]] <= rx_r;
						bitpos_rx <= bitpos_rx + 1;
					end
					if (bitpos_rx == 8 && sample == rx_count) state_rx <= RX_STATE_STOP;
				end
                RX_STATE_STOP: begin // sample is 0 when enter
                    // if sampling is too slow, we already eat into the next start bit
                    // if sampling is too fast, just wait more for next start bit
                    // as a basic check, assume won't be >3/4 cycle late
					if (sample == rx_count || (sample >= rx_count/4 && !rx_r)) begin
                        rx_fifo_enq <= 1;
						rx_fifo_data <= tmp_rx;
						sample <= rx_r ? 0 : 1; // every cycle matters... or not?
						bitpos_rx <= 0;
						tmp_rx <= 0;
						state_rx <= RX_STATE_START;
					end else begin
						sample <= sample + 1;
					end
				end
				default: state_rx <= RX_STATE_START;
			endcase
            end else begin
                rx_fifo_enq <= rxsim_en;
                rx_fifo_data <= rxsim_data;
            end
        end
    end

	// single-cycle pulse receive done indication, for quasisoc serialboot
    assign rxnew = rx_fifo_enq;
	assign rxdata = rx_fifo_data;

    // 2 beats at in/out
	reg rx_r0 = 1;
	reg tx_r0 = 1;
	always @ (posedge clk) begin
        if (loop) begin
            rx_r <= tx_r;
        end else begin
            rx_r0 <= rx;
            rx_r <= rx_r0;
        end
        tx_r0 <= tx_r;
	end
    assign tx = tx_r0;
endmodule
