`default_nettype none
`timescale 1ns / 1ps
module ps2_physical
(
    input   wire        clk,
    input   wire        reset_low,

    inout   wire        pin,

    output  wire        in,
    input   wire        out,
    input   wire        oe
);

    wire        bouncy;

    IOBUF ps2_clk
    (
        .IO(pin),

        .I(out),
        .O(bouncy),
        .OEN(~oe)
    );

    debouncer
    #(
        .CYCLES(255)
    )
    for_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .bit_in(bouncy),
        .bit_out(in)
    );

endmodule