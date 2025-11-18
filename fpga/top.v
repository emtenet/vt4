`default_nettype none
module top
(
    input wire xtal_in,
    input wire reset_low,

    output wire lcd_clk,
    output wire lcd_hsync,
    output wire lcd_vsync,
    output wire lcd_de,
    output wire [4:0] lcd_r,
    output wire [5:0] lcd_g,
    output wire [4:0] lcd_b
);

assign lcd_clk = xtal_in;

wire [6:0] h_block;
wire [3:0] h_pixel;
wire [4:0] v_block;
wire [4:0] v_pixel;

vga	vga
(
    .clk(lcd_clk),
    .reset_low(reset_low),

    .de(lcd_de),
    .hsync(lcd_hsync),
    .vsync(lcd_vsync),

    .h_block(h_block),
    .h_pixel(h_pixel),
    .v_block(v_block),
    .v_pixel(v_pixel)
);

wire pixel;
assign pixel = (v_pixel == 13 || v_pixel == 14) &&
               (h_pixel == 3 || h_pixel == 4);

assign  lcd_r = (lcd_de && pixel) ? 5'b01111 : 5'b00000;
assign  lcd_g = (lcd_de && pixel) ? 6'b011111 : 6'b000000;
assign  lcd_b = (lcd_de && pixel) ? 5'b01111 : 5'b00000;

endmodule

