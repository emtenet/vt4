`default_nettype none
module text_timings (
    input wire          clk,

    input wire          in_active,
    input wire          in_h_sync,
    input wire          in_v_sync,
    input wire          in_h_start,
    input wire          in_v_start,

    output reg          out_active,
    output reg          out_h_sync,
    output reg          out_v_sync,
    output reg [4:0]    out_row,
    output reg [4:0]    out_row_pixel,
    output reg [6:0]    out_col,
    output reg          out_col_start,
    output reg [3:0]    out_col_pixel
);

    `include "common.vh"

    always @(posedge clk) begin
        out_active <= in_active;
        out_h_sync <= in_h_sync;
        out_v_sync <= in_v_sync;

        if (in_active) begin
            if (in_h_start) begin
                out_col <= 0;
                out_col_pixel <= 0;
                out_col_start <= YES;
            end else if (out_col_pixel == 4'd9) begin
                out_col <= out_col + 1;
                out_col_pixel <= 0;
                out_col_start <= YES;
            end else begin
                out_col_pixel <= out_col_pixel + 1;
                out_col_start <= NO;
            end

            if (in_h_start) begin
                if (in_v_start) begin
                    out_row <= 0;
                    out_row_pixel <= 0;
                end else if (out_row_pixel == 5'd19) begin
                    out_row <= out_row + 1;
                    out_row_pixel <= 0;
                end else begin
                    out_row_pixel <= out_row_pixel + 1;
                end
            end
        end else begin
            out_col <= 0;
            out_col_pixel <= 0;
            out_col_start <= NO;
            // retain row count across in-active regions
            out_row <= out_row;
            out_row_pixel <= out_row_pixel;
        end
    end

endmodule
