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

    output reg glyph_is_zero,
    output reg pixel_is_zero,
    output reg [GLYPH_WIDTH-1:0] glyph_index,
    output reg [PIXEL_WIDTH-1:0] pixel_index
);
localparam  ONE = 1'b1;
localparam  YES = 1'b1;
localparam  NO = 1'b0;
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

initial active = NO;
initial glyph_is_zero = NO;
initial glyph_index = 0;
initial pixel_is_zero = NO;
initial pixel_index = 0;
initial inactive = 0;

always @(posedge clk) begin
    if (ce) begin
        if (active) begin
            glyph_is_zero <= NO;
            if (pixel_index != PIXEL_STOP) begin
                pixel_is_zero <= NO;
                pixel_index <= pixel_index + ONE;
            end else if (glyph_index != GLYPH_STOP) begin
                pixel_is_zero <= YES;
                pixel_index <= PIXEL_START;
                glyph_index <= glyph_index + ONE;
            end else begin
                pixel_is_zero <= NO;
                active <= NO;
                inactive <= INACTIVE_START;
            end
        end else if (inactive != INACTIVE_STOP) begin
            glyph_is_zero <= NO;
            pixel_is_zero <= NO;
            inactive <= inactive + ONE;
        end else begin
            active <= YES;
            glyph_is_zero <= YES;
            glyph_index <= GLYPH_START;
            pixel_is_zero <= YES;
            pixel_index <= PIXEL_START;
        end
    end else begin
        glyph_is_zero <= NO;
        pixel_is_zero <= NO;
    end
end

assign sync = ~(~active && (inactive == FRONT_PORCH));

assign carry = ce && ~active && (inactive == INACTIVE_STOP);

endmodule
