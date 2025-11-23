`default_nettype none
module top
(
    input wire xtal_in,

    input wire button,
    output wire lcd_backlight,

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

    .row_first(stage0_row_first),
    .row_start(stage0_row_start),
    .row_index(),
    .row_pixel(stage0_row_pixel),

    .col_first(),
    .col_start(stage0_col_start),
    .col_index(stage0_col_index),
    .col_pixel(stage0_col_pixel)
);

wire stage0_hsync;
wire stage0_vsync;
wire stage0_de;
wire stage0_row_first;
wire stage0_row_start;
wire [4:0] stage0_row_pixel;
wire stage0_col_start;
wire [6:0] stage0_col_index;
wire [3:0] stage0_col_pixel;

always @(posedge lcd_clk) begin
    stage1_hsync <= stage0_hsync;
    stage1_vsync <= stage0_vsync;
    stage1_de <= stage0_de;
    if (stage0_row_first)
        stage1_row_index <= 5'h0;
    else if (stage0_row_start)
        stage1_row_index <= stage1_row_index + 1'b1;
    stage1_row_pixel <= stage0_row_pixel;
    stage1_col_start <= stage0_col_start;
    stage1_col_index <= stage0_col_index;
end

reg stage1_hsync;
reg stage1_vsync;
reg stage1_de;
reg [4:0] stage1_row_index;
reg [4:0] stage1_row_pixel;
reg stage1_col_start;
reg [6:0] stage1_col_index;

always @(posedge lcd_clk) begin
    stage2_hsync <= stage1_hsync;
    stage2_vsync <= stage1_vsync;
    stage2_de <= stage1_de;
    stage2_row_pixel <= stage1_row_pixel;
    stage2_col_start <= stage1_col_start;
end

vram vram
(
    .clk(lcd_clk),
    .read_ce(stage1_col_start),
    .read_row(stage1_row_index),
    .read_col(stage1_col_index),
    .read_data(stage2_char)
);

reg stage2_hsync;
reg stage2_vsync;
reg stage2_de;
reg [4:0] stage2_row_pixel;
reg stage2_col_start;
reg [7:0] stage2_char;

always @(posedge lcd_clk) begin
    stage3_hsync <= stage2_hsync;
    stage3_vsync <= stage2_vsync;
    stage3_de <= stage2_de;
    stage3_col_start <= stage2_col_start;
end

// get horizontal pixels for char
char_rom char_rom
(
    .clk(lcd_clk),
    .ce(stage2_col_start),
    .char(stage2_char),
    .row(stage2_row_pixel),
    .q(stage3_pixels)
);

reg stage3_hsync;
reg stage3_vsync;
reg stage3_de;
reg stage3_col_start;
wire [9:0] stage3_pixels;

always @(posedge lcd_clk) begin
    stage4_hsync <= stage3_hsync;
    stage4_vsync <= stage3_vsync;
    stage4_de <= stage3_de;

    // shift through char pixels
    if (stage3_col_start)
        stage4_pixels <= stage3_pixels;
    else
        stage4_pixels <= {stage4_pixels[8:0], 1'b0};
end

reg stage4_hsync;
reg stage4_vsync;
reg stage4_de;
reg [9:0] stage4_pixels;

// display pixel
wire stage4_pixel;
assign stage4_pixel = stage4_pixels[9];

assign lcd_hsync = stage4_hsync;
assign lcd_vsync = stage4_vsync;
assign lcd_de = stage4_de;

// pixel colour
assign lcd_r = {{2{stage4_pixel}}, 3'b000};
assign lcd_g = {{2{stage4_pixel}}, 4'b0000};
assign lcd_b = {{2{stage4_pixel}}, 3'b000};

assign lcd_backlight = button;

endmodule

