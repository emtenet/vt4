`default_nettype none
`timescale 1ns / 1ps
module top
(
    input wire          xtal,

    inout wire          ps2_clk,
    inout wire          ps2_data,

    input wire [1:0]    button,
    output wire [5:0]   led,
    output wire [3:0]   diagnosis,

    output wire         hdmi_clk_n,
    output wire         hdmi_clk_p,
    output wire [2:0]   hdmi_data_n,
    output wire [2:0]   hdmi_data_p
);

    //==========================================
    // Prepare HDMI pipeline
    //==========================================

    wire        clk;
    wire        clk_5x;
    wire        lock;
    wire        reset_low;

    hdmi_clk hdmi_clk
    (
        .xtal(xtal),
        .clk(clk),
        .clk_5x(clk_5x),
        .lock(lock)
    );

    clock_synchronizer for_reset
    (
        .clk(clk),

        .bit_in(lock),
        .bit_out(reset_low)
    );

    //==========================================
    // Button press sends a PS/2 command
    //==========================================

    // wire    command_ready;
    // wire    command_valid;

    // button_handshake for_button
    // (
    //     .clk(clk),
    //     .reset_low(reset_low),

    //     .button(button[0]),

    //     .ready(command_ready),
    //     .valid(command_valid)
    // );

    //==========================================
    // PS/2 frame logic
    //==========================================

    wire        character_ready;
    wire        character_valid;
    wire [7:0]  character_byte;

    ps2 ps2
    (
        .clk(clk),
        .reset_low(reset_low),

        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),

        .character_ready(character_ready),
        .character_valid(character_valid),
        .character_byte(character_byte)
    );

    //==========================================
    // VRAM
    //==========================================

    wire        vram_read_ready;
    wire        vram_read_valid;
    wire [4:0]  vram_read_row;
    wire [6:0]  vram_read_col;
    wire [7:0]  vram_read_byte;

    wire        vram_write_ready;
    wire        vram_write_valid;
    reg [4:0]   vram_write_row;
    reg [6:0]   vram_write_col;
    wire [7:0]  vram_write_byte;

    vram vram
    (
        .clk(clk),

        .read_ready(vram_read_ready),
        .read_valid(vram_read_valid),
        .read_row(vram_read_row),
        .read_col(vram_read_col),
        .read_byte(vram_read_byte),

        .write_ready(vram_write_ready),
        .write_valid(vram_write_valid),
        .write_row(vram_write_row),
        .write_col(vram_write_col),
        .write_byte(vram_write_byte)
    );

    //==========================================
    // Write characters to VRAM
    //==========================================

    character_writer character_writer
    (
        .clk(clk),
        .reset_low(reset_low),

        .character_ready(character_ready),
        .character_valid(character_valid),
        .character_byte(character_byte),

        .write_ready(vram_write_ready),
        .write_valid(vram_write_valid),
        .write_row(vram_write_row),
        .write_col(vram_write_col),
        .write_byte(vram_write_byte)
    );

    //==========================================
    // Display VRAM to HDMI
    //==========================================

    hdmi hdmi
    (
        .clk(clk),
        .clk_5x(clk_5x),
        .reset_low(reset_low),

        .top_row(5'd0),

        .vram_valid(vram_read_valid),
        .vram_row(vram_read_row),
        .vram_col(vram_read_col),
        .vram_byte(vram_read_byte),

        .hdmi_clk_n(hdmi_clk_n),
        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_data_n(hdmi_data_n),
        .hdmi_data_p(hdmi_data_p)
    );

    // assign led = ~{scan_code_error, 5'b0};

    // assign diagnosis = {2'b0, scan_code_error, ~reset_low};

endmodule
