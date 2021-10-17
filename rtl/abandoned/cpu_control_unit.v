`timescale 1ns / 1ps
// pComputer multi-cycle CPU -- control unit

module control_unit
    (
        input clk,
        input rst,
        input [31:0]instruction,
        input ALUZero,
        input ALUCf,
        input ALUOf,
        input ALUSf,
        input MemReady,
        input [31:0]status,
        input irq,
        output reg iack,

        output reg PCWrite,
        output reg NewInstr,
        output reg [1:0]IorDorW,
        output reg MemRead,
        output reg MemWrite,
        output reg [2:0]RegSrc,
        output reg IRWrite,
        output reg [2:0]PCSource,
        output reg [2:0]ALUm,
        output reg [1:0]ALUSrcA,
        output reg [1:0]ALUSrcB,
        output reg RegWrite,
        output reg [1:0]RegDst,
        output reg ImmNSE,
        output reg Cmp,
        output reg IRSrc,
        output reg HiLoSrc,
        output reg HiLoWrite,

        output reg EPCWrite,
        output reg EPCSrc,
        output reg CauseWrite,
        output reg CauseSrc,
        output reg StatusWrite,
        output reg StatusSrc,
        output reg [4:0]Mfc0Src,
        output reg Mtc0Write,
        output reg [4:0]Mtc0Src
    );

    // control unit FSM state names (values doesn't matter)
    localparam IF = 0;
    localparam ID_RF = 1;
    localparam MFHI_END = 60;
    localparam MFLO_END = 61;
    localparam MULT_EX = 62;
    localparam MULT_WAIT = 63;
    localparam MULT_END = 64;
    localparam DIV_EX = 65;
    localparam DIV_WAIT = 66;
    localparam DIV_END = 67;
    localparam R_EX = 2;
    localparam R_END = 3;
    localparam SHIFT_EX = 4;
    localparam CMP_END = 5;
    localparam LUI_END = 6;
    localparam MEM_ADDR_CALC = 10;
    localparam MEM_ACCESS_LW = 11;
    localparam WB = 12; 
    localparam MEM_ACCESS_SW = 13;
    localparam CALCI_EX = 20;
    localparam CALCI_END = 21;
    localparam CMPI_END = 22;
    localparam B_EX = 30;
    localparam BEQ_END = 31;
    localparam BNE_END = 32;
    localparam J_END = 40;
    localparam JAL_END = 41;
    localparam JR_END = 42;
    localparam JALR_END = 43;
    localparam I_MFC0_END = 50;
    localparam I_MTC0_END = 51;
    localparam I_ERET_END = 52;
    localparam I_SYSCALL_END = 53;
    localparam I_INT_END = 54;
    localparam I_EXCPTN_END = 55;
    localparam IF_REMEDY = 96;
    localparam MEM_WAIT = 98;
    localparam BAD = 99;
    (*mark_debug = "true"*) reg [7:0]phase = IF;
    reg [7:0]phase_return = IF;
    //reg [7:0]phase = IF;
    reg [7:0]counter;

    // instruction[31:26] instruction type
    wire [5:0]instr_type = instruction[31:26];
    localparam TYPE_REG = 6'b000000;
    localparam TYPE_J = 6'b000010;
    localparam TYPE_JAL = 6'b000011;
    localparam TYPE_BEQ = 6'b000100;
    localparam TYPE_BNE = 6'b000101;
    localparam TYPE_BLEZ = 6'b000110; // todo
    localparam TYPE_BGTZ = 6'b000111; // todo
    localparam TYPE_ADDI = 6'b001000;
    localparam TYPE_ADDIU = 6'b001001;
    localparam TYPE_SLTI = 6'b001010; // todo
    localparam TYPE_SLTIU = 6'b001011; // todo
    localparam TYPE_ANDI = 6'b001100;
    localparam TYPE_ORI = 6'b001101;
    localparam TYPE_XORI = 6'b001110;
    localparam TYPE_LUI = 6'b001111;
    localparam TYPE_INT = 6'b010000;
    localparam TYPE_LW = 6'b100011;
    localparam TYPE_SW = 6'b101011;
    localparam TYPE_BAD = 0;

    // instruction[5:0] function
    wire [5:0]instr_funct = instruction[5:0];
    localparam FUNCT_SLL = 6'b000000;
    localparam FUNCT_SRL = 6'b000010;
    localparam FUNCT_SLLV = 6'b000100;
    localparam FUNCT_SRLV = 6'b000110;
    localparam FUNCT_JR = 6'b001000;
    localparam FUNCT_JALR = 6'b001001;
    localparam FUNCT_SYSCALL = 6'b001100;
    localparam FUNCT_MFHI = 6'b010000;
    localparam FUNCT_MTHI = 6'b010001; // not on todo list
    localparam FUNCT_MFLO = 6'b010010;
    localparam FUNCT_MTLO = 6'b010011; // not on todo list
    localparam FUNCT_MULT = 6'b011000;
    localparam FUNCT_MULTU = 6'b011001;
    localparam FUNCT_DIV = 6'b011010;
    localparam FUNCT_DIVU = 6'b011011;
    localparam FUNCT_ADD = 6'b100000;
    localparam FUNCT_ADDU = 6'b100001;
    localparam FUNCT_SUB = 6'b100010;
    localparam FUNCT_SUBU = 6'b100011;
    localparam FUNCT_AND = 6'b100100;
    localparam FUNCT_OR = 6'b100101;
    localparam FUNCT_XOR = 6'b100110;
    localparam FUNCT_NOR = 6'b100111; // not on todo list
    localparam FUNCT_SLT = 6'b101010;
    localparam FUNCT_SLTU = 6'b101011;

    // instruction label (values doesn't matter)
    reg [31:0]Op;
    localparam OP_MFHI = 91101;
    localparam OP_MFLO = 91102;
    localparam OP_MULT = 91103;
    localparam OP_DIV = 91104;
    localparam OP_ADD = 91001;
    localparam OP_SUB = 91002;
    localparam OP_AND = 91003;
    localparam OP_OR = 91004;
    localparam OP_XOR = 91005;
    localparam OP_SLT = 91006;
    localparam OP_SLTU = 91007;
    localparam OP_SLL = 91009;
    localparam OP_SRL = 91010;
    localparam OP_SLLV = 91011;
    localparam OP_SRLV = 91012;
    //
    localparam OP_ADDI = 92001;
    localparam OP_ANDI = 92002;
    localparam OP_ORI = 92003;
    localparam OP_XORI = 92004;
    localparam OP_LUI = 92005;
    localparam OP_SLTI = 92006;
    localparam OP_SLTIU = 92007;
    //
    localparam OP_LW = 90009;
    localparam OP_SW = 90010;
    localparam OP_BEQ = 90011;
    localparam OP_BNE = 90012;
    localparam OP_J = 90013;
    localparam OP_JAL = 90014;
    localparam OP_JR = 90015;
    localparam OP_JALR = 90016;
    localparam OP_MFC0 = 90017;
    localparam OP_MTC0 = 90018;
    localparam OP_ERET = 90019;
    localparam OP_SYSCALL = 90020;
    localparam OP_NOP = 98000;
    localparam OP_BAD = 99000;

    always @ (*) begin
        case (instr_type)
            TYPE_REG: case (instr_funct)
                FUNCT_SLL: Op = OP_SLL;
                FUNCT_SRL: Op = OP_SRL;
                FUNCT_SLLV: Op = OP_SLLV;
                FUNCT_SRLV: Op = OP_SRLV;
                FUNCT_JR: Op = OP_JR;
                FUNCT_JALR: Op = OP_JALR;
                FUNCT_SYSCALL: Op = OP_SYSCALL;
                FUNCT_MFHI: Op = OP_MFHI;
                FUNCT_MFLO: Op = OP_MFLO;
                FUNCT_MULT: Op = OP_MULT;
                FUNCT_MULTU: Op = OP_MULT;
                FUNCT_DIV: Op = OP_DIV;
                FUNCT_DIVU: Op = OP_DIV;
                FUNCT_ADD: Op = OP_ADD;
                FUNCT_ADDU: Op = OP_ADD;
                FUNCT_SUB: Op = OP_SUB;
                FUNCT_SUBU: Op = OP_SUB;
                FUNCT_AND: Op = OP_AND;
                FUNCT_OR: Op = OP_OR;
                FUNCT_XOR: Op = OP_XOR;
                FUNCT_SLT: Op = OP_SLT;
                FUNCT_SLTU: Op = OP_SLTU;
                // minor bug here: NOP judged as SHIFT
                default: if (instruction == 32'b0) Op = OP_NOP;
                else Op = OP_BAD;
            endcase
            TYPE_J: Op = OP_J;
            TYPE_JAL: Op = OP_JAL;
            TYPE_BEQ: Op = OP_BEQ;
            TYPE_BNE: Op = OP_BNE;
            TYPE_ADDI: Op = OP_ADDI;
            TYPE_ADDIU: Op = OP_ADDI;
            TYPE_SLTI: Op = OP_SLTI;
            TYPE_SLTIU: Op = OP_SLTIU;
            TYPE_ANDI: Op = OP_ANDI;
            TYPE_ORI: Op = OP_ORI;
            TYPE_XORI: Op = OP_XORI;
            TYPE_LUI: Op = OP_LUI;
            TYPE_LW: Op = OP_LW;
            TYPE_SW: Op = OP_SW;
            TYPE_INT: case (instruction[25:21])
                5'b10000: Op = OP_ERET;
                5'b00000: Op = OP_MFC0;
                5'b00100: Op = OP_MTC0;
                default: Op = OP_BAD;
            endcase
            default: Op = OP_BAD;
        endcase
    end

    // control fsm
    always @ (posedge clk) begin
        if (rst) begin
            phase <= IF;
        end
        else begin
            case(phase)
                IF: if (!MemReady) begin
                    phase <= MEM_WAIT;
                    phase_return <= IF_REMEDY;
                end
                else phase <= ID_RF;
                IF_REMEDY: phase <= ID_RF;
                ID_RF: begin
                    if (status[3] & irq) phase <= I_INT_END;
                    else case(Op)
                        OP_NOP: phase <= IF;

                        OP_MFHI: phase <= MFHI_END;
                        OP_MFLO: phase <= MFLO_END;
                        OP_MULT: phase <= MULT_EX;
                        OP_DIV: phase <= DIV_EX;
                        OP_ADD: phase <= R_EX;
                        OP_SUB: phase <= R_EX;
                        OP_AND: phase <= R_EX;
                        OP_OR: phase <= R_EX;
                        OP_XOR: phase <= R_EX;
                        OP_SLT: phase <= R_EX;
                        OP_SLTU: phase <= R_EX;
                        OP_SLL: phase <= SHIFT_EX;
                        OP_SRL: phase <= SHIFT_EX;
                        OP_SLLV: phase <= R_EX;
                        OP_SRLV: phase <= R_EX;

                        OP_LW: phase <= MEM_ADDR_CALC;
                        OP_SW: phase <= MEM_ADDR_CALC;
                        OP_ADDI: phase <= CALCI_EX;
                        OP_ANDI: phase <= CALCI_EX;
                        OP_ORI: phase <= CALCI_EX;
                        OP_XORI: phase <= CALCI_EX;
                        OP_SLTI: phase <= CALCI_EX;
                        OP_SLTIU: phase <= CALCI_EX;
                        OP_LUI: phase <= LUI_END;

                        OP_BEQ: phase <= B_EX;
                        OP_BNE: phase <= B_EX;

                        OP_J: phase <= J_END;
                        OP_JAL: phase <= JAL_END;
                        OP_JR: phase <= JR_END;
                        OP_JALR: phase <= JALR_END;

                        OP_MFC0: phase <= I_MFC0_END;
                        OP_MTC0: phase <= I_MTC0_END;
                        OP_ERET: phase <= I_ERET_END;
                        OP_SYSCALL: begin
                            if (status[0]) phase <= I_SYSCALL_END;
                            else phase <= IF;
                        end
                        default: phase <= BAD;
                    endcase
                end
                MEM_ADDR_CALC: case (Op)
                    OP_LW: phase <= MEM_ACCESS_LW;
                    OP_SW: phase <= MEM_ACCESS_SW;
                    default: phase <= BAD;
                endcase
                MEM_ACCESS_LW: begin
                    phase <= MEM_WAIT; phase_return <= WB;
                end
                WB: begin 
                    phase <= IF;
                end
                MEM_ACCESS_SW: begin
                    phase <= MEM_WAIT; phase_return <= IF;
                end
                LUI_END: phase <= IF;
                MFHI_END: phase <= IF;
                MFLO_END: phase <= IF;
                MULT_EX: begin
                    phase <= MULT_WAIT;
                    counter <= 3 - 2;
                end
                MULT_WAIT: begin
                    counter <= counter - 1;
                    if (counter == 0) phase <= MULT_END;
                end
                MULT_END: phase <= IF;
                DIV_EX: begin
                    phase <= DIV_WAIT;
                    counter <= 36 - 2;
                end
                DIV_WAIT: begin
                    counter <= counter - 1;
                    if (counter == 0) phase <= DIV_END;
                end
                DIV_END: phase <= IF;
                R_EX: case (Op)
                    OP_SLT: phase <= CMP_END;
                    OP_SLTU: phase <= CMP_END;
                    default: phase <= R_END;
                endcase
                R_END: phase <= IF;
                SHIFT_EX: phase <= R_END;
                CMP_END: phase <= IF;
                JR_END: phase <= IF;
                JALR_END: phase <= IF;
                J_END: phase <= IF;
                JAL_END: phase <= IF;
                B_EX: case (Op)
                    OP_BEQ: phase <= BEQ_END;
                    OP_BNE: phase <= BNE_END;
                    default: ;
                endcase
                BEQ_END: phase <= IF;
                BNE_END: phase <= IF;
                CALCI_EX: case (Op)
                    OP_SLTI: phase <= CMPI_END;
                    OP_SLTIU: phase <= CMPI_END;
                    default: phase <= CALCI_END;
                endcase
                CALCI_END: phase <= IF;
                CMPI_END: phase <= IF;
                I_MFC0_END: phase <= IF;
                I_MTC0_END: phase <= IF;
                I_ERET_END: phase <= IF;
                I_SYSCALL_END: phase <= IF;
                I_INT_END: phase <= IF;
                MEM_WAIT: begin // this costs thousands of cycles but who cares?
                    if (MemReady) phase <= phase_return;
                    else phase <= MEM_WAIT;
                end
                default: phase <= BAD;
            endcase
        end
    end

    // control signals for each FSM states
    always @ (*) begin
        PCWrite = 0;
        NewInstr = 0;
        IorDorW = 2'b00;
        MemRead = 0;
        MemWrite = 0;
        RegSrc = 3'b000;
        IRWrite = 0;
        PCSource = 3'b000;
        ALUm = 3'b000;
        ALUSrcA = 2'b0;
        ALUSrcB = 0;
        RegWrite = 0;
        RegDst = 2'b00;
        ImmNSE = 0;
        Cmp = 0;
        IRSrc = 0;
        HiLoSrc = 0;
        HiLoWrite = 0;
        EPCWrite = 0;
        EPCSrc = 0;
        CauseWrite = 0;
        CauseSrc = 0;
        StatusWrite = 0;
        StatusSrc = 0;
        Mfc0Src = 5'b0;
        Mtc0Write = 0;
        Mtc0Src = 5'b0;
        iack = 0;
        case (phase)
            IF: begin
                MemRead = 1;
                IRWrite = 1;
                PCWrite = 1;
                NewInstr = 1;
                ALUSrcB = 2'b01;
            end
            IF_REMEDY: begin
                IRWrite = 1;
                IRSrc = 1;
                ALUSrcB = 2'b01;
                //PCWrite = 1;
                //NewInstr = 1;
                //ALUSrcB = 2'b01;
            end
            ID_RF: begin
                ALUSrcB = 2'b11;
            end
            MEM_ADDR_CALC: begin
                ALUSrcA = 2'b01; ALUSrcB = 2'b10;
            end
            MEM_ACCESS_LW: begin
                MemRead = 1; IorDorW = 2'b01;
            end
            WB: begin
                RegWrite = 1; RegSrc = 3'b001;
            end
            MEM_ACCESS_SW: begin
                MemWrite = 1; IorDorW = 2'b01;
            end
            CALCI_EX: begin
                ALUSrcA = 2'b01; ALUSrcB = 2'b10;
                case (Op)
                    OP_ADDI: ALUm = 3'b000;
                    OP_ANDI: begin ALUm = 3'b010; ImmNSE = 1; end
                    OP_ORI: begin ALUm = 3'b011; ImmNSE = 1; end
                    OP_XORI: begin ALUm = 3'b100; ImmNSE = 1; end
                    OP_SLTI: ALUm = 3'b001; // TODO
                    OP_SLTIU: ALUm = 3'b001; // TODO
                endcase
            end
            CALCI_END: begin
                RegWrite = 1;
            end
            CMPI_END: begin
                RegWrite = 1; RegSrc = 3'b101;
                case (Op)
                    OP_SLTI: Cmp = (ALUOf ^ ALUSf) & !ALUZero;
                    OP_SLTIU: Cmp = ALUCf;
                    default: ;
                endcase
            end
            LUI_END: begin
                RegWrite = 1; RegSrc = 3'b010;
            end
            MFHI_END: begin
                RegWrite = 1; RegSrc = 3'b110;
            end
            MFLO_END: begin
                RegWrite = 1; RegSrc = 3'b111;
            end
            MULT_EX: begin
                ALUSrcA = 2'b01;
            end
            MULT_WAIT: ;
            MULT_END: begin
                HiLoWrite = 1;
            end
            DIV_EX: begin
                ALUSrcA = 2'b01;
            end
            DIV_WAIT: ;
            DIV_END: begin
                HiLoWrite = 1; HiLoSrc = 1;
            end
            R_EX: begin
                ALUSrcA = 2'b01;
                case (Op)
                    OP_ADD: ALUm = 3'b000;
                    OP_SUB: ALUm = 3'b001;
                    OP_AND: ALUm = 3'b010;
                    OP_OR: ALUm = 3'b011;
                    OP_XOR: ALUm = 3'b100;
                    OP_SLT: ALUm = 3'b001;
                    OP_SLTU: ALUm = 3'b001;
                    OP_SLLV: ALUm = 3'b101;
                    OP_SRLV: ALUm = 3'b110;
                endcase
            end
            SHIFT_EX: begin
                ALUSrcA = 2'b10;
                case (Op)
                    OP_SLL: ALUm = 3'b101;
                    OP_SRL: ALUm = 3'b110;
                endcase
            end
            R_END: begin
                RegWrite = 1; RegDst = 2'b01;
            end
            CMP_END: begin
                RegWrite = 1; RegDst = 2'b01; RegSrc = 3'b101;
                case (Op) 
                    OP_SLT: Cmp = (ALUOf ^ ALUSf) & !ALUZero;
                    OP_SLTU: Cmp = ALUCf;
                    default: ;
                endcase
            end
            B_EX: begin
                ALUSrcA = 2'b01; ALUm = 3'b001;
            end
            BEQ_END: begin
                PCWrite = ALUZero; PCSource = 3'b001;
            end
            BNE_END: begin
                PCWrite = !ALUZero; PCSource = 3'b001;
            end
            J_END: begin
                PCWrite = 1; PCSource = 3'b010;
            end
            JAL_END: begin
                PCWrite = 1; PCSource = 3'b010;
                RegWrite = 1; RegDst = 2'b10; RegSrc = 3'b011;
            end
            JR_END: begin
                PCWrite = 1; PCSource = 3'b011;
            end
            JALR_END: begin
                PCWrite = 1; PCSource = 3'b011;
                RegWrite = 1; RegDst = 2'b01; RegSrc = 3'b011;
            end
            I_MFC0_END: begin
                RegWrite = 1; RegSrc = 3'b100;
                Mfc0Src = instruction[15:11];
            end
            I_MTC0_END: begin
                Mtc0Write = 1;
                Mtc0Src = instruction[15:11];
            end
            I_ERET_END: begin
                PCWrite = 1; PCSource = 3'b100;
                StatusWrite = 1; StatusSrc = 1;
            end
            I_SYSCALL_END: begin
                PCWrite = 1; PCSource = 3'b101;
                CauseWrite = 1; CauseSrc = 1;
                StatusWrite = 1; StatusSrc = 0;
                EPCWrite = 1; EPCSrc = 0;
            end
            I_INT_END: begin
                PCWrite = 1; PCSource = 3'b101;
                CauseWrite = 1; CauseSrc = 0;
                StatusWrite = 1; StatusSrc = 0;
                EPCWrite = 1; EPCSrc = 1;
                iack = 1;
            end
            I_EXCPTN_END: begin
                PCWrite = 1; PCSource = 3'b100;
                CauseWrite = 1; CauseSrc = 2;
                StatusWrite = 1; StatusSrc = 0;
                EPCWrite = 1; EPCSrc = 1;
                //iack = 1; 
            end
            MEM_WAIT: begin
                IorDorW = 2'b10;
            end
        endcase
    end
endmodule
