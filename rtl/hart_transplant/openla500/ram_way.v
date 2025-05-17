// SPDX-License-Identifier: GPL-3.0-or-later
// Author: regymm

`timescale 1ns / 1ps
module data_bank_sram (
		input clka, 
		input [7:0]addra,
		input [31:0]dina,
		input [3:0]wea,
        input ena,
		output reg [31:0]douta
	);

	reg [31:0]mem[255:0];
    //integer i;
    //initial begin
        //for (i = 0; i < 256; i=i+1)
            //mem[i] = 32'b0;
    //end

	always @ (posedge clka) begin
        if (ena) begin
			if (wea[0]) mem[addra][7:0] <= dina[7:0];
			if (wea[1]) mem[addra][15:8] <= dina[15:8];
			if (wea[2]) mem[addra][23:16] <= dina[23:16];
			if (wea[3]) mem[addra][31:24] <= dina[31:24];
            douta <= mem[addra];
        end else begin
            douta <= 0;
        end
	end
endmodule

module tagv_sram (
		input clka, 
		input [7:0]addra,
		input [20:0]dina,
		input [0:0]wea,
        input ena,
		output reg [20:0]douta
	);

	reg [20:0]mem[255:0];
    //integer i;
    //initial begin
        //for (i = 0; i < 256; i=i+1)
            //mem[i] = 21'b0;
    //end

	always @ (posedge clka) begin
        if (ena) begin
            if (wea) begin
                mem[addra] <= dina;
            end
            douta <= mem[addra];
        end else begin
            douta <= 0;
        end
	end
endmodule
