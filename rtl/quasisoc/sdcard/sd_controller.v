/* SD Card controller module. Allows reading from and writing to a microSD card
through SPI mode. */
// http://web.mit.edu/6.111/www/f2017/tools/sd_controller.v
// Simulation: github.com/ZipCPU/sdspi
// ref: 
// https://stackoverflow.com/questions/8080718/sdhc-microsd-card-and-spi-initialization
// https://electronics.stackexchange.com/questions/321491/why-i-cant-issue-commands-after-cmd8-to-an-sdhc-card-in-spi-mode
// http://chlazza.nfshost.com/sdcardinfo.html
// (chinese) https://blog.csdn.net/ming1006/article/details/7281597
// https://elm-chan.org/docs/mmc/mmc_e.html

`timescale 1ns / 1ps

module sd_controller(
    output reg cs, // Connect to SD_DAT[3].
    output mosi, // Connect to SD_CMD.
    input miso, // Connect to SD_DAT[0].
    output sclk, // Connect to SD_SCK.
                // For SPI mode, SD_DAT[2] and SD_DAT[1] should be held HIGH. 
                // SD_RESET should be held LOW.

    input rd,   // Read-enable. When [ready] is HIGH, asseting [rd] will 
                // begin a 512-byte READ operation at [address]. 
                // [byte_available] will transition HIGH as a new byte has been
                // read from the SD card. The byte is presented on [dout].
    output reg [7:0] dout, // Data output for READ operation.
    output reg byte_available, // A new byte has been presented on [dout].

    input wr,   // Write-enable. When [ready] is HIGH, asserting [wr] will
                // begin a 512-byte WRITE operation at [address].
                // [ready_for_next_byte] will transition HIGH to request that
                // the next byte to be written should be presentaed on [din].
    input [7:0] din, // Data input for WRITE operation.
    output reg ready_for_next_byte, // A new byte should be presented on [din].

    input reset, // Resets controller on assertion.
    output ready, // HIGH if the SD card is ready for a read or write operation.
    input [31:0] address,   // Memory address for read/write operation. This MUST 
                            // be a multiple of 512 bytes, due to SD sectoring.
    input clk,  // normal speed clock
    input clk_pulse_slow, // pulsed slow clock
    output [4:0] status, // For debug purposes: Current state of controller.
    output reg [7:0] recv_data
);

    parameter RST = 0;
    parameter INIT = 1;
    parameter CMD0 = 2;
    parameter CMD8 = 3;
    parameter CMD55 = 4;
    parameter ACMD41 = 5;
    parameter POLL_CMD = 6;
    parameter CMD58 = 7;
    parameter CMD16 = 8;
    
    parameter IDLE = 9;
    parameter READ_BLOCK = 10;
    parameter READ_BLOCK_WAIT = 11;
    parameter READ_BLOCK_DATA = 12;
    parameter READ_BLOCK_CRC = 13;
    parameter PRE_SEND_CMD = 23;
    parameter SEND_CMD = 14;
    parameter RECEIVE_BYTE_WAIT = 15;
    parameter RECEIVE_BYTE = 16;
    parameter RECEIVE_BYTE_AFTERWAIT = 22;
    parameter WRITE_BLOCK_CMD = 17;
    parameter WRITE_BLOCK_INIT = 18;
    parameter WRITE_BLOCK_DATA = 19;
    parameter WRITE_BLOCK_BYTE = 20;
    parameter WRITE_BLOCK_WAIT = 21;
    
    parameter WRITE_DATA_SIZE = 515;
    
    (*mark_debug = "true"*) reg [4:0] state = RST;
    assign status = state;
    reg [4:0] return_state;
    reg sclk_sig = 0;
    reg [55:0] cmd_out = {56{1'b1}};
    reg cmd_mode = 1;
    reg [7:0] data_sig = 8'hFF;
    reg [2:0] response_type = 3'b1;
    reg [40:0] recv_data_r7 = 0;
    
    reg [9:0] byte_counter;
    reg [9:0] bit_counter;
    
    reg [26:0] boot_counter = 27'd080_000;
    reg [7:0] reset_counter = 0;
    always @(posedge clk) begin
        if(reset == 1) begin
            state <= RST;
            sclk_sig <= 0;
            //boot_counter <= 27'd005_000;
			boot_counter <= 27'd080_000;
            cmd_mode <= 1;
            cs <= 1;
            cmd_out <= {56{1'b1}};
            data_sig <= 8'hFF;
            dout <= 8'hFF;
            /*
			if (clk_pulse_slow) begin // startup init even when reseting
                reset_counter <= reset_counter + 1;
                if (reset_counter[7]) sclk_sig <= ~sclk_sig;
            end
            */
        end
        else begin
            if (clk_pulse_slow) begin
            case(state)
                RST: begin
                    if(boot_counter == 0) begin
                        sclk_sig <= 0;
                        cmd_out <= {56{1'b1}};
                        byte_counter <= 0;
                        byte_available <= 0;
                        ready_for_next_byte <= 0;
                        cmd_mode <= 1;
                        bit_counter <= 160;
                        cs <= 1;
                        state <= INIT;
                    end
                    else begin
                        // <400KHz startup init
                        boot_counter <= boot_counter - 1;
                        if (boot_counter[6:0] == 0) sclk_sig <= ~sclk_sig;
                        //sclk_sig <= ~sclk_sig; // I added this
                    end
                end
                INIT: begin
                    if(bit_counter == 0) begin
                        cs <= 0;
                        state <= CMD0;
                        sclk_sig <= 1'b0;
                    end
                    else begin
                        bit_counter <= bit_counter - 1;
                        sclk_sig <= ~sclk_sig;
                    end
                end
                CMD0: begin
                    // cmd format: 01   ......        .*32   ....... 1
                    //                command bit   argument  CRC7
                    // returns 01 if good
                    cmd_out <= 48'h40_00_00_00_00_95;
                    bit_counter <= 47;
                    response_type <= 3'b1; //*
                    return_state <= CMD8;
                    state <= PRE_SEND_CMD;
                end
                CMD8: begin
                    // this CMD8 has R7 response (CMD0 and CMD55 has R1)
                    // so take special care, or SDHC card may deadlock
                    // R7 response will be 01_0000_01_aa for SDHC
                    // the first 01 means SDv2.0, in which aa means success
                    cmd_out <= 48'h48_00_00_01_AA_87;
                    bit_counter <= 47;
                    response_type <= 3'b111;
                    return_state <= CMD55;
                    state <= PRE_SEND_CMD;
                end
                CMD55: begin
                    cmd_out <= 48'h77_00_00_00_00_65;
                    bit_counter <= 47;
                    response_type <= 3'b1;
                    return_state <= ACMD41;
                    state <= PRE_SEND_CMD;
                end
                ACMD41: begin
                    cmd_out <= 48'h69_40_00_00_00_77;
                    bit_counter <= 47;
                    response_type <= 3'b1;
                    return_state <= POLL_CMD;
                    state <= PRE_SEND_CMD;
                end
                POLL_CMD: begin
                    // ACMD41 responses 00 when not ready, 01 when ready
                    if(recv_data[0] == 0) begin
                        state <= CMD58; // response 0x0, OK
                    end
                    else begin
                        state <= CMD55; // response 0x1, again
                    end
                end
                CMD58: begin
                    // has R3 response
                    // returns: 00_c0_ff_80_00
                    // 00: SDv2.0, c0: SDHCv2
                    cmd_out <= 48'h7a_00_00_00_00_FD;
                    bit_counter <= 47;
                    response_type <= 3'b11;
                    return_state <= IDLE; // CMD16
                    state <= PRE_SEND_CMD;
                end
                CMD16: begin
                    // returns 00 if OK
                    cmd_out <= 48'h50_00_00_02_00_15;
                    bit_counter <= 47;
                    response_type <= 3'b1;
                    return_state <= IDLE;
                    state <= PRE_SEND_CMD;
                end
                IDLE: begin
                    cs <= 1'b1;
                    if(rd == 1) begin
                        state <= READ_BLOCK;
                    end
                    else if(wr == 1) begin
                        state <= WRITE_BLOCK_CMD;
                    end
                    else begin
                        state <= IDLE;
                    end
                    //sclk_sig <= ~sclk_sig;
                end
                READ_BLOCK: begin
                    cmd_out <= {8'h51, address, 8'hFF};
                    bit_counter <= 47;
                    response_type <= 3'b1;
                    return_state <= READ_BLOCK_WAIT;
                    state <= PRE_SEND_CMD;
                end
                READ_BLOCK_WAIT: begin
                    cs <= 1'b0;
                    if(sclk_sig == 1 && miso == 0) begin
                        byte_counter <= 511;
                        bit_counter <= 7;
                        return_state <= READ_BLOCK_DATA;
                        state <= RECEIVE_BYTE;
                    end
                    sclk_sig <= ~sclk_sig;
                end
                READ_BLOCK_DATA: begin
                    dout <= recv_data;
                    byte_available <= 1;
                    if (byte_counter == 0) begin
                        bit_counter <= 7;
                        return_state <= READ_BLOCK_CRC;
                        state <= RECEIVE_BYTE;
                    end
                    else begin
                        byte_counter <= byte_counter - 1;
                        return_state <= READ_BLOCK_DATA;
                        bit_counter <= 7;
                        state <= RECEIVE_BYTE;
                    end
                end
                READ_BLOCK_CRC: begin
                    bit_counter <= 7;
                    return_state <= IDLE;
                    state <= RECEIVE_BYTE;
                end
                PRE_SEND_CMD: begin
                    cs <= 1'b0;
                    sclk_sig <= 1'b0;
                    state <= SEND_CMD;
                end
                SEND_CMD: begin
                    if (sclk_sig == 1) begin
                        if (bit_counter == 0) begin
                            state <= RECEIVE_BYTE_WAIT;
                        end
                        else begin
                            bit_counter <= bit_counter - 1;
                            cmd_out <= {cmd_out[46:0], 1'b1};
                        end
                    end
                    sclk_sig <= ~sclk_sig;
                end
                RECEIVE_BYTE_WAIT: begin
                    if (sclk_sig == 1) begin
                        if (miso == 0) begin
                            recv_data <= 8'b0;
                            recv_data_r7 <= 40'b0;
                            case (response_type)
                                1: bit_counter <= 6;
                                3: bit_counter <= 38;
                                7: bit_counter <= 38;
                                default: bit_counter <= 6;
                            endcase
                            state <= RECEIVE_BYTE;
                        end
                    end
                    sclk_sig <= ~sclk_sig;
                end
                RECEIVE_BYTE: begin
                    byte_available <= 0;
                    if (sclk_sig == 1) begin
                        recv_data <= {recv_data[6:0], miso};
                        if (response_type != 3'b1) begin
                            recv_data_r7 <= {recv_data_r7[38:0], miso};
                        end
                        if (bit_counter == 0) begin
                            bit_counter <= 7;
                            state <= return_state; //RECEIVE_BYTE_AFTERWAIT;
                            if (return_state != READ_BLOCK_WAIT && return_state != READ_BLOCK_DATA && return_state != READ_BLOCK_CRC && 
                                return_state != WRITE_BLOCK_INIT && return_state != WRITE_BLOCK_DATA && return_state != WRITE_BLOCK_WAIT)
                                cs <= 1'b1;
                        end
                        else begin
                            bit_counter <= bit_counter - 1;
                        end
                    end
                    sclk_sig <= ~sclk_sig;
                end
                RECEIVE_BYTE_AFTERWAIT: begin
                    bit_counter <= bit_counter - 1;
                    if (bit_counter == 0) begin
                        state <= return_state;
                        //cs <= 1'b0;
                    end
                    sclk_sig <= ~sclk_sig;
                end
                WRITE_BLOCK_CMD: begin
                    cmd_out <= {8'h58, address, 8'hFF};
                    bit_counter <= 47;
                    return_state <= WRITE_BLOCK_INIT;
                    response_type <= 1;
                    state <= PRE_SEND_CMD;
                    ready_for_next_byte <= 1;
                end
                WRITE_BLOCK_INIT: begin
                    cmd_mode <= 0;
                    byte_counter <= WRITE_DATA_SIZE; 
                    state <= WRITE_BLOCK_DATA;
                    ready_for_next_byte <= 0;
                end
                WRITE_BLOCK_DATA: begin
                    if (byte_counter == 0) begin
                        state <= RECEIVE_BYTE_WAIT;
                        return_state <= WRITE_BLOCK_WAIT;
                    end
                    else begin
                        if ((byte_counter == 2) || (byte_counter == 1)) begin
                            data_sig <= 8'hFF;
                        end
                        else if (byte_counter == WRITE_DATA_SIZE) begin
                            data_sig <= 8'hFE;
                        end
                        else begin
                            data_sig <= din;
                            ready_for_next_byte <= 1;
                        end
                        bit_counter <= 7;
                        state <= WRITE_BLOCK_BYTE;
                        byte_counter <= byte_counter - 1;
                    end
                end
                WRITE_BLOCK_BYTE: begin
                    if (sclk_sig == 1) begin
                        if (bit_counter == 0) begin
                            state <= WRITE_BLOCK_DATA;
                            ready_for_next_byte <= 0;
                        end
                        else begin
                            data_sig <= {data_sig[6:0], 1'b1};
                            bit_counter <= bit_counter - 1;
                        end;
                    end;
                    sclk_sig <= ~sclk_sig;
                end
                WRITE_BLOCK_WAIT: begin
                    if (sclk_sig == 1) begin
                        if (miso == 1) begin
                            state <= IDLE;
                            cmd_mode <= 1;
                        end
                    end
                    sclk_sig <= ~sclk_sig;
                end
            endcase
            end
        end
    end

    assign sclk = sclk_sig;
    assign mosi = cmd_mode ? cmd_out[47] : data_sig[7];
    assign ready = (state == IDLE);
endmodule
