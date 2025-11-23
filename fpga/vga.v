`default_nettype none
module vga
(
    input wire clk,

    output wire de,
    output wire hsync,
    output wire vsync,

    output wire row_first,
    output wire row_start,
    output wire [4:0] row_index,
    output wire [4:0] row_pixel,

    output wire col_first,
    output wire col_start,
    output wire [6:0] col_index,
    output wire [3:0] col_pixel
);

wire v_ce;
wire h_active;
wire v_active;
wire col_is_first;
wire col_is_start;

vga_axis #(
    .GLYPHS(80),
    .PIXELS(10),
    .FRONT_PORCH(36), // 27MHz
    // .FRONT_PORCH(210), // 33Mhz
    .BACK_PORCH(46)
) h_axis
(
    .clk(clk),
    .ce(1'b1),

    .carry(v_ce),
    .active(h_active),
    .sync(hsync),

    .glyph_is_zero(col_is_first),
    .pixel_is_zero(col_is_start),
    .glyph_index(col_index),
    .pixel_index(col_pixel)
);

vga_axis #(
    .GLYPHS(24),
    .PIXELS(20),
    .FRONT_PORCH(7), // 27MHz
    // .FRONT_PORCH(22), // 33Mhz
    .BACK_PORCH(23)
) v_axis
(
    .clk(clk),
    .ce(v_ce),

    .active(v_active),
    .carry(),
    .sync(vsync),

    .glyph_is_zero(row_first),
    .pixel_is_zero(row_start),
    .glyph_index(row_index),
    .pixel_index(row_pixel)
);

assign de = h_active & v_active;
assign col_first = col_is_first & v_active;
assign col_start = col_is_start & v_active;

endmodule
