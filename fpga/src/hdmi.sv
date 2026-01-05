`default_nettype none
`timescale 1ns / 1ps
module hdmi
(
    input   wire        clk,
    input   wire        clk_5x,
    input   wire        reset_low,

    input   wire [4:0]  top_row,

    output  wire        vram_valid,
    output  wire [4:0]  vram_row,
    output  wire [6:0]  vram_col,
    input   wire [7:0]  vram_byte,

    output  wire        hdmi_clk_n,
    output  wire        hdmi_clk_p,
    output  wire [2:0]  hdmi_data_n,
    output  wire [2:0]  hdmi_data_p
);

    wire        stage0_active;
    wire        stage0_h_sync;
    wire        stage0_v_sync;
    wire        stage0_h_start;
    wire        stage0_v_start;

    hdmi_timings hdmi_timings
    (
        .clk(clk),
        .reset_low(reset_low),

        .active(stage0_active),
        .h_sync(stage0_h_sync),
        .v_sync(stage0_v_sync),

        .h_start(stage0_h_start),
        .v_start(stage0_v_start)
    );

    // STAGE 1 - 100 x 30 text display

    wire        stage1_active;
    wire        stage1_h_sync;
    wire        stage1_v_sync;
    wire [4:0]  stage1_row;
    wire [4:0]  stage1_row_pixel;
    wire [6:0]  stage1_col;
    wire        stage1_col_start;
    wire [3:0]  stage1_col_pixel;

    hdmi_text_mode hdmi_text_mode
    (
        .clk(clk),

        .in_active(stage0_active),
        .in_h_sync(stage0_h_sync),
        .in_v_sync(stage0_v_sync),
        .in_h_start(stage0_h_start),
        .in_v_start(stage0_v_start),

        .top_row(top_row),

        .out_active(stage1_active),
        .out_h_sync(stage1_h_sync),
        .out_v_sync(stage1_v_sync),
        .out_row(stage1_row),
        .out_row_pixel(stage1_row_pixel),
        .out_col(stage1_col),
        .out_col_start(stage1_col_start),
        .out_col_pixel(stage1_col_pixel)
    );

    // STAGE 2 - read char from VRAM at row,col

    reg         stage2_active;
    reg         stage2_h_sync;
    reg         stage2_v_sync;
    reg [4:0]   stage2_row_pixel;
    reg         stage2_col_start;
    reg [7:0]   stage2_byte;

    always @(*) begin
        vram_valid = stage1_col_start;
        vram_row = stage1_row;
        vram_col = stage1_col;
    end

    always @(posedge clk) begin
        stage2_active <= stage1_active;
        stage2_h_sync <= stage1_h_sync;
        stage2_v_sync <= stage1_v_sync;
        stage2_row_pixel <= stage1_row_pixel;
        stage2_col_start <= stage1_col_start;
        stage2_byte <= vram_byte;
    end

    // get horizontal pixels for char

    reg         stage3_h_sync;
    reg         stage3_v_sync;
    reg         stage3_active;
    reg         stage3_col_start;
    wire [9:0]  stage3_pixels;

    always @(posedge clk) begin
        stage3_active <= stage2_active;
        stage3_h_sync <= stage2_h_sync;
        stage3_v_sync <= stage2_v_sync;
        stage3_col_start <= stage2_col_start;
    end

    char_rom char_rom
    (
        .clk(clk),
        .ce(stage2_col_start),
        .char(stage2_byte),
        .row(stage2_row_pixel),
        .q(stage3_pixels)
    );

    // STAGE 4 - shift out char pixels

    reg         stage4_h_sync;
    reg         stage4_v_sync;
    reg         stage4_active;
    reg [9:0]   stage4_pixels;
    wire        stage4_pixel;

    always @(posedge clk) begin
        stage4_active <= stage3_active;
        stage4_h_sync <= stage3_h_sync;
        stage4_v_sync <= stage3_v_sync;

        // shift through char pixels
        if (stage3_col_start)
            stage4_pixels <= stage3_pixels;
        else
            stage4_pixels <= {stage4_pixels[8:0], 1'b0};
    end

    always @(*) begin
        stage4_pixel = stage4_pixels[9];
    end

    hdmi_encode hdmi_encode (
        .clk(clk),
        .clk_5x(clk_5x),
        .reset_low(reset_low),

        .active(stage4_active),
        .h_sync(stage4_h_sync),
        .v_sync(stage4_v_sync),
        .rgb({3{stage4_pixel,7'b0}}),

        .hdmi_clk_n(hdmi_clk_n),
        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_data_n(hdmi_data_n),
        .hdmi_data_p(hdmi_data_p)
    );

endmodule
