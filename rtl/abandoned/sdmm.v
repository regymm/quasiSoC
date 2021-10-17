`timescale 1ns / 1ps
// pComputer memory mapped SD card
// sdcard.v is connected to this
// 0x00000000 to 0x0ffffffc: mapped memory, 256MB max
// r/w 0x96003000: MM start sector
// r/w 0x96003004: MM size(in sector)
//
// Direct IO, raw access, full range, non-blocking
// w   0x96001000: directio block number
// w   0x96001004: directio offset
// w   0x96001008: directio do read
// w   0x9600100c: directio do write
// r   0x96001010: directio result ready
// r   0x96001014: directio result
//
// Pass to sdcard.v
// r   0x96002000: negative card detect
// r   0x96002004: write protected
// r   0x96002010: ready, but use 1010 is recommended

module sdmm
    (
        input clk,
        input rst,

        (*mark_debug = "true"*) input [31:0]a,
        (*mark_debug = "true"*) input [31:0]d,
        (*mark_debug = "true"*) input we,
        (*mark_debug = "true"*) input rd,
        (*mark_debug = "true"*) output reg [31:0]spo,
        (*mark_debug = "true"*) output wire ready,

        (*mark_debug = "true"*) output reg [15:0]sddrv_a,
        (*mark_debug = "true"*) output reg [31:0]sddrv_d,
        (*mark_debug = "true"*) output reg sddrv_we,
        (*mark_debug = "true"*) input [31:0]sddrv_spo,

        output reg irq = 0
    );

    (*mark_debug = "true"*) reg [7:0]load_count = 0;

    reg [31:0]mm_start_sector = 0;
    reg [31:0]mm_size = 0; // size in sector number

    reg [31:0]directio_sector = 0;
    reg [8:0]directio_offset = 0; // 0x0 to 0x1fc
    reg [31:0]directio_result = 0;
    wire [15:0]cache_rw_addr_directio = {7'h0, directio_offset};
    reg [31:0]target_data_directio = 0;

    localparam CONTROL_ADDR = 16'h9600;
    wire control_addr = (a[31:16] == CONTROL_ADDR);
    wire ncontrol_addr_legal = (a[31:28] == 4'b0) & ({9'b0, a[31:9]} <= mm_size); // this means not control_addr

    reg [31:0]target_addr = 0;
    reg [31:0]target_data = 0;
    wire [15:0]cache_rw_addr = {7'h0, target_addr[8:0]};

    localparam IDLE = 4'h0;
    localparam READ = 4'h1;
    localparam WRITE = 4'h2;
    localparam FLUSH_CHECK = 4'h3;
    localparam DIRTY_CHECK = 4'h4;
    localparam SYNC = 4'h5;
    localparam SET_NEW_SECTOR = 4'h6;
    localparam LOAD_NEW_SECTOR = 4'h7;
    localparam WAIT_READY = 4'hf;
    (*mark_debug = "true"*) reg [3:0]state = IDLE;
    reg [3:0]state_return = IDLE; // return to after SD becomes ready
    reg [3:0]state_todo = IDLE; // READ or WRITE
    reg cache_valid = 0;
    reg directio = 0;

    reg need_flush; // whether the target_addr falls into the current loaded SD sector
    reg is_dirty;
    reg sd_is_ready;

    always @ (posedge clk) begin
        if (rst) begin
            mm_start_sector <= 0;
            mm_size <= 0;
            state <= IDLE;
            cache_valid <= 0;
            load_count <= 0;
            irq <= 0;
        end
        else begin
            if (control_addr & we & ready)
                case (a[15:0])
                    16'h1000: directio_sector <= d;
                    16'h1004: directio_offset <= d[8:0];
                    16'h3000: mm_start_sector <= d;
                    16'h3004: mm_size <= d;
                    default: ;
                endcase

                if ((rd | we) & !ncontrol_addr_legal) begin
                    irq <= 1;
                end

            case (state)
                IDLE: begin
                    if (rd & ncontrol_addr_legal) begin
                        target_addr <= a;
                        target_data <= d;
                        state_todo <= READ;
                        state_return <= FLUSH_CHECK;
                        state <= WAIT_READY;
                        directio <= 0;
                    end
                    else if (we & ncontrol_addr_legal) begin
                        target_addr <= a;
                        target_data <= d;
                        state_todo <= WRITE;
                        state_return <= FLUSH_CHECK;
                        state <= WAIT_READY;
                        directio <= 0;
                    end
                    else if (we & control_addr & (a[15:0] == 16'h1008) & d[0]) begin
                        state_todo <= READ;
                        state_return <= FLUSH_CHECK;
                        state <= WAIT_READY;
                        directio <= 1;
                    end
                    else if (we & control_addr & (a[15:0] == 16'h100c) & d[0]) begin
                        target_data_directio <= d;
                        state_todo <= WRITE;
                        state_return <= FLUSH_CHECK;
                        state <= WAIT_READY;
                        directio <= 1;
                    end
                end
                FLUSH_CHECK: begin
                    if (!cache_valid) state <= SET_NEW_SECTOR;
                    else if (need_flush) state <= DIRTY_CHECK;
                    else state <= state_todo; // we have a "cache hit"
                end
                DIRTY_CHECK: begin
                    if (is_dirty) state <= SYNC;
                    else state <= SET_NEW_SECTOR;
                end
                SYNC: begin // write back dirty sector
                    state <= WAIT_READY;
                    state_return <= SET_NEW_SECTOR;
                end
                SET_NEW_SECTOR: begin
                    state <= LOAD_NEW_SECTOR;
                    cache_valid <= 1;
                end
                LOAD_NEW_SECTOR: begin
                    load_count <= load_count + 1;
                    state_return <= state_todo;
                    state <= WAIT_READY;
                end
                READ: begin
                    state <= IDLE;
                    if (directio) directio_result <= sddrv_spo;
                end
                WRITE: begin
                    state <= IDLE;
                end
                WAIT_READY: begin
                    if (sd_is_ready) state <= state_return;
                    else state <= WAIT_READY;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    always @ (*) begin
        spo = 0;
        sddrv_a = 0;
        sddrv_d = 0;
        sddrv_we = 0;
        need_flush = 0;
        is_dirty = 0;
        sd_is_ready = 0;
        case (state)
            IDLE: begin // so control addr when NOT idle will be ignored
                if (control_addr)
                    case (a[15:0])
                        16'h1010: spo = {31'b0, ready};
                        16'h1014: spo = directio_result;
                        16'h3000: spo = mm_start_sector;
                        16'h3004: spo = mm_size;
                        // so, old-20xx access still works, but strongly not
                        // recommended.
                        // Keep them to avoid re-write bootrom
                        // for a while
                        default: begin
                            sddrv_a = a[15:0];
                            sddrv_d = d;
                            //sddrv_we = we; // do not pass write signal
                            spo = sddrv_spo;
                        end
                    endcase
            end
            FLUSH_CHECK: begin
                sddrv_a = 16'h1000;
                if (directio) 
                    need_flush = (sddrv_spo != directio_sector);
                else
                    need_flush = (sddrv_spo != ((target_addr>>9) + mm_start_sector));
            end
            DIRTY_CHECK: begin
                sddrv_a = 16'h2014;
                is_dirty = sddrv_spo[0];
            end
            SYNC: begin
                sddrv_a = 16'h1008;
                sddrv_d = 32'h1;
                sddrv_we = 1;
            end
            SET_NEW_SECTOR: begin
                sddrv_a = 16'h1000;
                sddrv_we = 1;
                if (directio)
                    sddrv_d = directio_sector;
                else
                    sddrv_d = (target_addr>>9) + mm_start_sector;
            end
            LOAD_NEW_SECTOR: begin
                sddrv_a = 16'h1004;
                sddrv_d = 32'b1;
                sddrv_we = 1;
            end
            WAIT_READY: begin
                sddrv_a = 16'h2010;
                sd_is_ready = sddrv_spo[0];
            end
            READ: begin
                if (directio)
                    sddrv_a = cache_rw_addr_directio;
                else
                    sddrv_a = cache_rw_addr;
                spo = sddrv_spo;
            end
            WRITE: begin
                if (directio)
                    sddrv_a = cache_rw_addr_directio;
                else
                    sddrv_a = cache_rw_addr;
                if (directio)
                    sddrv_d = target_data_directio;
                else 
                    sddrv_d = target_data;
                sddrv_we = 1;
            end
            default: ;
        endcase
    end

    assign ready = (control_addr | // control addr always ready
        (state == IDLE & 
        !(ncontrol_addr_legal & (rd | we))) | // ready should be update right in the cycle r/w starts
        state == READ | state == WRITE); // early finish, or read result will be lost
endmodule
