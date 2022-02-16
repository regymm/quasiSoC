/**
 * File              : privilege.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.12.26
 * Last Modified Date: 2021.01.03
 */
`timescale 1ns / 1ps

// exception: CPU issued and write data to privilege. CPU gives mcause
// interrupt: privilege issued, CPU only gets a signal and gives pc. privilege maintains mcause
// then in exception/interrupt handler, CPU assembly gets all required info(CSRs) from privilege
//
// a small naming convention:
//  irq means sending single pulse,
//  interrupt/int_reply means sending high until reply
module privilege
	(
		input clk,
		input rst,

		input [11:0]a,
		input [31:0]d,
		input we,
		output reg [31:0]spo,

		// from interrupt.v
		// TODO: PLIC!!
		input eip,
		output reg eip_reply,

		// from timer.v
		input tip,

		//input mtval_we,
		//input [31:0]mtval_d,

		// for CPU exception
		input on_exc_enter,
		input on_exc_isint,
		input [31:0]pc_in,
		input [3:0]mcause_code_in,
		output [31:0]mtvec_out,
		// for CPU mret
		input on_exc_leave,
		output [31:0]mepc_out,

		// interrupt that goes into CPU directly
		// reply also by CPU
		output reg interrupt,
		input int_reply
    );

	reg mode = 1; // default 11 machine mode, 00 dummy user mode

	// Control State Registers
	(*mark_debug = "true"*)reg [31:0]mstatus = 32'b0_00000000_0000000000_00_00_0_0_;
	reg [31:0]misa = 32'b01_0000_00000000000001000100000000;
	(*mark_debug = "true"*)reg [31:0]mie;
	(*mark_debug = "true"*)reg [31:0]mtvec;
	(*mark_debug = "true"*)reg [31:0]mscratch;
	(*mark_debug = "true"*)reg [31:0]mepc;
	reg [31:0]mcause;
	(*mark_debug = "true"*)reg [31:0]mtval;
	(*mark_debug = "true"*)reg [31:0]mip;

	assign mepc_out = mepc_reg;
	reg [31:0]mepc_reg;
	always @ (posedge clk) begin
		mepc_reg <= mepc;
	end

	assign mtvec_out = mtvec_reg;
	reg [31:0]mtvec_reg;
	always @ (posedge clk) begin
		mtvec_reg <= mtvec;
	end
	//assign mtvec_out = mtvec;

	//reg [63:0]mtime;
	//reg [63:0]mtimecmp;

	//wire [31:0]mstatus_wpri_mask = 32'b01111111100000000000011001000100; // WPRI otherwise
	wire [31:0]mstatus_read_mask	= 32'b11111111111111111110011101110111;
	wire [31:0]mstatus_read_val		= 32'b0000000000000000000xx000x000x000;
	wire [31:0]mstatus_write_mask	= 32'b11111111111111111110011101110111;
	wire [31:0]mtvec_read_mask		= 32'b00000000000000000000000000000011;
	wire [31:0]mtvec_read_val		= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00;
	wire [31:0]mtvec_write_mask		= 32'b00000000000000000000000000000011;
	wire [31:0]mip_read_mask		= 32'b11111111111111111111111111110111;
	wire [31:0]mip_read_val			= {20'b0, eip, 3'b0, tip, 3'b0, 1'bx, 3'b0};
	wire [31:0]mip_write_mask		= 32'b11111111111111111111111111110111; // WARL otherwise
	wire [31:0]mie_read_mask		= 32'b00000000000000000000100010001000;
	wire [31:0]mie_read_val			= 32'b00000000000000000000x000x000x000;
	wire [31:0]mie_write_mask		= 32'b11111111111111111111011101110111; // WARL otherwise
	wire [31:0]mepc_read_mask		= 32'b00000000000000000000000000000011;
	wire [31:0]mepc_read_val		= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00;
	wire [31:0]mepc_write_mask		= 32'b00000000000000000000000000000011;
	//wire [31:0]mip_wpri_mask		= 32'b111111111010001000100; // WARL otherwise


	//reg [31:0]sstatus;
	//reg [31:0]sie;
	//reg [31:0]stvec;
	//reg [31:0]sscratch;
	//reg [31:0]sepc;
	//reg [31:0]scause;
	//reg [31:0]stval;
	//reg [31:0]sip;

	//reg [31:0]satp;

	//reg [31:0]misa;
	//reg [31:0]timee;
	//reg [31:0]timeeh;

	//wire mcause_isinterrupt = mcause[31];
	//wire mstatus_mie = mstatus[3];
	//wire mstatus_mpie = mstatus[7];
	
	wire mstatus_mie = mstatus[3];
	wire [1:0]mstatus_mpp = mstatus[12:11];
	wire mip_sip = mip[4];
	wire meie = mie[11];
	wire mtie = mie[7];
	wire msie = mie[3];

	always @ (*) begin
		case (a)
			//12'h100: spo = sstatus;
			//12'h104: spo = sie;
			//12'h105: spo = stvec;
			//12'h140: spo = sscratch;
			//12'h141: spo = sepc;
			//12'h142: spo = scause;
			//12'h143: spo = stval;
			//12'h144: spo = sip;
			//12'h180: spo = satp;

			12'h300: spo = mstatus_read_val & mstatus_read_mask + mstatus & ~mstatus_read_mask;
			12'h301: spo = misa;
			12'h304: spo = mie_read_val & mie_read_mask + mie & ~mie_read_mask;
			12'h305: spo = mtvec_read_val & mtvec_read_mask + mtvec & ~mtvec_read_mask;
			12'h340: spo = mscratch;
			12'h341: spo = mepc_read_val & mepc_read_mask + mepc & ~mepc_read_mask;
			12'h342: spo = mcause;
			12'h343: spo = mtval;
			12'h344: spo = mip_read_val & mip_read_mask + mip & ~mip_read_mask;

			//12'hC01: spo = timee;
			//12'hC81: spo = timeeh;

			default: spo = 0;
		endcase
	end

	always @ (posedge clk) begin
		if (rst) begin
			mode <= 1'b1;
			mstatus <= 32'b00000000000000000001100010000000;
			misa <= 32'b01_0000_00000000000001000100000000;
			mie <= 32'b0;
			mtvec <= 32'b0;
			mscratch <= 32'b0;
			mepc <= 32'b0;
			mcause <= 32'b0;
			mtval <= 32'b0;
			mip <= 32'b0;
		end else begin
			if (we) case (a)
				// normal CSR command IO
				12'h300: mstatus	<= (mstatus & mstatus_write_mask) + (d & ~mstatus_write_mask);
				12'h304: mie		<= (mie & mie_write_mask) + (d & ~mie_write_mask);
				12'h305: mtvec		<= (mtvec & mtvec_write_mask) + (d & ~mtvec_write_mask);
				12'h340: mscratch	<= d;
				12'h341: mepc		<= (mepc & mepc_write_mask) + (d & ~mepc_write_mask);
				12'h342: mcause		<= d; // WLRL, should be taken care of but not now
				12'h343: mtval		<= d; // should be taken care of
				12'h344: mip		<= (mip & mip_write_mask) + (d & ~mip_write_mask);
				default: ;
			endcase
			else if (on_exc_enter) begin
				// interrupt or exception
				// enter M-mode, MPP to previous mode
				mstatus <= {mstatus[31:13], mode, mode, mstatus[10:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
				mode <= 1'b1;
				mepc <= pc_in;
				if (on_exc_isint) begin
					mcause <= {1'b1, 27'b0, mcause_i_code};
				end else begin
					mcause <= {1'b0, 27'b0, mcause_code_in};
				end
			end else if (on_exc_leave) begin
				// mret, MPP set to 00, mode set to MPP
				mstatus <= {mstatus[31:13], 2'b0, mstatus[10:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]};
				mode <= (mstatus_mpp == 2'b0) ? 1'b0 : 1'b1;
			end
		end
	end

	reg int_reply_reg;
	reg int_pending;
	reg eip_reg;
	reg tip_reg;
	reg meie_reg;
	reg mtie_reg;
	reg [1:0]int_source;
	always @ (posedge clk) begin
		int_reply_reg <= int_reply;
		int_pending <= mstatus_mie & (eip&meie | tip&mtie | mip_sip&msie);
		eip_reg <= eip;
		tip_reg <= tip;
		meie_reg <= meie;
		mtie_reg <= mtie;
	end

	localparam IDLE = 2'b00;
	localparam ISSUE = 2'b01;
	localparam REPLY = 2'b10;
	localparam END = 2'b11;
	reg [1:0]state = IDLE;
	reg [3:0]mcause_i_code;
	always @ (posedge clk) begin
		if (rst) begin
			state <= IDLE;
			interrupt <= 0;
			eip_reply <= 0;
		end else begin
			case (state)
				IDLE: begin
					if (int_pending) begin
						int_source <= {eip_reg&meie_reg, tip_reg&mtie_reg};
						state <= ISSUE;
					end
				end
				ISSUE: begin
					interrupt <= 1;
					if (int_source[1]) begin
						// external
						eip_reply <= 1;
						mcause_i_code <= 4'd11;
					end else if (int_source[0]) begin
						// timer
						mcause_i_code <= 4'd7;
					end else
						// software
						mcause_i_code <= 4'd3;
					state <= REPLY;
				end
				REPLY: begin
					eip_reply <= 0;
					if (int_reply_reg) begin
						interrupt <= 0;
						state <= END;
					end
				end
				END: begin
					state <= IDLE;
				end
				//default: state <= IDLE;
			endcase
		end
	end
endmodule
