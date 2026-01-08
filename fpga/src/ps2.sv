`default_nettype none
`timescale 1ns / 1ps
module ps2
(
    input   wire        clk,
    input   wire        reset_low,

    inout   wire        ps2_clk,
    inout   wire        ps2_data,

    input   wire        character_ready,
    output  wire        character_valid,
    output  wire [7:0]  character_byte,
);

    wire        ps2_clk_in;
    wire        ps2_clk_out;
    wire        ps2_clk_oe;

    ps2_physical for_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .pin(ps2_clk),

        .in(ps2_clk_in),
        .out(ps2_clk_out),
        .oe(ps2_clk_oe)
    );

    wire        ps2_data_in;
    wire        ps2_data_out;
    wire        ps2_data_oe;

    ps2_physical for_ps2_data
    (
        .clk(clk),
        .reset_low(reset_low),

        .pin(ps2_data),

        .in(ps2_data_in),
        .out(ps2_data_out),
        .oe(ps2_data_oe)
    );

    wire        command_ready;
    wire        command_valid;
    wire [7:0]  command_byte;

    wire        command_ack_ready;
    wire        command_ack_valid;
    wire        command_ack_error;

    wire        scan_code_ready;
    wire        scan_code_valid;
    wire [7:0]  scan_code_byte;
    wire        scan_code_error;

    ps2_protocol protocol
    (
        .clk(clk),
        .reset_low(reset_low),

        .ps2_clk_in(ps2_clk_in),
        .ps2_clk_out(ps2_clk_out),
        .ps2_clk_oe(ps2_clk_oe),
        .ps2_data_in(ps2_data_in),
        .ps2_data_out(ps2_data_out),
        .ps2_data_oe(ps2_data_oe),

        .command_ready(command_ready),
        .command_valid(command_valid),
        .command_byte(command_byte),

        .command_ack_ready(command_ack_ready),
        .command_ack_valid(command_ack_valid),
        .command_ack_error(command_ack_error),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),
        .scan_code_error(scan_code_error)
    );

    ps2_state state
    (
        .clk(clk),
        .reset_low(reset_low),

        .command_ready(command_ready),
        .command_valid(command_valid),
        .command_byte(command_byte),

        .command_ack_ready(command_ack_ready),
        .command_ack_valid(command_ack_valid),
        .command_ack_error(command_ack_error),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),

        .character_ready(character_ready),
        .character_valid(character_valid),
        .character_byte(character_byte)
    );

endmodule