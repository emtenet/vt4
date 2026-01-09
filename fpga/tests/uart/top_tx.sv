`default_nettype none
`timescale 1ns / 1ps
module top_tx
(
    input   wire        clk,
    input   wire        reset_low,

    output  wire        pin,

    output  wire        data_ready,
    input   wire        data_valid,
    input   wire [7:0]  data_byte
);

    uart_tx
    #(
        .CLK(51_800_000),
        .BAUD(115200)
    )
    uut
    (
        .clk(clk),
        .reset_low(reset_low),

        .pin(pin),

        .data_ready(data_ready),
        .data_valid(data_valid),
        .data_byte(data_byte)
    );

endmodule
