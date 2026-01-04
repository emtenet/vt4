`default_nettype none
module top
(
    input wire          xtal,

    inout wire          ps2_clk_pin,
    inout wire          ps2_data_pin,

    input wire [1:0]    button,
    output wire [5:0]   led,
    output wire [3:0]   diagnosis,

    output wire         hdmi_clk_n,
    output wire         hdmi_clk_p,
    output wire [2:0]   hdmi_data_n,
    output wire [2:0]   hdmi_data_p
);

    `include "common.vh"

    wire        clk;
    wire        clk_5x;
    wire        reset_low;

    wire        vram_read_ready;
    wire        vram_read_valid;
    wire [4:0]  vram_read_row;
    wire [6:0]  vram_read_col;
    wire [7:0]  vram_read_char;

    wire        vram_write_ready;
    wire        vram_write_valid;
    reg [4:0]   vram_write_row;
    reg [6:0]   vram_write_col;
    wire [7:0]  vram_write_char;
    wire        ps2_error;
    wire [1:0]  ps2_state;

    hdmi hdmi
    (
        .xtal(xtal),
        .clk(clk),
        .clk_5x(clk_5x),
        .reset_low(reset_low),

        .top_row(5'd0),

        .vram_valid(vram_read_valid),
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

        .read_ready(vram_read_ready),
        .read_valid(vram_read_valid),
        .read_row(vram_read_row),
        .read_col(vram_read_col),
        .read_char(vram_read_char),

        .write_ready(vram_write_ready),
        .write_valid(vram_write_valid),
        .write_row(vram_write_row),
        .write_col(vram_write_col),
        .write_char(vram_write_char)
    );

    wire    ps2_clk_in;
    wire    ps2_clk_out;
    wire    ps2_clk_oe;

    IOBUF ps2_clk
    (
        .IO(ps2_clk_pin),

        .I(ps2_clk_out),
        .O(ps2_clk_in),
        .OEN(~ps2_clk_oe)
    );

    wire    ps2_data_in;
    wire    ps2_data_out;
    wire    ps2_data_oe;

    IOBUF ps2_data
    (
        .IO(ps2_data_pin),

        .I(ps2_data_out),
        .O(ps2_data_in),
        .OEN(~ps2_data_oe)
    );

    wire    command_ready;
    wire    command_valid;

    button_handshake for_button
    (
        .clk(clk),
        .reset_low(reset_low),

        .button(button[0]),

        .ready(command_ready),
        .valid(command_valid)
    );

    ps2 ps2
    (
        .clk(clk),
        .reset_low(reset_low),

        .ps2_clk_in(ps2_clk_in),
        .ps2_clk_out(ps2_clk_out),
        .ps2_clk_oe(ps2_clk_oe),
        .ps2_data_in(ps2_data_in),
        .ps2_data_out(ps2_data_out),
        .ps2_data_oe(ps2_data_oe),

        .diagnosis_state(ps2_state),
        .error(ps2_error),

        .command_ready(command_ready),
        .command_valid(command_valid),
        .command_data(8'hFF),

        .scan_code_ready(vram_write_ready),
        .scan_code_valid(vram_write_valid),
        .scan_code_data(vram_write_char)
    );

    reg [1:0] ps2_counter;

    initial begin
        ps2_counter = 2'b0;
        vram_write_row = 5'b0;
        vram_write_col = 7'b0;
    end

    always @(posedge clk) begin
        if (reset_low == LOW) begin
            vram_write_row <= 5'b0;
            vram_write_col <= 7'b0;
            ps2_counter = 2'b0;
        end else if (vram_write_valid == YES) begin
            ps2_counter <= ps2_counter + 1;
            if (vram_write_ready == YES) begin
                vram_write_col <= vram_write_col + 1;
                if (vram_write_col == 7'd99) begin
                    vram_write_row <= vram_write_row + 1;
                    vram_write_col <= 7'b0;
                end
            end
        end
    end

    assign led = ~{ps2_error, 3'b0, ps2_counter};

    assign diagnosis = {ps2_state, ps2_error, ~reset_low};

endmodule

