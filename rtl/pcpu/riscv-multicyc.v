/**
 * File              : riscv-multicyc.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.10.21
 * Last Modified Date: 2022.07.20
 */
// pComputer multicycle RISC-V processor
// currently supported: RV32IM
// todo: A

`timescale 1ns / 1ps
`include "quasi.vh"

module riscv_multicyc
	#(
		parameter START_ADDR = 32'hf0000000,
		parameter INVALID_ADDR = 32'hffffffff
	)
	(
		input clk,
		input rst,

		input tip,
		input sip,
		input eip,
		output eip_reply,

		output req,
		input gnt,
		input hrd,
		output [31:0]a,
		output [31:0]d,
		output we,
		output rd,
		input [31:0]spo,
		input ready
    );

	// basic control signals
	reg PCWrite;
	reg [2:0]PCSrc;
	reg [1:0]IorDorW;
	reg MemRead;
	reg MemWrite;
	wire MemReady;
	reg [2:0]MemSrc;
	reg IRWrite;
	reg [3:0]ALUm;
	reg [1:0]ALUSrcA;
	reg [1:0]ALUSrcB;
	reg RegWrite;
	reg [3:0]RegSrc;
	reg CsrASrc;
	reg CsrDSrc;

	// program counter
	(*mark_debug = "true"*) reg [31:0]pc;
	reg [31:0]oldpc;
	always @ (posedge clk) begin
		if (rst) pc <= START_ADDR;
		else if (PCWrite) begin
			pc <= newpc;
			oldpc <= pc;
		end
	end
	// ~~~~datapath~~~~
	reg [31:0]newpc;
	always @ (*) begin case (PCSrc)
		0: newpc = pc + 4;
		1: newpc = ALUOut2; // Branch
		2: newpc = ALUOut; // JAL
		3: newpc = ALUOut & ~1; // JALR
		`ifdef IRQ_EN
		4: newpc = {mtvec_in[31:2], 2'b0}; // exception, interrupt
		5: newpc = mepc_in;
		`endif
		default: newpc = INVALID_ADDR;
	endcase end

	// instruction register
	(*mark_debug = "true"*) reg [31:0]instruction;
	always @ (posedge clk) begin
		if(IRWrite) instruction <= new_instr;
	end
	// ~~~~datapath~~~~
	wire [31:0]new_instr = memread_data;

    // register file
    reg [31:0]WriteData;
    wire [31:0]ReadData1;
    wire [31:0]ReadData2;
    register_file register_file_inst
    (
        .clk(clk),
		.ra0(instruction[19:15]), // rs1
		.ra1(instruction[24:20]), // rs2
		.wa(instruction[11:7]),   // rd
        .we(RegWrite),
        .wd(WriteData),
        .rd0(ReadData1),
        .rd1(ReadData2)
    );
	reg [31:0]A;
	reg [31:0]B;
	always @ (posedge clk) begin
		A <= ReadData1;
		B <= ReadData2;
	end
	// ~~~~datapath~~~~
	always @ (*) begin case (RegSrc)
		0: WriteData = ALUOut;
		//1: WriteData = mdr;
		2: WriteData = imm;
		3: WriteData = pc; // already +4
		// LOAD
		4: WriteData = loadbyte; // byte
		5: WriteData = loadhalf; // half
		6: WriteData = mdr;
		`ifdef RV32M
		7: WriteData = RV32MOut;
		`endif
		`ifdef IRQ_EN
		8: WriteData = csrreg;
		`endif
		`ifdef RV32A
		9: WriteData = amo_temp;
		10:WriteData = sc_succeeded ? 0 : 1;
		`endif
		default: WriteData = 0;
	endcase end

	// memory(little endian, instr/data)
	assign a = {mem_addr[31:2], 2'b0};
	assign d = {memwrite_data[7:0], memwrite_data[15:8], memwrite_data[23:16], memwrite_data[31:24]};
	assign we = MemWrite;
	assign rd = MemRead;
	wire [31:0]memread_data = {spo[7:0], spo[15:8], spo[23:16], spo[31:24]};
	assign MemReady = ready;
	reg [31:0]mar;
	reg [31:0]mdr;
	always @ (posedge clk) begin
		mdr <= memread_data;
		//mwr <= memwrite_data;
		mar <= mem_addr;
	end
	// ~~~~datapath~~~~
	reg [31:0]mem_addr;
	reg [31:0]memwrite_data;
	always @ (*) begin case (IorDorW)
		0: mem_addr = pc; // instruction
		1: mem_addr = ALUOut; // data
		2: mem_addr = mar; // wait, and lr.w // ???
		default: mem_addr = INVALID_ADDR;
	endcase end
	always @ (*) begin case (MemSrc)
		// STORE
		0: memwrite_data = storebyte; // byte
		1: memwrite_data = storehalf; // half
		2: memwrite_data = ReadData2; // word
		//3: memwrite_data = mwr; // wait
		`ifdef RV32A
		4: memwrite_data = amo_t_op_rs2;
		`endif
		default: memwrite_data = 0;
	endcase end

	// ALU
	wire [31:0]ALUResult;
	alu alu_inst
	(
		.m(ALUm),
		.a(ALUIn1),
		.b(ALUIn2),
		.y(ALUResult)
	);
	reg [31:0]ALUOut;
	reg [31:0]ALUOut2;
	always @ (posedge clk) begin
		ALUOut <= ALUResult;
		ALUOut2 <= ALUOut;
	end
	// ~~~~datapath~~~~
	reg [31:0]ALUIn1;
	reg [31:0]ALUIn2;
	always @ (*) begin case (ALUSrcA)
		0: ALUIn1 = A;
		1: ALUIn1 = pc; // haven't +4
		`ifdef IRQ_EN
		2: ALUIn1 = csrimm;
		`endif
		default: ALUIn1 = 0;
	endcase end
	always @ (*) begin case (ALUSrcB)
		0: ALUIn2 = B;
		1: ALUIn2 = imm;
		`ifdef IRQ_EN
		2: ALUIn2 = csr_spo;
		`endif
		default: ALUIn2 = B;
	endcase end

	// ALU for RV32M
`ifdef RV32M
	reg RV32MStart;

	wire [2:0]RV32Mm;
	wire RV32MReady;
	wire [31:0]RV32MResult;
	wire RV32MException;
	rv32m rv32m_inst
	(
		.clk(clk),
		.start(RV32MStart),
		.a(ALUIn1),
		.b(ALUIn2),
		.m(RV32Mm),
		.finish(RV32MReady),
		.r(RV32MResult),
		.div0(RV32MException)
	);
	assign RV32Mm = instruction[14:12];
	wire is_RV32M = op == OP_R & instruction[25];
	reg [31:0]RV32MOut;
	always @ (posedge clk) begin
		RV32MOut <= RV32MResult;
	end
`endif

	// privilege 
`ifdef IRQ_EN
	reg CsrWe;
	reg CsrSave;
	reg OnExcEnter;
	reg OnExcLeave;
	reg OnExcIsint;
	reg IntReply;

	reg [3:0]mcause_code_out;
	wire [31:0]mtvec_in;
	wire [31:0]mepc_in;

	wire [31:0]csr_a = instruction[31:20];
	wire [31:0]csr_d = ALUOut;
	wire csr_we = CsrWe;
	wire [31:0]csr_spo;

	wire interrupt;
	privilege privilege_inst
	(
		.clk(clk),
		.rst(rst),

		.a(csr_a),
		.d(csr_d),
		.we(csr_we),
		.spo(csr_spo),

		.tip(tip),
		.sip(sip),
		.eip(eip),
		.eip_reply(eip_reply),

		.on_exc_enter(OnExcEnter),
		.on_exc_leave(OnExcLeave),
		.on_exc_isint(OnExcIsint),

		.pc_in(oldpc),
		.mcause_code_in(mcause_code_out),
		.mtvec_out(mtvec_in),
		.mepc_out(mepc_in),

		.interrupt(interrupt),
		.int_reply(IntReply)
	);
	reg [31:0]csrreg;
	always @ (posedge clk) begin
		if (CsrSave) csrreg <= csr_spo;
	end
	wire [31:0]csrimm = {27'b0, instruction[19:15]};

	// privileged instructions
	wire priv_csr = op == OP_PRIV & instruction[14:12] != 3'b0;
	wire priv_wfi = op == OP_PRIV & instruction[14:12] == 3'b0 & instruction[28] & !instruction[25] & !instruction[29];
	wire priv_mret = op == OP_PRIV & instruction[14:12] == 3'b0 & instruction[28] & !instruction[25] & instruction[29];
	wire priv_sfencevma = op == OP_PRIV & instruction[14:12] == 3'b0 & instruction[28] & instruction[25];
	wire priv_ecall = op == OP_PRIV & instruction[14:12] == 3'b0 & !instruction[28] & !instruction[20];
	wire priv_ebreak = op == OP_PRIV & instruction[14:12] == 3'b0 & !instruction[28] & instruction[20];

	localparam EXC_ILLEGAL_INSTRUCTION = 4'd2;
	localparam EXC_BREAKPOINT = 4'd3;
	localparam EXC_LOAD_FAULT = 4'd5;
	localparam EXC_STORE_FAULT = 4'd7;
	localparam EXC_ECALL_FROM_M_MODE = 4'd11;

	// TODO: generalize and improve
	always @ (posedge clk) begin
		if (priv_ebreak)
			mcause_code_out <= EXC_BREAKPOINT;
		else if (priv_ecall)
			mcause_code_out <= EXC_ECALL_FROM_M_MODE;
	end
`endif

`ifdef RV32A
	wire op_a_lr  = (op == OP_AMO) & instruction[31:27] == 5'b00010;
	wire op_a_sc  = (op == OP_AMO) & instruction[31:27] == 5'b00011;
	wire op_a_amo = (op == OP_AMO) & instruction[31:28] != 4'b0001;
	reg AMOTempWrite;
	reg [31:0]amo_temp = 0;
	always @ (posedge clk) begin
		// one cycle only!
		if (AMOTempWrite) amo_temp <= mdr;
	end
	reg [31:0]amo_t_op_rs2;
	always @ (*) begin case (instruction[31:27])
		5'b00001: amo_t_op_rs2 = B;
		5'b00000: amo_t_op_rs2 = amo_temp + B;
		5'b00100: amo_t_op_rs2 = amo_temp ^ B;
		5'b01100: amo_t_op_rs2 = amo_temp & B;
		5'b01000: amo_t_op_rs2 = amo_temp | B;
		// amomin(u) and amomax(u) not used in kernel
		// TODO: implement 
		default: amo_t_op_rs2 = 0;
	endcase end
	// load reserve/store conditional handling
	reg LRValid;
	reg LRInvalid;
	reg lr_valid;
	reg [31:0]lr_addr = 0;
	wire sc_success = lr_valid & lr_addr == ALUOut;
	reg sc_succeeded;
	always @ (posedge clk) begin
		if (rst) begin
			lr_valid <= 0;
		end else begin
			if (LRValid) begin
			//if (phase == WB & op_a_lr) begin
				lr_valid <= 1;
				lr_addr <= mar;
			// sc, succeeded or not, invalidates reservation
			end else if (LRInvalid) begin
			//end else if (phase == MEM & op_a_sc) begin
				lr_valid <= 0;
				sc_succeeded <= sc_success;
			end
		end
	end
`else
	wire op_a_lr  = 0;
	wire op_a_sc  = 0;
	wire op_a_amo = 0;
`endif

	// instruction decode
	localparam OP_LUI	=	7'b0110111;
	localparam OP_AUIPC	=	7'b0010111;
	localparam OP_JAL	=	7'b1101111;
	localparam OP_JALR	=	7'b1100111;
	localparam OP_BR	=	7'b1100011;
	localparam OP_LOAD	=	7'b0000011;
	localparam OP_STORE	=	7'b0100011;
	localparam OP_R_I	=	7'b0010011;
	localparam OP_R		=	7'b0110011; // including RV32M
	localparam OP_FENCE	=	7'b0001111; // FENCE(nop), FENCE.I(nop)
	localparam OP_PRIV	=	7'b1110011; // ENV(ecall, ebreak), CSR, WFI(aka nop), SFENCE.VMA(aka nop), MRET
	localparam OP_AMO	=	7'b0101111; // amoxxx.w.xx, lr.xx, sc.xx
	// TODO: simplify this
	wire inst_srai = instruction[14:12] == 3'b101 & op == OP_R_I & instruction[30] == 1'b1;
	wire [6:0]op = instruction[6:0];
	wire nse = instruction[14];
	reg [31:0]imm;
	wire [31:0]imm_i = {{21{instruction[31]}}, instruction[30:20]};
	wire [31:0]imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
	wire [31:0]imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
	wire [31:0]imm_u = {instruction[31:12], 12'b0};
	wire [31:0]imm_s = {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
	always @ (*) begin
		if (op == OP_LUI | op == OP_AUIPC) imm = imm_u;
		else if (op == OP_R_I | op == OP_LOAD | op == OP_JALR) imm = imm_i;
		else if (op == OP_BR) imm = imm_b;
		else if (op == OP_JAL) imm = imm_j;
		else if (op == OP_STORE) imm = imm_s;
		else if (op == OP_AMO) imm = 0;
		else imm = 0;
	end

	// unaligned memory access
	wire store_unaligned = ~instruction[13];
	wire [31:0]loadbyte;
	wire [31:0]loadhalf;
	reg [31:0]storebyte;
	reg [31:0]storehalf;
	(*mark_debug = "true"*)reg [7:0]loadbyte_byte;
	reg [15:0]loadhalf_half;
	always @ (*) begin case (mar[1:0]) 2'b00: begin
			loadbyte_byte = mdr[7:0];
			storebyte = {mdr[31:8], ReadData2[7:0]};
		end 2'b01: begin
			loadbyte_byte = mdr[15:8];
			storebyte = {mdr[31:16], ReadData2[7:0], mdr[7:0]};
		end 2'b10: begin
			loadbyte_byte = mdr[23:16];
			storebyte = {mdr[31:24], ReadData2[7:0], mdr[15:0]};
		end 2'b11: begin
			loadbyte_byte = mdr[31:24];
			storebyte = {ReadData2[7:0], mdr[23:0]};
	end endcase end
	always @ (*) begin case (mar[1]) 1'b0: begin
			loadhalf_half = mdr[15:0];
			storehalf = {mdr[31:16], ReadData2[15:0]};
		end 1'b1: begin
			loadhalf_half = mdr[31:16];
			storehalf = {ReadData2[15:0], mdr[15:0]};
	end endcase end
	assign loadbyte = nse ? {24'b0, loadbyte_byte}: {{24{loadbyte_byte[7]}}, loadbyte_byte};
	assign loadhalf = nse ? {16'b0, loadhalf_half}: {{16{loadhalf_half[15]}}, loadhalf_half};

	localparam IF			=	10;
	localparam ID_RF		=	20;
	localparam EX			=	30;
	localparam MEM			=	40;
	localparam EXU			=	50;
	localparam MEMU			=	60;
	localparam WB			=	70;
	`ifdef RV32M
	localparam RV32M_WAIT	=	80;
	`endif
	`ifdef RV32A
	localparam RV32A_MEM1	=	81;
	localparam RV32A_WTEMP	=	82;
	localparam RV32A_MEM2	=	83;
	`endif
	localparam INTERRUPT	=	100;
	localparam EXCEPTION	=	110;
	localparam MRET			=	120;
	//localparam ECALL		=	130;
	localparam BAD			=	255;

	// execution phases
	reg [7:0]phase;
	reg [7:0]phase_n;
	wire phase_changing = phase_n != phase;
	always @ (posedge clk) begin
		if (rst) phase <= IF;
		else phase <= phase_n;
	end
	// the memory fuse, to make sure after bus
	// handshake, rd/we is only issued one cycle
	reg mfuse;
	wire phase_with_mem =
		phase == IF | phase == MEM | phase == MEMU
		`ifdef RV32A
		| phase == RV32A_MEM1 | phase == RV32A_MEM2
		`endif
		;
	// to avoid multiple handshaking during intense 
	// memory requests
	wire phase_need_gnt = phase_with_mem | phase == EXU
		`ifdef RV32A
		| phase == RV32A_WTEMP
		`endif
		;
	// bus req/gnt
	wire bus_xfer_ok = gnt & !hrd;
	assign req = !hrd & phase_need_gnt;
	always @ (posedge clk) begin
		if (rst) mfuse <= 1;
		// actually phase_with_mem not needed
		else if (!phase_changing & phase_with_mem & bus_xfer_ok) mfuse <= 0;
		else mfuse <= 1;
	end


	// control signals
	always @ (*) begin
		phase_n = BAD;
		PCWrite = 0;
		PCSrc = 0;
		IorDorW = 0;
		MemRead = 0;
		MemWrite = 0;
		MemSrc = 0;
		IRWrite = 0;
		ALUm = 0;
		ALUSrcA = 0;
		ALUSrcB = 0;
		RegWrite = 0;
		RegSrc = 0;
		CsrASrc = 0;
		CsrDSrc = 0;
		`ifdef RV32M
		RV32MStart = 0;
		`endif
		`ifdef IRQ_EN
		CsrWe = 0;
		CsrSave = 0;
		OnExcEnter = 0;
		OnExcLeave = 0;
		OnExcIsint = 0;
		IntReply = 0;
		`endif
		`ifdef RV32A
		AMOTempWrite = 0;
		LRValid = 0;
		LRInvalid = 0;
		`endif
		case (phase)
			IF: begin
				// bus_xfer_ok needed, because when heralding
				// it's possible to have ready mem but invalid bus
				if (bus_xfer_ok & MemReady) phase_n = ID_RF;
				else phase_n = IF;
				// after getting into ID_RF IRWrite has finished OK
				// ~~~~~~~~~~~~~~~~~~~~
				// wait till bus handshake ready,
				// make sure read is issued
				// if bus is not ready, rd will have no effect
				// have to make sure only one valid rd cycle
				MemRead = mfuse;
				IRWrite = 1;
			end
			ID_RF: begin
				// FENCE, SFENCE.VMA, and WFI does nothing in our simple architecture
				`ifdef IRQ_EN
				if (interrupt) phase_n = INTERRUPT;
				else if (op == OP_FENCE | priv_wfi | priv_sfencevma) phase_n = IF;
				else if (priv_mret) phase_n = MRET;
				else if (priv_ebreak) phase_n = EXCEPTION;
					//mcause_code_out <= EXC_BREAKPOINT;
				else if (priv_ecall) phase_n = EXCEPTION;
					//mcause_code_out <= EXC_ECALL_FROM_M_MODE;
				else
				`endif
				if (op == OP_LUI | op == OP_AUIPC | op == OP_JAL) phase_n = WB;
				else phase_n = EX;
				// ~~~~~~~~~~~~~~~~~~~~
				PCWrite = 1;
				ALUSrcA = 1; ALUSrcB = 1;
			end
			EX: begin
				if (op == OP_STORE | op == OP_LOAD | op_a_lr | op_a_sc) phase_n = MEM;
				`ifdef RV32M
				else if (is_RV32M) phase_n = RV32M_WAIT;
				`endif
				`ifdef RV32A
				else if (op_a_amo) phase_n = RV32A_MEM1;
				`endif
				else phase_n = WB;
				// ~~~~~~~~~~~~~~~~~~~~
				`ifdef RV32M
				RV32MStart = 1;
				`endif
				if (op == OP_R) begin
					ALUm = {instruction[30], instruction[14:12]};
				end else if (op == OP_R_I) begin
					ALUm = {inst_srai ? 1'b1 : 1'b0, instruction[14:12]};
					ALUSrcB = 1;
				end else if (op == OP_JALR) begin
					ALUSrcB = 1;
				end else if (op == OP_BR) begin
					ALUm = instruction[14] ? {2'b0, instruction[14:13]} : 4'b1000;
				end else if (op == OP_LOAD | op == OP_STORE | op_a_lr | op_a_sc | op_a_amo) begin
					ALUSrcB = 1;
				`ifdef IRQ_EN
				end else if (priv_csr) begin
					ALUSrcA = instruction[14] ? 2 : 0;
					ALUSrcB = 2;
					ALUm = {instruction[12], instruction[13], 2'b10};
					CsrSave = 1;
				`endif
				end
			end
			MEM: begin
				if (bus_xfer_ok & MemReady) begin
					if (op == OP_LOAD | op_a_lr | op_a_sc)
						phase_n = WB;
					else if (op == OP_STORE & store_unaligned)
						phase_n = EXU;
					else /* (op == OP_STORE & !store_unaligned)*/
						phase_n = IF;
				end
				else phase_n = MEM;
				// ~~~~~~~~~~~~~~~~~~~~
				// since a/d may not be issued(and then latched by memory
				// module) in one cycle, we have to keep them correct(at
				// least until bus handshake & issue rd/we)
				ALUSrcB = 1;
				IorDorW = 1;
				if (op == OP_LOAD | (op == OP_STORE & store_unaligned) | op_a_lr) begin
					MemRead = mfuse; // Load, SB, SH
				end else if (op == OP_STORE & !store_unaligned) begin
					MemWrite = mfuse;
					MemSrc = 2; // SW
				`ifdef RV32A
				end else if (op_a_sc) begin
					MemWrite = sc_success & mfuse;
					MemSrc = 2;
					LRInvalid = mfuse;
				`endif
				end
			end
			`ifdef RV32A
			RV32A_MEM1: begin
				if (bus_xfer_ok & MemReady) phase_n = RV32A_WTEMP;
				else phase_n = RV32A_MEM1;
				// ~~~~~~~~~~~~~~~~~~~~
				ALUSrcB = 1;
				MemRead = mfuse; IorDorW = 1;
			end
			RV32A_WTEMP: begin
				phase_n = RV32A_MEM2;
				// ~~~~~~~~~~~~~~~~~~~~
				AMOTempWrite = 1;
				ALUSrcB = 1;
			end
			RV32A_MEM2: begin
				if (MemReady) phase_n = WB; // no handshake
				else phase_n = RV32A_MEM2;
				// ~~~~~~~~~~~~~~~~~~~~
				ALUSrcB = 1;
				MemWrite = mfuse; IorDorW = 1;
				MemSrc = 4;
			end
			`endif
			EXU: begin
				phase_n = MEMU;
				// ~~~~~~~~~~~~~~~~~~~~
				IorDorW = 2; // why this?
				ALUSrcB = 1;
			end
			MEMU: begin
				if (MemReady) phase_n = IF; // no handshake
				else phase_n = MEMU;
				// ~~~~~~~~~~~~~~~~~~~~
				ALUSrcB = 1;
				MemWrite = mfuse; IorDorW = 1;
				MemSrc = instruction[13:12]; // SB, SH
			end
			WB: begin
				phase_n = IF;
				// ~~~~~~~~~~~~~~~~~~~~
				RegWrite = 1;
				`ifdef RV32M
				if (is_RV32M) RegSrc = 7; else
				`endif
				if (op == OP_R | op == OP_R_I) RegSrc = 0;
				else if (op == OP_LUI) RegSrc = 2;
				else if (op == OP_AUIPC) RegSrc = 0;
				else if (op == OP_JAL) begin
					RegSrc = 3;
					PCWrite = 1; PCSrc = 2;
				end else if (op == OP_JALR) begin
					RegSrc = 3;
					PCWrite = 1; PCSrc = 3;
				end else if (op == OP_BR) begin
					// TODO: optimize BR phases
					RegWrite = 0;
					PCWrite = (instruction[14] ? instruction[12] : !instruction[12]) ^ |ALUOut; PCSrc = 1;
					//PCWrite = !instruction[12] ^ |ALUOut; PCSrc = 1;
				end else if (op == OP_LOAD) begin // LB, LH, LW, LBU, LHU, LR.W
					RegSrc = {1'b1, instruction[13:12]};
				`ifdef IRQ_EN
				end else if (priv_csr) begin
					RegSrc = 8;
					CsrWe = 1;
				`endif
				`ifdef RV32A
				end else if (op_a_amo) begin RegSrc = 9;
				end else if (op_a_sc) begin RegSrc = 10;
				end else if (op_a_lr) begin
					RegSrc = 6;
					LRValid = 1;
				`endif
				end
			end
			`ifdef RV32M
			RV32M_WAIT: begin
				if (RV32MReady) phase_n = WB;
				else phase_n = RV32M_WAIT;
			end
			`endif
			`ifdef IRQ_EN
			INTERRUPT: begin
				phase_n = IF;
				// ~~~~~~~~~~~~~~~~~~~~
				OnExcEnter = 1;
				OnExcIsint = 1;
				IntReply = 1;
				PCWrite = 1; PCSrc = 4;
			end
			EXCEPTION: begin
				phase_n = IF;
				// ~~~~~~~~~~~~~~~~~~~~
				OnExcEnter = 1;
				PCWrite = 1; PCSrc = 4;
			end
			MRET: begin
				phase_n = IF;
				// ~~~~~~~~~~~~~~~~~~~~
				OnExcLeave = 1;
				PCWrite = 1; PCSrc = 5;
			end
			`endif
			BAD: begin
				phase_n = BAD;
			end
		endcase
	end
endmodule
