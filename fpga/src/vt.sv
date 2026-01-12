`default_nettype none
`timescale 1ns / 1ps
module vt
(
    input   wire        clk,
    input   wire        reset_low,

    output  logic       host_ready,
    input   wire        host_valid,
    input   wire [7:0]  host_byte,

    input   wire        vram_ready,
    output  logic       vram_valid,
    output  logic [4:0] vram_row,
    output  logic [6:0] vram_col,
    output  logic [7:0] vram_byte,

    output  reg [4:0]   top_row,

    output  reg [4:0]   cursor_row,
    output  reg [6:0]   cursor_col
);

    localparam  INITIAL_TOP_ROW     = 5'd0;
    localparam  INITIAL_BOTTOM_ROW  = 5'd29;
    localparam  INITIAL_CURSOR_ROW  = 5'd1;
    localparam  INITIAL_CURSOR_COL  = 7'd0;
    localparam  COL_FIRST           = 7'd0;
    localparam  COL_LAST            = 7'd99;

    reg [4:0]   bottom_row;

    initial begin
        top_row = INITIAL_TOP_ROW;
        bottom_row = INITIAL_BOTTOM_ROW;

        cursor_row = INITIAL_CURSOR_ROW;
        cursor_col = INITIAL_CURSOR_COL;
    end

    always_comb begin
        host_ready = vram_ready;

        vram_valid = host_valid;
        vram_row = cursor_row;
        vram_col = cursor_col;
        vram_byte = host_byte;
    end

    always @(posedge clk) begin
        if (vram_valid == YES && vram_ready == YES) begin
            cursor_col <= cursor_col + 1;
            if (vram_col == COL_LAST) begin
                if (cursor_row == bottom_row) begin
                    top_row <= top_row + 1;
                    bottom_row <= bottom_row + 1;
                end
                cursor_row <= cursor_row + 1;
                cursor_col <= COL_FIRST;
            end
        end

        if (reset_low == LOW) begin
            top_row <= INITIAL_TOP_ROW;
            bottom_row <= INITIAL_BOTTOM_ROW;

            cursor_row <= INITIAL_CURSOR_ROW;
            cursor_col <= INITIAL_CURSOR_COL;
        end
    end

endmodule
