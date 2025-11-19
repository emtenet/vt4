`default_nettype none
module vga_axis
#(
    parameter GLYPHS = 80,
    parameter PIXELS = 10,
    parameter FRONT_PORCH = 210,
    parameter BACK_PORCH = 46
)
(
    input wire clk,
    input wire ce,

    output wire carry,
    output reg active,
    output wire sync,

    output reg [GLYPH_WIDTH-1:0] glyph, // row / column index
    output reg [PIXEL_WIDTH-1:0] pixel  // pixel within row / column
);
localparam  GLYPH_START     = 0;
localparam  GLYPH_STOP      = GLYPHS - 1;
localparam  GLYPH_WIDTH     = $clog2(GLYPHS);
localparam  PIXEL_START     = 0;
localparam  PIXEL_STOP      = PIXELS - 1;
localparam  PIXEL_WIDTH     = $clog2(PIXELS);
localparam  INACTIVE_START  = 0;
localparam  INACTIVE_STOP   = FRONT_PORCH + BACK_PORCH - 1;
localparam  INACTIVE_WIDTH  = $clog2(INACTIVE_STOP + 1);
reg [INACTIVE_WIDTH-1:0] inactive;

initial active = 0;
initial glyph = 0;
initial pixel = 0;
initial inactive = 0;

always @(posedge clk) begin
    if (ce) begin
        if (active) begin
            if (pixel != PIXEL_STOP)
                pixel <= pixel + 1'b1;
            else if (glyph != GLYPH_STOP) begin
                pixel <= PIXEL_START;
                glyph <= glyph + 1'b1;
            end else begin
                active <= 0;
                inactive <= INACTIVE_START;
            end
        end else if (inactive != INACTIVE_STOP) 
            inactive <= inactive + 1'b1;
        else begin
            active <= 1;
            glyph <= GLYPH_START;
            pixel <= PIXEL_START;
        end
    end
end

assign sync = ~(~active && (inactive == FRONT_PORCH));

assign carry = ce && ~active && (inactive == INACTIVE_STOP);

endmodule
