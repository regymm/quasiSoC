`timescale 1ns / 1ps
// pComputer multi-cycle CPU -- coprocessor0
// interrupt/exception handler, and other random stuff

module coprocessor0
    (
        input clk,
        input rst,

        input [4:0]Mfc0Src,
        output reg [31:0]mfc0out,
        input [4:0]Mtc0Src,
        input Mtc0Write,
        input [31:0]mtc0in,

        input EPCSrc,
        input CauseSrc,
        input StatusSrc,
        input EPCWrite,
        input CauseWrite,
        input StatusWrite,
        input [31:0]pc,
        input [31:0]current_pc,
        input [3:0]causedata_outside,

        // TODO: better exception cause id
        output wire [31:0]epc_out,
        output wire [31:0]status_out,
        output wire ring_out
    );

    // cp0 registers
    // "standard" ones
    reg [31:0]cause = 0;
    reg [31:0]status = 32'b1111;
    reg [31:0]epc = 0;
    // privilege level
    reg [1:0]ring = 2'b00;
    // counter
    (*mark_debug = "true"*) reg [31:0]counter = 0;

    // cp0 signals
    // need extras signals because many regs may be written at once
    reg [31:0]CauseData;
    reg [31:0]StatusData;
    reg [31:0]EPCData;
    // and other signals are needed at all time
    assign epc_out = epc;
    assign status_out = status;
    assign ring_out = ring[0];

    // datpath -- coprocessor 0
    always @ (*) begin
        case (Mfc0Src)
            14: mfc0out = epc;
            13: mfc0out = cause;
            12: mfc0out = status;
            default: mfc0out = 0;
        endcase
        case (CauseSrc)
            0: CauseData = {28'b0, causedata_outside};  // timer, ...
            1: CauseData = 1;                           // syscall
            2: CauseData = 2;                           // exception
            default: ;
        endcase
        case (StatusSrc)
            0: StatusData = {status[15:0], 16'b0};  // syscall/interrupt
            1: StatusData = {16'b0, status[31:16]}; // eret
            //2: StatusData = mtc0in;
        endcase
        case (EPCSrc)
            0: EPCData = pc;            // syscall: return to next instr
            1: EPCData = current_pc;    // interrupt: return to current instr
            //2: EPCData = mtc0in;
        endcase
    end
    always @ (posedge clk) begin
        if (rst) begin
            epc <= 0;
            cause <= 0;
            status <= 32'b1111;
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
            // in theory these two cases won't overlap
            if (Mtc0Write) case (Mtc0Src)
                14: epc <= mtc0in;
                13: cause <= mtc0in;
                12: status <= mtc0in;
                default: ;
            endcase
            else begin
                if (EPCWrite) epc <= EPCData;
                if (CauseWrite) cause <= CauseData;
                if (StatusWrite) status <= StatusData;
            end
        end
    end
endmodule
