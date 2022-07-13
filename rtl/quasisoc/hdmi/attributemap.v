module attributemap (
           input wire [7:0] attribute,
           output wire [23:0] fgrgb,
           output wire [23:0] bgrgb,
           output wire blink
);
// See https://en.wikipedia.org/wiki/Video_Graphics_Array#Color_palette
assign blink = attribute[7];
assign bgrgb = attribute[6:4] == 3'b000 ? 24'h000000
    : attribute[6:4] == 3'b001 ? 24'h0000AA
    : attribute[6:4] == 3'b010 ? 24'h00AA00
    : attribute[6:4] == 3'b011 ? 24'h00AAAA
    : attribute[6:4] == 3'b100 ? 24'hAA0000
    : attribute[6:4] == 3'b101 ? 24'hAA00AA
    : attribute[6:4] == 3'b110 ? 24'hAA5500
    : attribute[6:4] == 3'b111 ? 24'hAAAAAA
    : 24'h000000;

assign fgrgb = attribute[3:0] == 4'h0 ? 24'h000000
    : attribute[3:0] == 4'h1 ? 24'h0000AA
    : attribute[3:0] == 4'h2 ? 24'h00AA00
    : attribute[3:0] == 4'h3 ? 24'h00AAAA
    : attribute[3:0] == 4'h4 ? 24'hAA0000
    : attribute[3:0] == 4'h5 ? 24'hAA00AA
    : attribute[3:0] == 4'h6 ? 24'hAA5500
    : attribute[3:0] == 4'h7 ? 24'hAAAAAA
    : attribute[3:0] == 4'h8 ? 24'h555555
    : attribute[3:0] == 4'h9 ? 24'h5555FF
    : attribute[3:0] == 4'hA ? 24'h55FF55
    : attribute[3:0] == 4'hB ? 24'h55FFFF
    : attribute[3:0] == 4'hC ? 24'hFF5555
    : attribute[3:0] == 4'hD ? 24'hFF55FF
    : attribute[3:0] == 4'hE ? 24'hFFFF55
    : attribute[3:0] == 4'hF ? 24'hFFFFFF
    : 24'h000000;

endmodule
