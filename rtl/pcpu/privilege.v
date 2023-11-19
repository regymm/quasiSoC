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
		output csrexp,

		// timer/external interrupt from outside
		input m_tip,
		input m_eip,
		output reg m_eip_reply,

		// for CPU exception
		input on_exc_enter,
		input on_exc_isint,
		input [31:0]pc_in,
		input [3:0]mcause_code_in,
		output [31:0]mtvec_out,
		// for CPU mret
		input on_exc_leave,
		input on_exc_ismret,
		output [31:0]mepc_out,
		output [31:0]sepc_out,

		// interrupt that goes into CPU directly, reply also by CPU
		output reg interrupt,
		input int_reply,

		// 11 machine mode, 01 supervisor, 00 dummy user mode
		output reg [1:0]mode = 2'b11,

		output paging,
		output [21:0]ppn
    );


	// Control State Registers
	(*mark_debug = "true"*)reg [31:0]mstatus;
	reg [31:0]misa;
	reg [31:0]mideleg = 0;
	reg [31:0]medeleg = 0;
	(*mark_debug = "true"*)reg [31:0]mie;
	(*mark_debug = "true"*)reg [31:0]mtvec;
	(*mark_debug = "true"*)reg [31:0]mscratch;
	(*mark_debug = "true"*)reg [31:0]mepc;
	reg [31:0]mcause;
	(*mark_debug = "true"*)reg [31:0]mtval;
	(*mark_debug = "true"*)reg [31:0]mip = 0;

	reg [31:0]mepc_reg;
	reg [31:0]sepc_reg;
	always @ (posedge clk) begin
		mepc_reg <= mepc;
		sepc_reg <= sepc;
	end
	assign mepc_out = mepc_reg;
	assign sepc_out = sepc_reg;

	reg [31:0]mtvec_reg;
	always @ (posedge clk) begin
		mtvec_reg <= mtvec;
	end
	assign mtvec_out = mtvec_reg;
	// we don't have stvec_out


	//wire [31:0]mstatus_wpri_mask = 32'b01111111100000000000011001000100; // WPRI otherwise
	//wire [31:0]mstatus_read_mask	= 32'b11111111111111111110011101110111;
	//wire [31:0]mstatus_read_val		= 32'b0000000000000000000zz000z000z000;
	//wire [31:0]mstatus_write_mask	= 32'b11111111111111111110011101110111;
	//wire [31:0]mtvec_read_mask		= 32'b00000000000000000000000000000011;
	//wire [31:0]mtvec_read_val		= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz00;
	//wire [31:0]mtvec_write_mask		= 32'b00000000000000000000000000000011;
	//wire [31:0]mip_read_mask		= 32'b11111111111111111111111111110111;
	//wire [31:0]mip_read_val			= {20'b0, eip, 3'b0, tip, 3'b0, sip, 3'b0};
	//wire [31:0]mip_write_mask		= 32'b11111111111111111111111111110111; // WARL otherwise
	//wire [31:0]mie_read_mask		= 32'b00000000000000000000100010001000;
	//wire [31:0]mie_read_val			= 32'b00000000000000000000z000z000z000;
	//wire [31:0]mie_write_mask		= 32'b11111111111111111111011101110111; // WARL otherwise
	//wire [31:0]mepc_read_mask		= 32'b00000000000000000000000000000011;
	//wire [31:0]mepc_read_val		= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz00;
	//wire [31:0]mepc_write_mask		= 32'b00000000000000000000000000000011;
	//wire [31:0]mip_wpri_mask		= 32'b111111111010001000100; // WARL otherwise

	// having Z or X in read val is not good, thought they are mask
	//                                                  S      M   I        A
	wire [31:0]misa_init			= 32'b01000000_00000100_00010001_00000001;

	//                                                         MM    M S     
	//                                                         PP  S P P M S 
	//                                                         PP  P I I I I 
	//                                                         10  P E E E E 
	wire [31:0]mstatus_init			= 32'b00000000_00000000_00011001_10100000;
	wire [31:0]mstatus_read_mask	= 32'b11111111_11111111_11100110_01010101;
	wire [31:0]mstatus_read_val		= 32'b0;
	wire [31:0]mstatus_write_mask	= mstatus_read_mask;
	wire [31:0]sstatus_read_mask	= 32'b11111111_11111111_11111110_11011101;
	wire [31:0]sstatus_read_val		= 32'b0;
	wire [31:0]sstatus_write_mask	= sstatus_read_mask;

	wire [31:0]mtvec_read_mask		= 32'b00000000_00000000_00000000_00000011;
	wire [31:0]mtvec_read_val		= 32'b0;
	wire [31:0]mtvec_write_mask		= mtvec_read_mask;
	wire [31:0]stvec_read_mask		= mtvec_read_mask;
	wire [31:0]stvec_read_val		= mtvec_read_val;
	wire [31:0]stvec_write_mask		= mtvec_write_mask;

	wire [31:0]mip_read_mask		= 32'b11111111_11111111_11111101_11011101;
	wire [31:0]mip_read_val			= {20'b0, m_eip, 1'b0, 1'b0, 1'b0,
											  m_tip, 1'b0, 1'b0, 1'b0,
											  1'b0,  1'b0, 1'b0, 1'b0};
	wire [31:0]mip_write_mask		= 32'b11111111_11111111_11111101_11011101;
	// in our no-delegate implementation, sip is only writen by M-mode SBI
	// Linux kernel doesn't use sip, but relies on sie for interrupt control
	// so our SBI will monitor sie to decide whether pass on the interrupt to S-mode kernel
	wire [31:0]sip_read_mask		= 32'b11111111_11111111_11111111_11111111;
	wire [31:0]sip_read_val			= 32'b0;
	wire [31:0]sip_write_mask		= 32'b11111111_11111111_11111111_11111111;

	//                                                          M S  M S M S  
	//                                                          E E  T T S S  
	//                                                          I I  I I I I  
	//                                                          E E  E E E E  
	wire [31:0]mie_read_mask		= 32'b11111111_11111111_11110101_01010101;
	wire [31:0]mie_read_val			= 32'b0;
	wire [31:0]mie_write_mask		= mie_read_mask; // WARL otherwise
	wire [31:0]sie_read_mask		= 32'b11111111_11111111_11111101_11011101;
	wire [31:0]sie_read_val			= 32'b0;
	wire [31:0]sie_write_mask		= sie_read_mask; // WARL otherwise

	wire [31:0]mepc_read_mask		= 32'b00000000_00000000_00000000_00000011;
	wire [31:0]mepc_read_val		= 32'b0;
	wire [31:0]mepc_write_mask		= mepc_read_mask;
	wire [31:0]sepc_read_mask		= mepc_read_mask;
	wire [31:0]sepc_read_val		= 32'b0;
	wire [31:0]sepc_write_mask		= mepc_write_mask;

	wire [31:0]satp_read_mask		= 32'b01111111_11000000_00000000_00000000;
	wire [31:0]satp_read_val		= 32'b0;
	wire [31:0]satp_write_mask		= satp_read_mask;

	reg [31:0]stvec;
	reg [31:0]sscratch;
	reg [31:0]sepc;
	reg [31:0]scause;
	reg [31:0]stval;
	reg [31:0]satp;

	
	// some aliases
	wire mstatus_mpie = mstatus[7];
	wire mstatus_spie = mstatus[5];
	wire mstatus_mie = mstatus[3];
	wire mstatus_sie = mstatus[1];
	wire [1:0]mstatus_mpp = mstatus[12:11];
	wire mstatus_spp = mstatus[8];

	wire meie = mie[11];
	wire mtie = mie[7];
	wire msie = mie[3];

	//wire mcause_isinterrupt = mcause[31];
	//wire mstatus_mie = mstatus[3];

	assign paging = satp[31];
	assign ppn = satp[21:0];

	always @ (*) begin
		case (a)
			12'h100: spo = sstatus_read_val & sstatus_read_mask | mstatus & ~sstatus_read_mask;
			12'h104: spo = sie_read_val & sie_read_mask | mie & ~sie_read_mask;
			12'h105: spo = stvec_read_val & stvec_read_mask | stvec & ~stvec_read_mask;
			12'h140: spo = sscratch;
			12'h141: spo = sepc_read_val & sepc_read_mask | sepc & ~sepc_read_mask;
			12'h142: spo = scause;
			12'h143: spo = stval;
			12'h144: spo = sip_read_val & sip_read_mask | mip & ~sip_read_mask;
			12'h180: spo = satp_read_val & satp_read_mask | satp & ~satp_read_mask;

			12'h300: spo = mstatus_read_val & mstatus_read_mask | mstatus & ~mstatus_read_mask;
			12'h301: spo = misa;
			12'h302: spo = medeleg;
			12'h303: spo = mideleg;
			12'h304: spo = mie_read_val & mie_read_mask | mie & ~mie_read_mask;
			12'h305: spo = mtvec_read_val & mtvec_read_mask | mtvec & ~mtvec_read_mask;
			12'h340: spo = mscratch;
			12'h341: spo = mepc_read_val & mepc_read_mask | mepc & ~mepc_read_mask;
			12'h342: spo = mcause;
			12'h343: spo = mtval;
			12'h344: spo = mip_read_val & mip_read_mask | mip & ~mip_read_mask;

			default: spo = 0;
		endcase
	end
	// time and timeh access is forwarded to M mode
	assign csrexp = a == 12'hc01 || a == 12'hc81;

	always @ (posedge clk) begin
		if (rst) begin
			mode <= 2'b11;

			mstatus <= mstatus_init;
			misa <= misa_init;
			mie <= 32'b0;
			mtvec <= 32'b0;
			mscratch <= 32'b0;
			mepc <= 32'b0;
			mcause <= 32'b0;
			mtval <= 32'b0;

			stvec <= 32'b0;
			sscratch <= 32'b0;
			sepc <= 32'b0;
			scause <= 32'b0;
			stval <= 32'b0;
			satp <= 32'b0;
		end else begin
			if (we) case (a)
				// normal CSR command IO
				12'h100: mstatus	<= (mstatus & sstatus_write_mask) + (d & ~sstatus_write_mask);
				12'h104: mie		<= (mie & sie_write_mask) + (d & ~sie_write_mask);
				12'h105: stvec		<= (stvec & stvec_write_mask) + (d & ~stvec_write_mask);
				12'h140: sscratch	<= d;
				12'h141: sepc		<= (sepc & sepc_write_mask) + (d & ~sepc_write_mask);
				12'h142: scause		<= d; // probably not used by kernel
				12'h143: stval		<= d; // probably not used by kernel
				12'h180: satp		<= (satp & satp_write_mask) + (d & ~satp_write_mask);

				12'h300: mstatus	<= (mstatus & mstatus_write_mask) + (d & ~mstatus_write_mask);
				12'h304: mie		<= (mie & mie_write_mask) + (d & ~mie_write_mask);
				12'h305: mtvec		<= (mtvec & mtvec_write_mask) + (d & ~mtvec_write_mask);
				12'h340: mscratch	<= d;
				12'h341: mepc		<= (mepc & mepc_write_mask) + (d & ~mepc_write_mask);
				12'h342: mcause		<= d; // WLRL, should be taken care of but not now
				12'h343: mtval		<= d; // should be taken care of
				default: ;
			endcase
			else if (on_exc_enter) begin
				// interrupt or exception
				// we do every handling in M-mode, forward to S-mode is done by SBI
				// enter M-mode, MPP to previous mode, disable MIE, MPIE saves previous MIE
				mstatus <= {mstatus[31:13], mode, mstatus[10:8], mstatus_mie, mstatus[6:4], 1'b0, mstatus[2:0]};
				mode <= 2'b11;
				mepc <= pc_in;
				if (on_exc_isint) begin
					mcause <= {1'b1, 27'b0, mcause_i_code};
				end else begin
					mcause <= {1'b0, 27'b0, mcause_code_in};
				end
				// enter S-mode: delegated
				// not now
			end else if (on_exc_leave) begin
				// return from interrupt or exception: mret or sret
				// if mret/sret gets here, it will be legal (not, like, mret from S-mode)
				if (on_exc_ismret) begin
					// mret
					// mode back to MPP, MPP set to 00(U), MIE back to MPIE, MPIE to 1
					mstatus <= {mstatus[31:13], 2'b00, mstatus[10:8], 1'b1, mstatus[6:4], mstatus_mpie, mstatus[2:0]};
					mode <= mstatus_mpp;
				end else begin
					// sret
					// mode back to SPP, SPP to 0(U), SIE back to SPIE, SPIE to 1
					mstatus <= {mstatus[31:9], 1'b0, mstatus[7:6], 1'b1, mstatus[4:2], mstatus_spie, mstatus[0]};
					mode <= {1'b0, mstatus_spp};
				end
			end
		end
	end

	reg int_reply_reg;
	reg int_pending;
	reg m_tip_reg;
	reg m_eip_reg;
	reg meie_reg;
	reg mtie_reg;
	always @ (posedge clk) begin
		int_reply_reg <= int_reply;
		int_pending <= mstatus_mie & (m_eip&meie | m_tip&mtie | 0&msie);
		m_eip_reg <= m_eip;
		m_tip_reg <= m_tip;
		meie_reg <= meie;
		mtie_reg <= mtie;
	end

	localparam IDLE = 2'b00;
	localparam ISSUE = 2'b01;
	localparam REPLY = 2'b10;
	localparam END = 2'b11;
	reg [1:0]state = IDLE;
	reg [1:0]int_source;
	reg [3:0]mcause_i_code;
	always @ (posedge clk) begin
		if (rst) begin
			state <= IDLE;
			interrupt <= 0;
			m_eip_reply <= 0;
			int_source <= 0;
			mcause_i_code <= 0;
		end else begin
			case (state)
				IDLE: begin
					if (int_pending) begin
						int_source <= {m_eip_reg&meie_reg, m_tip_reg&mtie_reg};
						state <= ISSUE;
					end
				end
				ISSUE: begin
					interrupt <= 1;
					if (int_source[1]) begin
						// external
						m_eip_reply <= 1;
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
					m_eip_reply <= 0;
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
