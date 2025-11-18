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

wire de_next;
wire hsync_next;
wire vsync_next;
wire block;
wire [6:0] h_block;
wire [3:0] h_pixel;
wire [4:0] v_block;
wire [4:0] v_pixel;

vga	vga
(
    .clk(lcd_clk),
    .reset_low(reset_low),

    .de(de_next),
    .hsync(hsync_next),
    .vsync(vsync_next),

    .block(block),
    .h_block(h_block),
    .h_pixel(h_pixel),
    .v_block(v_block),
    .v_pixel(v_pixel)
);

reg hsync_delay;
reg vsync_delay;
reg de_delay;

always @(posedge lcd_clk) begin
    hsync_delay <= hsync_next;
    vsync_delay <= vsync_next;
    de_delay <= de_next;
end
assign lcd_hsync = hsync_delay;
assign lcd_vsync = vsync_delay;
assign lcd_de = de_delay;

char_rom char_rom
(
    .clk(lcd_clk),
    .ce(block),
    .char(8'h32),
    .row(v_block),
    .q(background_next)
);
wire [9:0] background_next;
reg [9:0] background;
always @(posedge lcd_clk) begin
    if (block) begin
        if (h_block == 0)
            background <= background_next;
        else
            background <= {background[8:0], 1'b0};
    end
end

wire pixel;
assign pixel = (v_pixel == 13 || v_pixel == 14) &&
               (h_pixel == 3 || h_pixel == 4);

assign  lcd_r = (lcd_de && pixel) ? 5'b01111 : 5'b00000;
assign  lcd_g = (lcd_de && pixel) ? 6'b011111 : {3'b00, {4{background[9]}}};
assign  lcd_b = (lcd_de && pixel) ? 5'b01111 : 5'b00000;

endmodule

