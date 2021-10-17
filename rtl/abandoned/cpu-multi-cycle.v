`timescale 1ns / 1ps
// pComputer multi-cycle CPU

module cpu_multi_cycle
    (
        input clk,
        input rst,
        input irq,
        input [3:0]icause,
        output iack,
        output ring,

        output reg [31:0]a,
        output reg [31:0]d,
        output reg we,
        output reg rd,
        input [31:0]spo,
        input ready
    );

    localparam START_ADDR = 32'hf0000000;

    // internal registers
    //(*mark_debug = "true"*) reg [31:0]instruction = 0;
    (*mark_debug = "true"*) reg [31:0]instruction = 0;
    (*mark_debug = "true"*) reg [31:0]pc = START_ADDR;
    reg [31:0]current_pc = START_ADDR;
    reg [31:0]waitaddr = 32'hffffffff;
    reg [31:0]mdr = 0;
    reg [31:0]ALUOut = 0;
    reg [31:0]BAddr = 0;
    reg ALUZero = 0;
    reg ALUCf = 0;
    reg ALUOf = 0;
    reg ALUSf = 0;
    reg [31:0]A = 0;
    reg [31:0]B = 0;
    reg [31:0]Hi = 0;
    reg [31:0]Lo = 0;

    // some signals
    reg [31:0]newpc;
    reg [63:0]newHiLo;
    wire [31:0]status;
    reg [31:0]imm;

    // control unit signals
    wire PCWrite;
    wire NewInstr;
    wire [1:0]IorDorW;
    wire MemRead;
    wire MemWrite;
    reg MemReady;
    wire [2:0]RegSrc;
    wire IRWrite;
    wire [2:0]PCSource;
    wire [2:0]ALUm;
    wire [1:0]ALUSrcA;
    wire [1:0]ALUSrcB;
    wire RegWrite;
    wire [1:0]RegDst;
    wire ImmNSE;
    wire Cmp;
    wire IRSrc;
    wire HiLoSrc;
    wire HiLoWrite;
    wire EPCWrite;
    wire EPCSrc;
    wire CauseWrite;
    wire CauseSrc;
    wire StatusWrite;
    wire StatusSrc;
    wire [4:0]Mfc0Src;
    wire Mtc0Write;
    wire [4:0]Mtc0Src;
    control_unit control_unit_inst
    (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .ALUZero(ALUZero),
        .ALUCf(ALUCf),
        .ALUOf(ALUOf),
        .ALUSf(ALUSf),
        .status(status),
        .irq(irq),
        .iack(iack),

        .PCWrite(PCWrite),
        .NewInstr(NewInstr),
        .IorDorW(IorDorW),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemReady(MemReady),
        .RegSrc(RegSrc),
        .IRWrite(IRWrite),
        .PCSource(PCSource),
        .ALUm(ALUm),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .RegWrite(RegWrite),
        .RegDst(RegDst),
        .ImmNSE(ImmNSE),
        .Cmp(Cmp),
        .IRSrc(IRSrc),
        .HiLoSrc(HiLoSrc),
        .HiLoWrite(HiLoWrite),

        .EPCSrc(EPCSrc),
        .EPCWrite(EPCWrite),
        .CauseWrite(CauseWrite),
        .CauseSrc(CauseSrc),
        .StatusWrite(StatusWrite),
        .StatusSrc(StatusSrc),
        .Mfc0Src(Mfc0Src),
        .Mtc0Write(Mtc0Write),
        .Mtc0Src(Mtc0Src)
    );

    // register file
    reg [4:0]WriteRegister;
    reg [31:0]WriteData;
    wire [31:0]ReadData1;
    wire [31:0]ReadData2;
    register_file register_file_inst
    (
        .clk(clk),
        .ra0(instruction[25:21]),
        .ra1(instruction[20:16]),
        .wa(WriteRegister),
        .we(RegWrite),
        .wd(WriteData),
        .rd0(ReadData1),
        .rd1(ReadData2)
    );

    // memory mapper
    reg [31:0]mem_addr;
    reg [31:0]MemData;
    always @ (*) begin
        a = mem_addr;
        d = B;
        we = MemWrite;
        rd = MemRead;
        MemData = spo;
        MemReady = ready;
    end

    // ALU
    reg [31:0]ALUIn1;
    reg [31:0]ALUIn2;
    wire [31:0]ALUResult;
    wire ALUZero_wire;
    wire ALUCf_wire;
    wire ALUOf_wire;
    wire ALUSf_wire;
    alu alu_inst
    (
        .m(ALUm),
        .a(ALUIn1),
        .b(ALUIn2),
        .y(ALUResult),
        .zf(ALUZero_wire),
        .cf(ALUCf_wire),
        .of(ALUOf_wire),
        .sf(ALUSf_wire)
    );

    wire [63:0]MultResult;
    mult_gen_0 mult_gen_0_inst
    (
        .clk(clk),
        .A(ALUIn1),
        .B(ALUIn2),
        .P(MultResult)
    );

    wire [63:0]DivResult;
    wire DivReady;
    div_gen_0 div_gen_0_inst
    (
        .aclk(clk),
        .s_axis_divisor_tdata(ALUIn2),
        .s_axis_divisor_tvalid(1),
        .s_axis_dividend_tdata(ALUIn1),
        .s_axis_dividend_tvalid(1),
        .m_axis_dout_tdata(DivResult),
        .m_axis_dout_tvalid(DivReady)
    );

    // coprocessor0
    wire [31:0]mfc0out;
    wire [31:0]epc;
    coprocessor0 coprocessor0_inst
    (
        .clk(clk),
        .rst(rst),
        .Mfc0Src(Mfc0Src),
        .EPCSrc(EPCSrc),
        .CauseSrc(CauseSrc),
        .StatusSrc(StatusSrc),
        .EPCWrite(EPCWrite),
        .CauseWrite(CauseWrite),
        .StatusWrite(StatusWrite),

        .pc(pc),
        .current_pc(current_pc),
        .causedata_outside(icause),
        .mtc0in(B),
        .mfc0out(mfc0out),
        .epc_out(epc),
        .status_out(status),
        .ring_out(ring)
    );



    // datapath -- main
    always @ (*) begin
        case (ImmNSE)
            0: imm = {{16{instruction[15]}}, instruction[15:0]};
            1: imm = {16'h0, instruction[15:0]};
        endcase
        case (IorDorW)
            0: mem_addr = pc;                           // IF
            1: mem_addr = ALUOut;                       // MEM
            2: mem_addr = waitaddr;                 // MEM_WAIT
            default: mem_addr = 32'hffffffff;
        endcase
        case (RegDst)
            0: WriteRegister = instruction[20:16];      // I-type
            1: WriteRegister = instruction[15:11];      // R-type, jalr
            2: WriteRegister = 5'b11111;                // jal
            default: WriteRegister = 0;
        endcase
        case (RegSrc)
            0: WriteData = ALUOut;                      // 
            1: WriteData = mdr;                         // lw
            2: WriteData = {instruction[15:0], 16'b0};  // lui
            3: WriteData = pc;                          // jal
            4: WriteData = mfc0out;                     // mfc0
            5: WriteData = {31'b0, Cmp};                // slt,...
            6: WriteData = Hi;                          // mfhi
            7: WriteData = Lo;                          // mflo
        endcase
        case (ALUSrcA)
            0: ALUIn1 = pc;                             // IF, ID
            1: ALUIn1 = A;                              // 
            2: ALUIn1 = {27'b0, instruction[10:6]};              // sll,srl
            default: ALUIn1 = 0;
        endcase
        case (ALUSrcB)
            0: ALUIn2 = B;                              //
            1: ALUIn2 = 4;                              // IF, IF_REMEDY
            2: ALUIn2 = imm;                            // addi,...
            3: ALUIn2 = imm << 2;                       // ID
        endcase
        case (PCSource)
            0: newpc = ALUResult;                               // IF
            1: newpc = BAddr;                                   // beq, bne
            2: newpc = {pc[31:28], instruction[25:0], 2'b0};    // j, jal
            3: newpc = A;                                       // jr, jalr
            4: newpc = epc;                                     // eret
            5: newpc = 32'h80000000;                            // syscall/int
            default: newpc = 0;
        endcase
        case (HiLoSrc)
            1'b0: newHiLo = MultResult;                        // mult
            1'b1: newHiLo = DivResult;                         // div
        endcase
    end
    always @ (posedge clk) begin
        if (rst) begin
            pc <= START_ADDR;
            //instruction <= 0;
            //mdr <= 0;
            //ALUOut <= 0;
            //ALUCf <= 0;
            //ALUOf <= 0;
            //BAddr <= 0;
            //A <= 0;
            //B <= 0;
        end
        else begin
            A <= ReadData1;
            B <= ReadData2;
            ALUOut <= ALUResult;
            BAddr <= ALUOut;
            ALUCf <= ALUCf_wire;
            ALUOf <= ALUOf_wire;
            ALUSf <= ALUSf_wire;
            ALUZero <= ALUZero_wire;
            mdr <= MemData;
            if (PCWrite) pc <= newpc;
            if (NewInstr) current_pc <= pc;
            if (IRWrite) begin
                if (IRSrc) instruction <= mdr;
                else instruction <= MemData;
            end
            if (HiLoWrite) {Hi, Lo} <= newHiLo;
            if (MemRead | MemWrite) waitaddr <= mem_addr;
        end
    end
endmodule
