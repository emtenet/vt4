`default_nettype none
module top
(
    input wire xtal_in,

    output wire lcd_clk,
    output wire lcd_hsync,
    output wire lcd_vsync,
    output wire lcd_de,
    output wire [4:0] lcd_r,
    output wire [5:0] lcd_g,
    output wire [4:0] lcd_b
);

assign lcd_clk = xtal_in;

vga	vga
(
    .clk(lcd_clk),

    .hsync(stage0_hsync),
    .vsync(stage0_vsync),
    .de(stage0_de),

    .glyph(stage0_glyph),
    .h_glyph(stage0_col_index),
    .h_pixel(stage0_col_pixel),
    .v_glyph(stage0_row_index),
    .v_pixel(stage0_row_pixel)
);

wire stage0_hsync;
wire stage0_vsync;
wire stage0_de;
wire stage0_glyph;
wire [6:0] stage0_col_index;
wire [3:0] stage0_col_pixel;
wire [4:0] stage0_row_index;
wire [4:0] stage0_row_pixel;

always @(posedge lcd_clk) begin
    stage1_hsync <= stage0_hsync;
    stage1_vsync <= stage0_vsync;
    stage1_de <= stage0_de;
    stage1_glyph <= stage0_glyph;
    stage1_row_pixel <= stage0_row_pixel;

    // get char for row & column
    if (stage0_glyph) begin
        if (stage0_col_index[6:4] == 3'b000 && stage0_row_index[4] == 1'b0)
            stage1_char <= {stage0_row_index[3:0],stage0_col_index[3:0]};
        else
            stage1_char <= 8'h20;
    end
end

reg stage1_hsync;
reg stage1_vsync;
reg stage1_de;
reg stage1_glyph;
reg [4:0] stage1_row_pixel;
reg [7:0] stage1_char;

always @(posedge lcd_clk) begin
    stage2_hsync <= stage1_hsync;
    stage2_vsync <= stage1_vsync;
    stage2_de <= stage1_de;
    stage2_glyph <= stage1_glyph;
end

// get horizontal pixels for char
char_rom char_rom
(
    .clk(lcd_clk),
    .ce(stage1_glyph),
    .char(stage1_char),
    .row(stage1_row_pixel),
    .q(stage2_pixels)
);

reg stage2_hsync;
reg stage2_vsync;
reg stage2_de;
reg stage2_glyph;
wire [9:0] stage2_pixels;

always @(posedge lcd_clk) begin
    stage3_hsync <= stage2_hsync;
    stage3_vsync <= stage2_vsync;
    stage3_de <= stage2_de;
    stage3_glyph <= stage2_glyph;

    // shift through char pixels
    if (stage2_glyph)
        stage3_pixels <= stage2_pixels;
    else
        stage3_pixels <= {stage3_pixels[8:0], 1'b0};
end

reg stage3_hsync;
reg stage3_vsync;
reg stage3_de;
reg stage3_glyph;
reg [9:0] stage3_pixels;

// display pixel
wire stage3_pixel;
assign stage3_pixel = stage3_pixels[9];

assign lcd_hsync = stage3_hsync;
assign lcd_vsync = stage3_vsync;
assign lcd_de = stage3_de;

// pixel colour
assign lcd_r = {{2{stage3_pixel}}, 3'b000};
assign lcd_g = {{2{stage3_pixel}}, 4'b0000};
assign lcd_b = {{2{stage3_pixel}}, 3'b000};

endmodule

