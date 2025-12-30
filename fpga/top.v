`default_nettype none
module top
(
    input wire          xtal,

    output wire         hdmi_clk_n,
    output wire         hdmi_clk_p,
    output wire [2:0]   hdmi_data_n,
    output wire [2:0]   hdmi_data_p
);

    `include "common.vh"

    wire        clk;
    wire        clk_5x;
    wire        reset_low;

    wire        vram_read_ce;
    wire [4:0]  vram_read_row;
    wire [6:0]  vram_read_col;
    wire [7:0]  vram_read_char;

    hdmi hdmi
    (
        .xtal(xtal),
        .clk(clk),
        .clk_5x(clk_5x),
        .reset_low(reset_low),

        .top_row(0),

        .vram_ce(vram_read_ce),
        .vram_row(vram_read_row),
        .vram_col(vram_read_col),
        .vram_char(vram_read_char),

        .hdmi_clk_n(hdmi_clk_n),
        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_data_n(hdmi_data_n),
        .hdmi_data_p(hdmi_data_p)
    );

    vram vram
    (
        .clk(clk),

        .read_ce(vram_read_ce),
        .read_row(vram_read_row),
        .read_col(vram_read_col),
        .read_char(vram_read_char),

        .write_ce(NO),
        .write_row(5'b0),
        .write_col(7'b0),
        .write_char("?")
    );

endmodule

