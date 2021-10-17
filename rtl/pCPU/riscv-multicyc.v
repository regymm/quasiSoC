/**
 * File              : riscv-multicyc.v
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2020.10.21
 * Last Modified Date: 2021.10.17
 */
// pComputer multicycle RISC-V processor
// currently supported: RV32IM
// todo: A

`timescale 1ns / 1ps
`include "quasi.vh"

module riscv_multicyc
	(
		input clk,
		input rst,

		input eip,
		input eip_istimer,
		output eip_reply,

		output reg [31:0]a,
		output reg [31:0]d,
		output reg we,
		output reg rd,
		input [31:0]spo,
		input ready
    );

	localparam START_ADDR = 32'hf0000000;
	localparam INVALID_ADDR =32'hffffffff;

	(*mark_debug = "true"*) reg [31:0]pc;
	reg [31:0]oldpc;
	(*mark_debug = "true"*) reg [31:0]instruction;

	reg [31:0]A;
	reg [31:0]B;
	reg [31:0]ALUOut;
	reg [31:0]ALUOut2;
	reg [31:0]RV32MOut;
	reg [31:0]mar;
	reg [31:0]mwr;
	reg [31:0]mdr;

	// control signals
	reg PCWrite;
	reg [2:0]PCSrc;
	reg [1:0]IorDorW;
	reg MemRead;
	reg MemWrite;
	reg MemReady;
	reg [1:0]MemSrc;
	reg IRWrite;
	reg IRLate;
	reg [3:0]ALUm;
	reg [1:0]ALUSrcA;
	reg [1:0]ALUSrcB;
	reg RegWrite;
	reg [3:0]RegSrc;
	reg PCOutSrc;
	reg CsrASrc;
	reg CsrDSrc;
	//wire RegDst;


    // register file
    //reg [4:0]WriteRegister;
    reg [31:0]WriteData;
    wire [31:0]ReadData1;
    wire [31:0]ReadData2;
    register_file register_file_inst
    (
        .clk(clk),
		.ra0(instruction[19:15]), // rs1
		.ra1(instruction[24:20]), // rs2
		.wa(instruction[11:7]),   // rd
		//.ra0(instr_new[19:15]), // rs1
		//.ra1(instr_new[24:20]), // rs2
		//.wa(instr_new[11:7]),   // rd
        .we(RegWrite),
        .wd(WriteData),
        .rd0(ReadData1),
        .rd1(ReadData2)
    );

	reg [31:0]instr_new;

	// memory mapper, little endian
	reg [31:0]mem_addr;
	reg [31:0]memwrite_data;
	reg [31:0]memread_data;
	always @ (*) begin
		a = mem_addr;
		d = {memwrite_data[7:0], memwrite_data[15:8], memwrite_data[23:16], memwrite_data[31:24]};
		we = MemWrite;
		rd = MemRead;
		memread_data = {spo[7:0], spo[15:8], spo[23:16], spo[31:24]};
		MemReady = ready;
	end

	// ALU
	reg [31:0]ALUIn1;
	reg [31:0]ALUIn2;
	wire [31:0]ALUResult;
	alu alu_inst
	(
		.m(ALUm),
		.a(ALUIn1),
		.b(ALUIn2),
		.y(ALUResult)
	);

`ifdef RV32M
	// RV32M
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
`else
	//assign RV32MReady = 1;
	//assign RV32MException = 0;
	//assign RV32MResult = 0;
