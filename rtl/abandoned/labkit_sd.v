/* Labkit project demonstrating SD controller use. */

`timescale 1ns / 1ps

// Be sure to enable SD_CD, SD_RESET, SD_SCK, SD_CMD, and SD_DAT in the
// constraints file.
module labkit(input CLK100MHZ, input SD_CD, output SD_RESET, output SD_SCK, output SD_CMD, 
	inout [3:0] SD_DAT, output [15:0] LED, input BTNC);

    // Clock the SD card at 25 MHz.
	wire clk_100mhz = CLK100MHZ;
    wire clk_50mhz;
    wire clk_25mhz;
    clock_divider div1(clk_100mhz, clk_50mhz);
    clock_divider div2(clk_50mhz, clk_25mhz);

    wire rst = BTNC;
    wire spiClk;
    wire spiMiso;
    wire spiMosi;
    wire spiCS;

    // MicroSD SPI/SD Mode/Nexys 4
    // 1: Unused / DAT2 / SD_DAT[2]
    // 2: CS / DAT3 / SD_DAT[3]
    // 3: MOSI / CMD / SD_CMD
    // 4: VDD / VDD / ~SD_RESET
    // 5: SCLK / SCLK / SD_SCK
    // 6: GND / GND / - 
    // 7: MISO / DAT0 / SD_DAT[0]
    // 8: UNUSED / DAT1 / SD_DAT[1]
    assign SD_DAT[2] = 1;
    assign SD_DAT[3] = spiCS;
    assign SD_CMD = spiMosi;
    assign SD_RESET = 0;
    assign SD_SCK = spiClk;
    assign spiMiso = SD_DAT[0];
    assign SD_DAT[1] = 1;
    
    reg rd = 0;
    reg wr = 0;
    reg [7:0] din = 0;
    wire [7:0] dout;
    wire byte_available;
    wire ready;
    wire ready_for_next_byte;
    reg [31:0] adr = 32'h00_00_00_00;
    
    reg [15:0] bytes = 0;
    reg [1:0] bytes_read = 0;
    
    wire [4:0] state;
    
    parameter STATE_INIT = 0;
    parameter STATE_START = 1;
    parameter STATE_WRITE = 2;
    parameter STATE_READ = 3;
    reg [1:0] test_state = STATE_INIT; 
    assign LED = {state, ready, test_state, bytes[15:8]};
    
    sd_controller sdcont(.cs(spiCS), .mosi(spiMosi), .miso(spiMiso),
            .sclk(spiClk), .rd(rd), .wr(wr), .reset(rst),
            .din(din), .dout(dout), .byte_available(byte_available),
            .ready(ready), .address(adr), 
            .ready_for_next_byte(ready_for_next_byte), .clk(clk_25mhz), 
            .status(state));
    

    always @(posedge clk_25mhz) begin
        if(rst) begin
            bytes <= 0;
            bytes_read <= 0;
            din <= 0;
            wr <= 0;
            rd <= 0;
            test_state <= STATE_INIT; 
        end
        else begin
            case (test_state)
                STATE_INIT: begin
                    if(ready) begin
                        test_state <= STATE_START;
                        wr <= 1;
                        din <= 8'hAA;
                    end
                end
                STATE_START: begin
                    if(ready == 0) begin
                        test_state <= STATE_WRITE;
                        wr <= 0;
                    end
                end
                STATE_WRITE: begin
                    if(ready) begin
                        test_state <= STATE_READ;
                        rd <= 1;
                    end
                    else if(ready_for_next_byte) begin
                        din <= 8'hAA;
                    end
                end
                STATE_READ: begin
                    if(byte_available) begin
                        rd <= 0;
                        if(bytes_read == 0) begin
                            bytes_read <= 1;
                            bytes[15:8] <= dout;
                        end
                        else if(bytes_read == 1) begin
                            bytes_read <= 2;
                            bytes[7:0] <= dout;
                            
                        end
                    end
                end
            endcase
        end
    end
endmodule
