`default_nettype none
`timescale 1ns / 1ps
module ps2
(
    input   wire        clk,
    input   wire        reset_low,

    inout   wire        ps2_clk,
    inout   wire        ps2_data,

    input   wire        switch_active_ready,
    output  reg         switch_active_valid,
    output  reg [1:0]   switch_active_to,

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

    wire        command_code_ready;
    wire        command_code_valid;
    wire [7:0]  command_code_byte;

    wire        command_code_ack_ready;
    wire        command_code_ack_valid;
    wire        command_code_ack_error;

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

        .command_code_ready(command_code_ready),
        .command_code_valid(command_code_valid),
        .command_code_byte(command_code_byte),

        .command_code_ack_ready(command_code_ack_ready),
        .command_code_ack_valid(command_code_ack_valid),
        .command_code_ack_error(command_code_ack_error),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),
        .scan_code_error(scan_code_error)
    );

    wire        num_lock_is_on;
    wire        control_is_down;
    wire        caps_lock_is_on;
    wire        scroll_lock_is_on;
    wire        shift_is_down;

    wire        scan_code_is_ack;
    wire        scan_code_is_extended;
    wire        scan_code_is_resend;
    wire        scan_code_is_special;
    wire        scan_code_is_status;

    ps2_state state
    (
        .clk(clk),
        .reset_low(reset_low),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),

        .num_lock_is_on(num_lock_is_on),
        .control_is_down(control_is_down),
        .caps_lock_is_on(caps_lock_is_on),
        .scroll_lock_is_on(scroll_lock_is_on),
        .shift_is_down(shift_is_down),

        .scan_code_is_ack(scan_code_is_ack),
        .scan_code_is_extended(scan_code_is_extended),
        .scan_code_is_resend(scan_code_is_resend),
        .scan_code_is_special(scan_code_is_special),
        .scan_code_is_status(scan_code_is_status),

        .switch_active_ready(switch_active_ready),
        .switch_active_valid(switch_active_valid),
        .switch_active_to(switch_active_to),
    );

    ps2_commands ps2_commands
    (
        .clk(clk),
        .reset_low(reset_low),

        .scan_code_is_ack(scan_code_is_ack),
        .scan_code_is_resend(scan_code_is_resend),
        .scan_code_is_status(scan_code_is_status),

        .caps_lock_is_on(caps_lock_is_on),
        .num_lock_is_on(num_lock_is_on),
        .scroll_lock_is_on(scroll_lock_is_on),

        .command_code_ready(command_code_ready),
        .command_code_valid(command_code_valid),
        .command_code_byte(command_code_byte),

        .command_code_ack_ready(command_code_ack_ready),
        .command_code_ack_valid(command_code_ack_valid),
        .command_code_ack_error(command_code_ack_error),
    );

    ps2_key_codes key_codes
    (
        .clk(clk),
        .reset_low(reset_low),

        .scan_code_ready(scan_code_ready),
        .scan_code_valid(scan_code_valid),
        .scan_code_byte(scan_code_byte),
        .scan_code_is_extended(scan_code_is_extended),
        .scan_code_is_special(scan_code_is_special),

        .num_lock_is_on(num_lock_is_on),
        .control_is_down(control_is_down),
        .caps_lock_is_on(caps_lock_is_on),
        .shift_is_down(shift_is_down),

        .character_ready(character_ready),
        .character_valid(character_valid),
        .character_byte(character_byte)
    );

endmodule