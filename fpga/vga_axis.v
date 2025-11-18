`default_nettype none
module vga_axis
#(
    parameter BLOCKS = 80,
    parameter PIXELS = 10,
    parameter FRONT_PORCH = 210,
    parameter BACK_PORCH = 46
)
(
    input wire clk,
    input wire reset_low,

    input wire increment,
    output wire carry,
    output reg active,
    output wire sync,

    output reg [BLOCK_WIDTH-1:0] block, // row / column index
    output reg [PIXEL_WIDTH-1:0] pixel  // pixel index within row / column
);
localparam  BLOCK_START     = 0;
localparam  BLOCK_STOP      = BLOCKS - 1;
localparam  BLOCK_WIDTH     = $clog2(BLOCKS);
localparam  PIXEL_START     = 0;
localparam  PIXEL_STOP      = PIXELS - 1;
localparam  PIXEL_WIDTH     = $clog2(PIXELS);
localparam  INACTIVE_START  = 0;
localparam  INACTIVE_STOP   = FRONT_PORCH + BACK_PORCH - 1;
localparam  INACTIVE_WIDTH  = $clog2(INACTIVE_STOP + 1);
reg [INACTIVE_WIDTH-1:0] inactive;

always @(posedge clk or negedge reset_low) begin
    if( !reset_low ) begin
        active <= 0;
        inactive <= INACTIVE_START;
    end else if (increment) begin
        if (active) begin
            if (pixel != PIXEL_STOP)
                pixel <= pixel + 1'b1;
            else if (block != BLOCK_STOP) begin
                pixel <= PIXEL_START;
                block <= block + 1'b1;
            end else begin
                active <= 0;
                inactive <= INACTIVE_START;
            end
        end else if (inactive != INACTIVE_STOP) 
            inactive <= inactive + 1'b1;
        else begin
            active <= 1;
            block <= BLOCK_START;
            pixel <= PIXEL_START;
        end
    end
end

assign  sync = ~(~active && (inactive == FRONT_PORCH));

assign carry = increment && ~active && (inactive == INACTIVE_STOP);

endmodule
