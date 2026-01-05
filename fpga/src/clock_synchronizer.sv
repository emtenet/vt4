`default_nettype none
`timescale 1ns / 1ps
module clock_synchronizer
#(
    parameter EXTRA_DEPTH = 0
)
(
    input   wire       clk,

    input   wire       bit_in,
    output  reg        bit_out
);

    localparam DEPTH = 2 + EXTRA_DEPTH;

    reg [DEPTH-1:0] synchronizer;

    initial begin
        synchronizer = {DEPTH{1'b0}};
    end

    always @(posedge clk) begin
        synchronizer <= {synchronizer[DEPTH-2:0], bit_in};
    end

    always @(*) begin
        bit_out = synchronizer[DEPTH-1];
    end

endmodule
