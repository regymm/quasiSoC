`timescale 1ns / 1ps
// arbitrator -- N-to-1
// only major master(CPU) has herald signal
// asymm processing: major has highest priority
// priority list: 0 1 2 3
// TODO: later all signal should have hrd

module arbitrator
// instead, tie req to 0 if not used
	//#(
		//parameter M2_ENABLE = 1,
		//parameter M3_ENABLE = 0,
		//parameter M4_ENABLE = 0
	//)
    (
		input clk,
		input rst,

		input req0,
		output gnt0,
		output hrd0,
        input [31:0]a0,
        input [31:0]d0,
        input we0,
        input rd0,
        output reg [31:0]spo0,
        output reg ready0,

		input req1,
		output gnt1,
        input [31:0]a1,
        input [31:0]d1,
        input we1,
        input rd1,
        output reg [31:0]spo1,
        output reg ready1,

		input req2,
		output gnt2,
        input [31:0]a2,
        input [31:0]d2,
        input we2,
        input rd2,
        output reg [31:0]spo2,
        output reg ready2,

		input req3,
		output gnt3,
        input [31:0]a3,
        input [31:0]d3,
        input we3,
        input rd3,
        output reg [31:0]spo3,
        output reg ready3,

		output reg [31:0]a,
		output reg [31:0]d,
		output reg we,
		output reg rd,
		input [31:0]spo,
		input ready,

		output irq
    );

	reg [1:0]gnt;
	// remember major start xfer condition:
	//  gnt0 & !hrd
	assign gnt0 = gnt == 2'b00;
	assign gnt1 = gnt == 2'b01;
	assign gnt2 = gnt == 2'b10;
	assign gnt3 = gnt == 2'b11;
	always @ (*) begin
		spo0 = 0;
		ready0 = 0;
		spo1 = 0;
		ready1 = 0;
		spo2 = 0;
		ready2 = 0;
		spo3 = 0;
		ready3 = 0;
		case (gnt) 
			2'b00: begin
				a = a0;
				d = d0;
				we = we0;
				rd = rd0;
				spo0 = spo;
				ready0 = ready;
			end
			2'b01: begin
				a = a1;
				d = d1;
				we = we1;
				rd = rd1;
				spo1 = spo;
				ready1 = ready;
			end
			2'b10: begin
				a = a2;
				d = d2;
				we = we2;
				rd = rd2;
				spo2 = spo;
				ready2 = ready;
			end
			2'b11: begin
				a = a3;
				d = d3;
				we = we3;
				rd = rd3;
				spo3 = spo;
				ready3 = ready;
			end
			default: begin
				a = 0;
				d = 0;
				we = 0;
				rd = 0;
			end
		endcase
	end
	
	wire mjr_req = req0;
	wire mnr_req = req1 | req2 | req3;
	localparam IDLE = 0;
	localparam MJR = 1;
	localparam MNR1 = 2;
	localparam MNR2 = 3;
	localparam MNR3 = 4;
	reg [2:0]state = IDLE;
	assign hrd0 = (state == IDLE & mnr_req & !mjr_req);
	always @ (*) begin
		case (state) 
			MNR1: gnt = 2'b01;
			MNR2: gnt = 2'b10;
			MNR3: gnt = 2'b11;
			default: gnt = 2'b00;
		endcase
	end

	always @ (posedge clk) begin
		if (rst) begin
			state <= IDLE;
		end else begin
			case (state)
				IDLE: begin
					if (mjr_req) state <= MJR;
					else if (req1) state <= MNR1;
					else if (req2) state <= MNR2;
					else if (req3) state <= MNR3;
				end
				MJR: begin
					if (!req0) state <= IDLE;
				end
				MNR1: begin
					if (!req1) state <= IDLE;
				end
				MNR2: begin
					if (!req2) state <= IDLE;
				end
				MNR3: begin
					if (!req3) state <= IDLE;
				end
				default: state <= IDLE;
			endcase
		end
	end
endmodule