`endif

	// privilege 
`ifdef IRQ_EN
	//reg csrsrc;

	reg [31:0]csr_a;
	reg [31:0]csr_d;
	reg csr_we;
	wire [31:0]csr_spo;

	reg on_exc_enter;
	reg on_exc_leave;
	reg on_exc_isint;

	reg [31:0]pc_out;
	reg [3:0]mcause_code_out;
	wire [31:0]mtvec_in;
	wire [31:0]mepc_in;

	wire interrupt;
	reg int_reply;
	privilege privilege_inst
	(
		.clk(clk),
		.rst(rst),

		.a(csr_a),
		.d(csr_d),
		.we(csr_we),
		.spo(csr_spo),

		.eip(eip),
		.eip_istimer(eip_istimer),
		.eip_reply(eip_reply),

		.on_exc_enter(on_exc_enter),
		.on_exc_leave(on_exc_leave),
		.on_exc_isint(on_exc_isint),

		.pc_in(pc_out),
		.mcause_code_in(mcause_code_out),
		.mtvec_out(mtvec_in),
		.mepc_out(mepc_in),

		.interrupt(interrupt),
		.int_reply(int_reply)
	);
	reg csrsave;
	reg [31:0]csrr;
	//TODO: check width
	wire [31:0]csrimm = {26'b0, instruction[19:15]};
`else
`endif

	// RV32A not on todo list now

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
	localparam OP_AMO	=	7'b0101111;
	// TODO: ECALL, EBREAK(?), 
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

	// unaligned memory access
	wire store_unaligned = ~instruction[13];
	wire [31:0]loadbyte;
	wire [31:0]loadhalf;
	reg [31:0]storebyte;
	reg [31:0]storehalf;
	reg [7:0]loadbyte_byte;
	reg [15:0]loadhalf_half;
	always @ (*) begin case (mar[1:0])
		2'b00: begin
			loadbyte_byte = mdr[7:0];
			storebyte = {mdr[31:8], ReadData2[7:0]};
		end
		2'b01: begin
			loadbyte_byte = mdr[15:8];
			storebyte = {mdr[31:16], ReadData2[7:0], mdr[7:0]};
		end
		2'b10: begin
			loadbyte_byte = mdr[23:16];
			storebyte = {mdr[31:24], ReadData2[7:0], mdr[15:0]};
		end
		2'b11: begin
			loadbyte_byte = mdr[31:24];
			storebyte = {ReadData2[7:0], mdr[23:0]};
		end
	endcase end
	always @ (*) begin case (mar[1])
		1'b0: begin
			loadhalf_half = mdr[15:0];
			storehalf = {mdr[31:16], ReadData2[15:0]};
		end
		1'b1: begin
			loadhalf_half = mdr[31:16];
			storehalf = {ReadData2[15:0], mdr[15:0]};
		end
	endcase end
	assign loadbyte = nse ? {24'b0, loadbyte_byte}: {{24{loadbyte_byte[7]}}, loadbyte_byte};
	assign loadhalf = nse ? {16'b0, loadhalf_half}: {{16{loadhalf_half[15]}}, loadhalf_half};

	// privileged instructions
	wire priv_csr = instruction[14:12] != 3'b0;
	wire priv_wfi = instruction[14:12] == 3'b0 & instruction[28] & !instruction[25] & !instruction[29];
	wire priv_mret = instruction[14:12] == 3'b0 & instruction[28] & !instruction[25] & instruction[29];
	wire priv_sfencevma = instruction[14:12] == 3'b0 & instruction[28] & instruction[25];
	wire priv_ecall = instruction[14:12] == 3'b0 & !instruction[28] & !instruction[20];
	wire priv_ebreak = instruction[14:12] == 3'b0 & !instruction[28] & instruction[20];

	localparam EXC_ILLEGAL_INSTRUCTION = 4'd2;
	localparam EXC_BREAKPOINT = 4'd3;
	localparam EXC_ECALL_FROM_M_MODE = 4'd11;

	`ifdef RV32M
	assign RV32Mm = instruction[14:12];
	wire is_RV32M = instruction[25];
	`endif
	always @ (*) begin
		if (op == OP_LUI | op == OP_AUIPC) imm = imm_u;
		else if (op == OP_R_I | op == OP_LOAD | op == OP_JALR) imm = imm_i;
		else if (op == OP_BR) imm = imm_b;
		else if (op == OP_JAL) imm = imm_j;
		else if (op == OP_STORE) imm = imm_s;
		else imm = 0;
	end
	reg [7:0]phase;
	reg [7:0]phase_n;
	reg [7:0]phase_return;
	reg phase_return_set;
	reg [7:0]phase_return_n;
	localparam IF			=	10;
	//localparam IF_REMEDY	=	20;
	localparam ID_RF		=	30;
	localparam EX			=	40;
	localparam MEM			=	50;
	localparam EXU			=	53;
	localparam MEMU			=	55;
	localparam WB			=	60;
	localparam MEM_WAIT		=	70;
	`ifdef RV32M
	localparam RV32M_WAIT	=	80;
	`endif
	localparam INTERRUPT	=	150;
	localparam EXCEPTION	=	160;
	localparam MRET			=	170;
	//localparam ECALL		=	170;
	localparam BAD			=	255;


	// control signals
	always @ (*) begin
		PCWrite = 0;
		PCSrc = 0;
		//NewInstr = 0;
		IorDorW = 0;
		MemRead = 0;
		MemWrite = 0;
		MemSrc = 0;
		IRWrite = 0;
		IRLate = 0;
		ALUm = 0;
		ALUSrcA = 0;
		ALUSrcB = 0;
		RegWrite = 0;
		RegSrc = 0;
		//RegDst = 0;
		PCOutSrc = 0;
		CsrASrc = 0;
		CsrDSrc = 0;
		`ifdef RV32M
		RV32MStart = 0;
		`endif
		csr_we = 0;
		csrsave = 0;
		on_exc_enter = 0;
		on_exc_leave = 0;
		on_exc_isint = 0;
		int_reply = 0;
		case (phase)
			IF: begin
				MemRead = 1;
				IRWrite = 1;
			end
			//IF_REMEDY: begin
				//IRWrite = 1; IRLate = 1;
			//end
			ID_RF: begin
				PCWrite = 1;
				ALUSrcA = 1; ALUSrcB = 1;
			end
			EX: begin
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
				end else if (op == OP_LOAD | op == OP_STORE) begin
					ALUSrcB = 1;
				end else if (op == OP_PRIV & priv_csr) begin
					ALUSrcA = instruction[14] ? 2 : 0;
					ALUSrcB = 2;
					ALUm = instruction[13] ? {3'b011, instruction[12]} : {4'b1111};
					csrsave = 1;
				end
			end
			MEM: begin
				if (op == OP_LOAD | (op == OP_STORE & store_unaligned)) begin
					MemRead = 1; IorDorW = 1; // Load, SB, SH
				end else if (op == OP_STORE & !store_unaligned) begin
					MemWrite = 1; IorDorW = 1;
					MemSrc = 2; // SW
				end
			end
			EXU: begin
				IorDorW = 2;
				ALUSrcB = 1;
			end
			MEMU: begin
				MemWrite = 1; IorDorW = 1;
				MemSrc = instruction[13:12]; // SB, SH
			end
			WB: begin
				`ifdef RV32M
				if (op == OP_R & is_RV32M) begin
					RegWrite = 1; RegSrc = 7;
				end else
				`endif
				if (op == OP_R | op == OP_R_I) begin
					RegWrite = 1;
				end else if (op == OP_LUI) begin
					RegWrite = 1; RegSrc = 2;
				end else if (op == OP_AUIPC) begin
					RegWrite = 1;
				end else if (op == OP_JAL) begin
					RegWrite = 1; RegSrc = 3;
					PCWrite = 1; PCSrc = 2;
				end else if (op == OP_JALR) begin
					RegWrite = 1; RegSrc = 3;
					PCWrite = 1; PCSrc = 3;
				end else if (op == OP_BR) begin
					PCWrite = (instruction[14] ? instruction[12] : !instruction[12]) ^ |ALUOut; PCSrc = 1;
					//PCWrite = !instruction[12] ^ |ALUOut; PCSrc = 1;
				end else if (op == OP_LOAD) begin // LB, LH, LW, LBU, LHU
					RegWrite = 1; RegSrc = {1'b1, instruction[13:12]};
				end else if (op == OP_PRIV & priv_csr) begin
					RegWrite = 1; RegSrc = 8;
					csr_we = 1;
				end
			end
			MEM_WAIT: begin
				IorDorW = 2;
				MemSrc = 3;
				if (MemReady & phase_return == ID_RF) IRWrite = 1;
			end
			INTERRUPT: begin
				on_exc_enter = 1;
				on_exc_isint = 1;
				int_reply = 1;
				PCWrite = 1; PCSrc = 4;
				PCOutSrc = 0;
			end
			EXCEPTION: begin
				on_exc_enter = 1;
				PCWrite = 1; PCSrc = 4;
				PCOutSrc = 1;
			end
			MRET: begin
				on_exc_leave = 1;
				PCWrite = 1; PCSrc = 5;
			end
		endcase
	end

	// TODO: generalize and improve
	always @ (posedge clk) begin
		if (op == OP_PRIV)
			if (priv_ebreak)
				mcause_code_out <= EXC_BREAKPOINT;
			else if (priv_ecall)
				mcause_code_out <= EXC_ECALL_FROM_M_MODE;
	end

	// phase control
	always @ (*) begin
		phase_n = BAD;
		phase_return_n = BAD;
		phase_return_set = 0;
		case (phase)
			IF:
				if (!MemReady) begin
					phase_n = MEM_WAIT;
					phase_return_set = 1;
					//phase_return_n = IF_REMEDY;
					phase_return_n = ID_RF;
				end else phase_n = ID_RF;
			//IF_REMEDY:
				//phase_n = ID_RF;
			ID_RF:
				// FENCE, SFENCE.VMA, and WFI does nothing in our simple architecture
				if (interrupt) phase_n = INTERRUPT;
				else if (op == OP_FENCE | op == OP_PRIV & (priv_wfi | priv_sfencevma)) phase_n = IF;
				else if (op == OP_PRIV & (priv_mret)) phase_n = MRET;
				else if (op == OP_PRIV & (priv_ebreak)) begin
					phase_n = EXCEPTION;
					//mcause_code_out <= EXC_BREAKPOINT;
				end else if (op == OP_PRIV & (priv_ecall)) begin
					phase_n = EXCEPTION;
					//mcause_code_out <= EXC_ECALL_FROM_M_MODE;
				end else if (op == OP_LUI | op == OP_AUIPC | op == OP_JAL) phase_n = WB;
				else phase_n = EX;
			EX:
				if (op == OP_STORE | op == OP_LOAD)
					phase_n = MEM;
				`ifdef RV32M
				else if (op == OP_R & is_RV32M)
					phase_n = RV32M_WAIT;
				`endif
				else phase_n = WB;
			MEM: begin
				phase_n = MEM_WAIT;
				phase_return_set = 1;
				if (op == OP_LOAD) phase_return_n = WB;
				else if (op == OP_STORE & store_unaligned)
					phase_return_n = EXU;
				else /* op == OP_STORE & !store_unaligned */
					phase_return_n = IF;
			end
			EXU:
				phase_n = MEMU;
			MEMU: begin
				phase_n = MEM_WAIT;
				phase_return_set = 1;
				phase_return_n = IF;
			end
			WB:
				phase_n = IF;
			MEM_WAIT: // including IF_REMEDY
				if (MemReady) begin
					phase_n = phase_return;
					//if (phase_return == ID_RF) begin
						//IRWrite = 1; // IRLate = 1;
					//end
				end
				else phase_n = MEM_WAIT;
			`ifdef RV32M
			RV32M_WAIT: begin
				if (RV32MReady) phase_n = WB;
				else phase_n = RV32M_WAIT;
			end
			`endif
			INTERRUPT:
				phase_n = IF;
			EXCEPTION:
				phase_n = IF;
			MRET:
				phase_n = IF;
			BAD:
				phase_n = BAD;
		endcase
	end

	// control FSM
	always @ (posedge clk) begin
		if (rst) begin
			phase <= IF;
		end
		else begin
			phase <= phase_n;
			if (phase_return_set) phase_return <= phase_return_n;
			case (phase)
				IF: begin
				end
				//IF_REMEDY: begin
				//end
				ID_RF: begin
				end
				EX: begin
				end
				MEM: begin
				end
				EXU: begin
				end
				MEMU: begin
				end
				WB: begin
				end
				MEM_WAIT: begin
				end
				INTERRUPT: begin
				end
				EXCEPTION: begin
				end
				MRET: begin
				end
				BAD: begin
				end
			endcase
		end
	end

	// CPU datapath
	always @ (*) begin case (IorDorW)
		0: mem_addr = pc; // instruction
		1: mem_addr = ALUOut; // data
		2: mem_addr = mar; // wait
		default: mem_addr = INVALID_ADDR;
	endcase end
	reg [31:0]newpc;
	always @ (*) begin case (PCSrc)
		0: newpc = pc + 4;
		1: newpc = ALUOut2; // Branch
		2: newpc = ALUOut; // JAL
		3: newpc = ALUOut & ~1; // JALR
		4: newpc = {mtvec_in[31:2], 2'b0}; // exception, interrupt
		5: newpc = mepc_in;
		default: newpc = INVALID_ADDR;
	endcase end
	always @ (*) begin case (ALUSrcA)
		0: ALUIn1 = A;
		1: ALUIn1 = pc; // haven't +4
		2: ALUIn1 = csrimm;
		default: ALUIn1 = 0;
	endcase end
	always @ (*) begin case (ALUSrcB)
		0: ALUIn2 = B;
		1: ALUIn2 = imm;
		2: ALUIn2 = csr_spo;
		default: ALUIn2 = B;
	endcase end
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
		8: WriteData = csrr;
		default: WriteData = 0;
	endcase end
	always @ (*) begin case (MemSrc)
		// STORE
		0: memwrite_data = storebyte; // byte
		1: memwrite_data = storehalf; // half
		2: memwrite_data = ReadData2; // word
		3: memwrite_data = mwr; // wait
		default: memwrite_data = 0;
	endcase end
	always @ (*) begin case (PCOutSrc)
		0: pc_out = oldpc; // interrupt -- redo current op
		1: pc_out = pc; // exception -- go on to next op
		default: pc_out = 0;
	endcase end
	always @ (*) begin case (CsrASrc)
		//0: csr_a = instruction[31:20]; // normal
		//1: csr_a = ; // mepc
		default: csr_a = instruction[31:20];
	endcase end
	always @ (*) begin case (CsrDSrc)
		//0: csr_d = ALUOut; // normal
		//1:
		default: csr_d = ALUOut;
	endcase end
	always @ (*) begin case (IRLate)
		1: instr_new = mdr;
		0: instr_new = memread_data;
	endcase end
	// CPU main TODO: move out of if-else
	always @ (posedge clk) begin
		if (rst) begin
			pc <= START_ADDR;
		end
		else begin
			A <= ReadData1;
			B <= ReadData2;
			
			ALUOut <= ALUResult; ALUOut2 <= ALUOut;
			`ifdef RV32M
			RV32MOut <= RV32MResult;
			`endif

			mdr <= memread_data;
			mwr <= memwrite_data;
			mar <= mem_addr;

			if (csrsave) csrr <= csr_spo;

			if (PCWrite) begin
				pc <= newpc; oldpc <= pc;
			end

			if (IRWrite) instruction <= instr_new;
		end
	end
endmodule
