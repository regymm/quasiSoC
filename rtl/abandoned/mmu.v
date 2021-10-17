`timescale 1ns / 1ps
// pComputer primitive MMU
// single level page table
// 1MB page: 23 bit offset, total 256 pages(per instance)
// VA:
// [31:28] memory section selection
// [27:20] VPN
// [19:0] offset
// PTE:
// [31:24] PPN
// [23:3] Unused
// [1] Privileged mode (ring)
// [0] Present
// r/w  0xe0000000: paging enable
// r/w  0xe0000004: page table base register
// r/w  0xe0000008: lower bound in which paging enabled
// r/w  0xe000000c: upper bound in which paging enabled
//
// Use fast ram(like TLB) at 0x10000000 is recommended for PTBR
// can have 64*64 PTE aka 64 processes

module mmu
    (
        input clk, 
        input rst, 

        input ring,

        input [31:0]va,
        input [31:0]vd,
        input vwe, 
        input vrd, 
        output reg [31:0]vspo, 
        output reg vready,

        output reg [31:0]pa,
        output reg [31:0]pd,
        output reg pwe, 
        output reg prd, 
        input [31:0]pspo, 
        input pready,
        input pirq,

        output reg virq = 0
    );

    reg [31:0]ptbr = 0; // page table base register
    reg [31:0]addr_lower = 0; // lower address limit of paging
    reg [31:0]addr_upper = 0; // upper address limit of paging
    reg enabled = 0;

    wire ispaging = enabled & (va[31:28] == 4'b0) & (va > addr_lower) & (va < addr_upper);

    //reg [31:0]pa_bak = 32'hffffffff;

    localparam IDLE = 4'h0;
    localparam READ_PT = 4'h2;
    localparam CHECK = 4'h3;
    localparam PREAD = 4'hb;
    localparam PWRITE = 4'hc;
    localparam RW_END = 4'hd;
    localparam ERR = 4'he;
    localparam MEM_WAIT = 4'hf;
    reg [3:0]phase = IDLE;
    reg [3:0]phase_todo;
    reg [3:0]phase_return;

    reg [31:0]target_va;
    reg [31:0]target_vd;
    reg [31:0]pa_bak; // to store memory address when waiting
    reg [31:0]pspo_recv;

    wire [31:0]pte_pa = ptbr + {22'b0, target_va[27:20], 2'b0};
    wire [31:0]target_pa = {4'b0, pspo_recv[31:24], target_va[19:0]};
    wire legal = pspo_recv[0] & (ring <= pspo_recv[1]);

    always @ (posedge clk) begin
        if (rst) begin
            ptbr <= 0;
            addr_lower <= 0;
            addr_upper <= 0;
            enabled <= 0;
            phase <= IDLE;
        end
        else begin
            if (va == 32'he0000000 & vwe)
                enabled <= vd[0];

            //if (pirq) begin
                //phase <= ERR;
            //end
            //else
            case (phase)
                IDLE: begin
                    if (ispaging & (vrd | vwe)) begin
                        phase <= READ_PT;
                        target_va <= va;
                        target_vd <= vd;
                        if (vrd) phase_todo <= PWRITE;
                        else phase_todo <= PREAD;
                    end
                end
                READ_PT: begin
                    phase <= MEM_WAIT;
                    phase_return <= CHECK;
                    pa_bak <= pa;
                end
                CHECK: begin
                    if (legal) phase <= phase_todo;
                    else phase <= ERR;
                end
                PREAD: begin
                    phase <= MEM_WAIT;
                    phase_return <= RW_END;
                    pa_bak <= pa;
                end
                PWRITE: begin
                    phase <= MEM_WAIT;
                    phase_return <= RW_END;
                    pa_bak <= pa;
                end
                RW_END: begin
                    phase <= IDLE;
                end
                ERR: begin
                    phase <= IDLE;
                end
                MEM_WAIT: begin
                    if (pready) begin
                        phase <= phase_return;
                        pspo_recv <= pspo;
                    end
                end
                default: ;
            endcase
            //if (pready) pa_bak <= va;
            //pa_bak <= pa;

        end
    end

    //always @ (*) begin
        //if (!pready) begin // lock value until ready
            ////pa = pa_bak;
            //pa = 0;
        //end
        //else pa = va;
    //end

    always @ (*) begin
        //pa = 0;
        //pd = 0;
        //pwe = 0;
        //prd = 0;
        //vspo = 0;
        //vready = 0;
        //virq = 0;
        //// paging OFF (default)
        //if (ispaging) begin // paging ON
            //case (phase)
                //IDLE: ;
                //READ_PT: begin
                    //pa = pte_pa;
                    //prd = 1;
                //end
                //CHECK: ;
                //PREAD: begin
                    //pa = target_pa;
                    //prd = 1;
                //end
                //PWRITE: begin
                    //pa = target_pa;
                    //pwe = 1;
                //end
                //RW_END: begin
                    //vspo = pspo_recv;
                    //vready = 1;
                //end
                //ERR: begin
                    //virq = 1;
                    //vready = 1;
                //end
                //MEM_WAIT: begin
                    //pa = pa_bak;
                //end
                //default: ;
            //endcase
        //end
        //else
        begin
            pa = va;
            pd = vd;
            pwe = vwe; 
            prd = vrd;
            vspo = pspo;
            vready = pready;
        end
    end

endmodule
