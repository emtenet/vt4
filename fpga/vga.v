`default_nettype none
module vga
(
    input wire clk,

    output wire de,
    output wire hsync,
    output wire vsync,

    output wire glyph,
    output wire [6:0] h_glyph,
    output wire [3:0] h_pixel,
    output wire [4:0] v_glyph,
    output wire [4:0] v_pixel
);

wire v_ce;
wire h_active;
wire v_active;

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

    .glyph(h_glyph),
    .pixel(h_pixel)
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

    .glyph(v_glyph),
    .pixel(v_pixel)
);

assign de = h_active & v_active;
assign glyph = de & (h_pixel == 4'b0000);

endmodule
