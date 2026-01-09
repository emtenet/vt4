`default_nettype none
`timescale 1ns / 1ps
module top_rx
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        pin,

    input   wire        data_ready,
    output  wire        data_valid,
    output  wire [7:0]  data_byte
);

    uart_rx
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
