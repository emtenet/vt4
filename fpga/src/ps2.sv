`default_nettype none
`timescale 1ns / 1ps
module ps2
(
    input   wire        clk,
    input   wire        reset_low,

    inout   wire        ps2_clk,
    inout   wire        ps2_data,

    input   wire        switch_port_ready,
    output  wire        switch_port_valid,
    output  wire [7:0]  switch_port_data,

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

    wire        command_received_ready;
    wire        command_received_valid;
    wire        command_received_error;

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

        .command_received_ready(command_received_ready),
        .command_received_valid(command_received_valid),
        .command_received_error(command_received_error),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),
        .scan_code_error(scan_code_error)
    );

    wire        scan_code_extended;
    wire        scan_code_special;

    wire        num_lock;
    wire        control;
    wire        caps_lock;
    wire        shift;

    wire        ack_scan_code_received;

    wire        resend_scan_code_received;

    wire        set_status;
    wire        set_status_caps_lock;
    wire        set_status_num_lock;
    wire        set_status_scroll_lock;

    ps2_state state
    (
        .clk(clk),
        .reset_low(reset_low),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),
        .scan_code_extended(scan_code_extended),
        .scan_code_special(scan_code_special),

        .num_lock(num_lock),
        .control(control),
        .caps_lock(caps_lock),
        .shift(shift),

        .ack_scan_code_received(ack_scan_code_received),

        .resend_scan_code_received(resend_scan_code_received),

        .set_status(set_status),
        .set_status_caps_lock(set_status_caps_lock),
        .set_status_num_lock(set_status_num_lock),
        .set_status_scroll_lock(set_status_scroll_lock)
    );

    ps2_commands ps2_commands
    (
        .clk(clk),
        .reset_low(reset_low),

        .ack_scan_code_received(ack_scan_code_received),

        .resend_scan_code_received(resend_scan_code_received),

        .set_status(set_status),
        .set_status_caps_lock(set_status_caps_lock),
        .set_status_num_lock(set_status_num_lock),
        .set_status_scroll_lock(set_status_scroll_lock),

        .command_ready(command_ready),
        .command_valid(command_valid),
        .command_byte(command_byte),

        .command_received_ready(command_received_ready),
        .command_received_valid(command_received_valid),
        .command_received_error(command_received_error),
    );

    ps2_key_codes key_codes
    (
        .clk(clk),
        .reset_low(reset_low),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),
        .scan_code_extended(scan_code_extended),
        .scan_code_special(scan_code_special),

        .num_lock(num_lock),
        .control(control),
        .caps_lock(caps_lock),
        .shift(shift),

        .character_ready(character_ready),
        .character_valid(character_valid),
        .character_byte(character_byte)
    );

endmodule