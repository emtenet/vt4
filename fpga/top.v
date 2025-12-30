`default_nettype none
module top
(
    input wire          xtal,

    input wire          ps2_clk_pin,
    input wire          ps2_data_pin,

    input wire          button,
    output reg [5:0]    led,

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

    reg [4:0]   vram_write_row;
    reg [6:0]   vram_write_col;

    hdmi hdmi
    (
        .xtal(xtal),
        .clk(clk),
        .clk_5x(clk_5x),
        .reset_low(reset_low),

        .top_row(5'd0),

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

        .write_ce(ps2_valid & ~vram_read_ce),
        .write_row(vram_write_row),
        .write_col(vram_write_col),
        .write_char(ps2_data)
    );

    wire        ps2_valid;
    wire [7:0]  ps2_data;

    ps2 ps2
    (
        .clk(clk),
        .reset_low(button), //reset_low),

        .ps2_clk_pin(ps2_clk_pin),
        .ps2_data_pin(ps2_data_pin),

        .rx_ready(~vram_read_ce),
        .rx_valid(ps2_valid),
        .rx_data(ps2_data)
    );

    initial begin
        led = ~6'b0;
        vram_write_row = 5'b0;
        vram_write_col = 7'b0;
    end

    always @(posedge clk) begin
        if (reset_low == LOW) begin
            vram_write_row <= 5'b0;
            vram_write_col <= 7'b0;
            led <= ~6'b0;
        end else if (button == LOW) begin
            led <= ~6'b0;
        end else if (ps2_valid == YES) begin
            led <= ~ps2_data[5:0];
            if (~vram_read_ce) begin
                vram_write_col <= vram_write_col + 1;
                if (vram_write_col == 7'd99) begin
                    vram_write_row <= vram_write_row + 1;
                    vram_write_col <= 7'b0;
                end
            end
        end
    end

endmodule

