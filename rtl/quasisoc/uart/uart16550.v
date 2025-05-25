// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm
`timescale 1ns / 1ps

module uart16550 #(
    parameter CLOCK_FREQ = 62500000,
    parameter RESET_BAUD_RATE = 9600,
    parameter FIFODEPTH = 16,
    parameter LENDIAN = 0,
    parameter SIM = 0,
    parameter VERBOSELOG = 0
)(
    input clk,
    input rst,
    (*mark_debug = "true"*)input [2:0]a,
    (*mark_debug = "true"*)input [31:0]d,
    (*mark_debug = "true"*)input rd,
    (*mark_debug = "true"*)input we,
    (*mark_debug = "true"*)output reg [31:0]spo,
    (*mark_debug = "true"*)output ready,

    input rx, // sin
    output tx, // sout
    (*mark_debug = "true"*)output irq,

    // for interactive simulation
    input rxsim_en,
    input [7:0]rxsim_data,
    // for uartboot and uartreset, unused for standard 16550
    output rxnew,
    output [7:0]rxdata
);
	(*mark_debug = "true"*) wire [7:0]data = LENDIAN ? d[7:0] : d[31:24];

	(*mark_debug = "true"*) reg rx_r = 1;
	(*mark_debug = "true"*) reg tx_r = 1;

    localparam TX_IDLE = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_DATA = 2'b10;
    localparam TX_STOP = 2'b11;
    reg [1:0]state_tx = TX_IDLE;
    reg [7:0]data_tx = 8'h00;
    reg [2:0]bitpos_tx = 3'b0;

    localparam RX_STATE_START = 2'b01;
    localparam RX_STATE_START_REMEDY = 2'b00;
    localparam RX_STATE_DATA = 2'b10;
    localparam RX_STATE_STOP = 2'b11;
    (*mark_debug = "true"*) reg [1:0]state_rx = RX_STATE_START;
    (*mark_debug = "true"*) reg [15:0]sample = 0;
    (*mark_debug = "true"*) reg [3:0]bitpos_rx = 0;
    (*mark_debug = "true"*) reg [7:0]tmp_rx = 8'b0;

    (*mark_debug = "true"*)wire [7:0]rbr; // R
    reg [7:0]rbr_r;
    wire [7:0]rbr_o;
    (*mark_debug = "true"*)wire [7:0]thr = tx_fifo_enq ? data : 0; // W
    (*mark_debug = "true"*)reg [7:0]ier = 0; // RW
    wire edssi = ier[3];
    wire elsi = ier[2];
    wire etbei = ier[1];
    wire erbfi = ier[0];
    (*mark_debug = "true"*)wire [7:0]iir = {fifoen, fifoen, 2'b0, intid2, intpend}; // R
    // 011: receiver line status
    wire rls_irq = oe;
    // 010: received data available
    reg rda_irq = 0;
    // 110: character timeout
    reg ct_irq = 0;
    reg [31:0]ct_cnt = 0;
    // 001: THR empty
    reg thre_irq = 0;
    // 000: modem status, unused, indicates no interrupt here
    wire [2:0]intid2 = (rls_irq  & elsi ) ? 3'b011 : 
                       (rda_irq  & erbfi) ? 3'b010 : 
                       (ct_irq   & erbfi) ? 3'b110 : 
                       (thre_irq & etbei ) ? 3'b001 : 3'b000;
    wire intpend = intid2 == 3'b000; // use unused 3'b000 as indicator
    assign irq = !intpend;
    (*mark_debug = "true"*)reg [7:0]fcr = 0; // W
    wire [1:0]rcvr_fifo_trigger_level = fcr[7:6];
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
    (*mark_debug = "true"*)wire [7:0]lsr = { error_in_rcvr_fifo,
        temt, thre, bi, fe, pe, oe, dr }; // R
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
    localparam DLL_INIT = (CLOCK_FREQ/(16*RESET_BAUD_RATE)) & 8'hFF;
    localparam DLM_INIT = ((CLOCK_FREQ/(16*RESET_BAUD_RATE)) & 16'hFF00) >> 8;
    (*mark_debug = "true"*)reg [7:0]dll = DLL_INIT; // RW
    (*mark_debug = "true"*)reg [7:0]dlm = DLM_INIT; // RW
    // no pre-scaler division
    wire [15:0]dl = {dlm, dll};
    wire [19:0]tx_count = {dl, 4'b0}; // dl * 16
	reg  [19:0]tx_en_cnt = 0;
    (*mark_debug = "true"*)wire txclk_en = tx_en_cnt == 0;
	always @ (posedge clk) begin
		if (rst) tx_en_cnt <= 0;
		else tx_en_cnt <= tx_en_cnt == tx_count ? 0 : tx_en_cnt + 1;
	end
    (*mark_debug = "true"*)wire [15:0]rx_count = dl * 16;
    (*mark_debug = "true"*)wire [15:0]rx_count_sample = rx_count/2;
    (*mark_debug = "true"*)wire [15:0]rx_count_remedy = rx_count/4;

    // illegal reads/writes are automatically discarded
    (*mark_debug = "true"*)wire tx_fifo_empty;
    (*mark_debug = "true"*)wire tx_fifo_full;
    (*mark_debug = "true"*)wire tx_fifo_enq = we && a == 3'b000 && !dlab;
    (*mark_debug = "true"*)wire [7:0]tx_fifo_data;
    myfifo #(.SIMLOG(0), .WIDTH(8), .DEPTH(FIFODEPTH)) uart_16550_txfifo (
        .clk(clk),
        .rst(xmit_fifo_reset | rst),
        .enq(tx_fifo_enq),
        .din(thr),
        .deq(state_tx == TX_IDLE && !tx_fifo_empty),
        .dout(tx_fifo_data),
        .empty(tx_fifo_empty),
        .full(tx_fifo_full)
    );
    (*mark_debug = "true"*)wire rx_fifo_empty;
    (*mark_debug = "true"*)wire rx_fifo_full;
    (*mark_debug = "true"*)wire [$clog2(FIFODEPTH)-1:0]rx_filled; 
    (*mark_debug = "true"*)reg [7:0] rx_fifo_data;
    (*mark_debug = "true"*)reg rx_fifo_enq;
    (*mark_debug = "true"*)wire rx_fifo_deq = rd && a == 3'b000 && !dlab;
    myfifo #(.SIMLOG(0), .WIDTH(8), .DEPTH(FIFODEPTH)) uart_16550_rxfifo (
        .clk(clk),
        .rst(rcvr_fifo_reset | rst),
        .enq(rx_fifo_enq),
        .din(rx_fifo_data),
        .deq(rx_fifo_deq),
        .dout(rbr),
        .empty(rx_fifo_empty),
        .full(rx_fifo_full),
        .filled(rx_filled)
    );
    assign rbr_o = rx_fifo_deq ? rbr : rbr_r;
    
    reg [2:0]intid2_old = 0;
    // ordinary registe writes
    always @ (*) begin
        if      (a == 3'b000) spo = LENDIAN ? {24'b0, dlab ? dll : rbr_o} : {dlab ? dll : rbr_o, 24'b0};
        else if (a == 3'b001) spo = LENDIAN ? {24'b0, dlab ? dlm : ier} : {dlab ? dlm : ier, 24'b0};
        else if (a == 3'b010) spo = LENDIAN ? {24'b0, iir} : {iir, 24'b0};
        else if (a == 3'b011) spo = LENDIAN ? {24'b0, lcr} : {lcr, 24'b0};
        else if (a == 3'b100) spo = LENDIAN ? {24'b0, mcr} : {mcr, 24'b0};
        else if (a == 3'b101) spo = LENDIAN ? {24'b0, lsr} : {lsr, 24'b0};
        else if (a == 3'b110) spo = LENDIAN ? {24'b0, msr} : {msr, 24'b0};
        else if (a == 3'b111) spo = LENDIAN ? {24'b0, spr} : {spr, 24'b0};
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

            rbr_r <= 0;

            ier <= 8'h0;
            fcr <= 8'h0;
            lcr <= 8'b00000011;
            mcr <= 8'h0;
            //lsr <= 8'b01100000;
            spr <= 8'h0;
            dll <= DLL_INIT;
            dlm <= DLM_INIT;

            temt <= 0;
            thre <= 0;
            bi <= 0;
            fe <= 0;
            pe <= 0;
            oe <= 0;
            dr <= 0;

            rda_irq <= 0;
            thre_irq <= 0;

            ct_cnt <= 0;
            ct_irq <= 0;
        end
        else begin
            if (VERBOSELOG == 1) begin
                intid2_old <= intid2;
                if (intid2 != intid2_old) begin
                    $write("intid2 changes to: %03x\n", intid2);
                    $write("ier: %08x\n", ier);
                    $write("thr: %08x\n", thr);
                    $write("iir: %08x\n", iir);
                    $write("fcr: %08x\n", fcr);
                    $write("lcr: %08x\n", lcr);
                    $write("mcr: %08x\n", mcr);
                    $write("lsr: %08x\n", lsr);
                end
                if (rd) begin
                    $write("\033[43mRD_%x_%08x\033[0m ", a, spo);
                end
                if (we) begin
                    $write("\033[42mWE_%x_%08x\033[0m ", a, d);
                end
            end
            // Latch RBR, so after RX FIFO deq, top value remains, until next deq
            if (rx_fifo_deq) rbr_r <= rbr;
            else rbr_r <= rbr_r;
            // LSR contents
            // an instant empty will occur after the first of a serial of writes lands,  
            //  giving an unwanted interrupt
            // because our THR is just the FIFO's tail
            temt <= tx_fifo_empty && state_tx == TX_IDLE;
            thre <= tx_fifo_empty && state_tx == TX_IDLE;
            dr <= !rx_fifo_empty;
            // Interrupts
            // LSR interrupts
            // overrun error: read LSR to clear
            if (rd && a == 3'b101) begin
                oe <= 0;
            end else begin
                if (rx_fifo_full && rx_fifo_enq)
                    oe <= 1;
            end 
            // transmitter holding register empty interrupt:
            // clear by reading iir or writing to thr
            if (rd && a == 3'b010) begin
                thre_irq <= 0;
            end else if (tx_fifo_enq) begin
                thre_irq <= 0;
            end else if (thre) begin
                thre_irq <= 1;
                //$write("\033[35mT\033[0m");
            end
            // received data available (auto)
            case (rcvr_fifo_trigger_level)
                2'b00: rda_irq <= rx_filled >= 1;
                2'b01: rda_irq <= rx_filled >= 4;
                2'b10: rda_irq <= rx_filled >= 8;
                2'b11: rda_irq <= rx_filled >= 14;
            endcase
            // character timeout (read RBR to clear)
            if (rd && a == 3'b000) begin
                ct_cnt <= 0;
                ct_irq <= 0;
            end else begin
                // 48 bits at current baud rate for timeout
                // Just use 64
                if (rx_filled && !rx_fifo_enq && !rx_fifo_deq)
                    ct_cnt <= ct_cnt + 1;
                else
                    ct_cnt <= 0;
                if (ct_cnt > 64 * tx_count) begin
                    ct_irq <= 1;
                    //$write("\033[35mT\033[0m");
                end
            end
            // FIFO reset clearing
            if (xmit_fifo_reset || rcvr_fifo_reset) begin
                fcr <= fcr & 8'b11111001;
            end
            // ordinary register writes
            if (we) begin
                if      (a == 3'b000 && dlab)  dll <= data;
                else if (a == 3'b000 && !dlab) ; // TX Fifo Enq
                else if (a == 3'b001 && dlab)  dlm <= data;
                else if (a == 3'b001 && !dlab) ier <= data;
                else if (a == 3'b010)          fcr <= data;
                else if (a == 3'b011)          lcr <= data;
                else if (a == 3'b100)          mcr <= data;
                else if (a == 3'b111)          spr <= data;
            end
            // TX and RX FSM, runs on its own
            case (state_tx)
                TX_IDLE: if (!tx_fifo_empty) begin
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
                    if (SIM == 1) begin
                        $write("%c", data_tx);
                        $fflush();
                    end
                    tx_r <= 1'b1;
                    state_tx <= TX_IDLE;
                end
            endcase
            if (SIM == 0) begin
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
                if (VERBOSELOG & rxsim_en)
                    $write("SIMW: %c\n", rxsim_data);
            end
        end
    end

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

    assign ready = 1;

	// single-cycle pulse receive done indication, for quasisoc serialboot
    assign rxnew = rx_fifo_enq;
	assign rxdata = rx_fifo_data;
endmodule

module myfifo #(
    parameter SIMLOG = 0,
	parameter WIDTH = 32,
	parameter DEPTH = 16
)(
	input clk,
	input rst,

	input enq,
	input [WIDTH-1:0]din,
	input deq,
	output [WIDTH-1:0]dout,
	output empty,
	output full,
    output [$clog2(DEPTH)-1:0]filled
);
	reg [$clog2(DEPTH)-1:0]head = 0;
	reg [$clog2(DEPTH)-1:0]tail = 0;
	assign empty = head == tail;
	assign full = tail+1 == head;
    assign filled = (tail - head + DEPTH);

	reg [WIDTH-1:0]d[DEPTH-1:0];

	assign dout = d[head];

	always @ (posedge clk) begin
		if (rst) begin
			head <= 0;
			tail <= 0;
			d[0] <= 0;
		end else begin
			// ignore illegal requests
			if (enq & (!full | deq)) begin
				tail <= tail + 1;
				d[tail] <= din;
                if (SIMLOG) begin
                    $write("\033[34mENQ %c(%02x) (h:%d t:%d l:%d)\033[0m\n", din, din, head, tail, filled);
                    $write("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n", d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12], d[13], d[14], d[15]);
                end
			end
			if (deq & !empty) begin
				head <= head + 1;
                if (SIMLOG) begin
                    $write("\033[33mDEQ %c(%02x) (h:%d t:%d l:%d)\033[0m\n", dout, dout, head, tail, filled);
                    $write("%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n", d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12], d[13], d[14], d[15]);
                end
			end
		end
	end
endmodule
