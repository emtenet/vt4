`default_nettype none
module vga
(
    input wire clk,
    input wire reset_low,

    output wire de,
    output wire hsync,
    output wire vsync,

    output wire [6:0] h_block,
    output wire [3:0] h_pixel,
    output wire [4:0] v_block,
    output wire [4:0] v_pixel
);

wire next_row;
wire h_active;
wire v_active;

vga_axis #(
    .BLOCKS(80),
    .PIXELS(10),
    .FRONT_PORCH(36), // 27MHz
    // .FRONT_PORCH(210), // 33Mhz
    .BACK_PORCH(46)
) h_axis
(
    .clk(clk),
    .reset_low(reset_low),

    .increment(1'b1),
    .carry(next_row),
    .active(h_active),
    .sync(hsync),

    .block(h_block),
    .pixel(h_pixel)
);

vga_axis #(
    .BLOCKS(24),
    .PIXELS(20),
    .FRONT_PORCH(7), // 27MHz
    // .FRONT_PORCH(22), // 33Mhz
    .BACK_PORCH(23)
) v_axis
(
    .clk(clk),
    .reset_low(reset_low),

    .increment(next_row),
    .active(v_active),
    .carry(),
    .sync(vsync),

    .block(v_block),
    .pixel(v_pixel)
);

assign  de = h_active & v_active;

endmodule
