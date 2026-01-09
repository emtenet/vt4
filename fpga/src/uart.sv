`default_nettype none
`timescale 1ns / 1ps
module uart
#(
    parameter CLK = 0, // MHz
    parameter BAUD = 0 // Baud rate
)
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        rx_pin,
    input   wire        rx_ready,
    output  reg         rx_valid,
    output  wire [7:0]  rx_byte,

    output  wire        tx_pin,
    output  wire        tx_ready,
    input   wire        tx_valid,
    input   wire [7:0]  tx_byte
);

    wire        rx_debounced;

    debouncer
    #(
        .CYCLES(255)
    )
    for_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .bit_in(rx_pin),
        .bit_out(rx_debounced)
    );

    uart_rx
    #(
        .CLK(CLK)
        .BAUD(BAUD)
    )
    uart_rx
    (
        .clk(clk),
        .reset_low(reset_low),

        .pin(rx_debounced),

        .data_ready(rx_ready),
        .data_valid(rx_valid),
        .data_byte(rx_byte)
    );

    uart_tx
    #(
        .CLK(CLK)
        .BAUD(BAUD)
    )
    uart_tx
    (
        .clk(clk),
        .reset_low(reset_low),

        .pin(tx_pin),

        .data_ready(tx_ready),
        .data_valid(tx_valid),
        .data_byte(tx_byte)
    );

endmodule
