`default_nettype none
`timescale 1ns / 1ps
module request_latch
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        made,
    output  reg         request,
    input   wire        taken
);

    initial begin
        request = NO;
    end

    always_ff @(posedge clk) begin
        if (taken == YES) begin
            request <= NO;
        end

        if (made == YES) begin
            request <= YES;
        end

        if (reset_low == LOW) begin
            request <= NO;
        end
    end

endmodule