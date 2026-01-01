`default_nettype none
module ps2
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        ps2_clk_pin,
    input   wire        ps2_data_pin,

    input   wire        rx_ready,
    output  reg         rx_valid,
    output  reg         rx_error,
    output  wire [7:0]  rx_data
);

    `include "common.vh"

    wire        ps2_clk;
    wire        ps2_data;

    debouncer
    #(
        .CYCLES(255)
    )
    for_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .bit_in(ps2_clk_pin),
        .bit_out(ps2_clk)
    );

    debouncer
    #(
        .CYCLES(255)
    )
    for_ps2_data
    (
        .clk(clk),
        .reset_low(reset_low),

        .bit_in(ps2_data_pin),
        .bit_out(ps2_data)
    );

    wire ps2_clk_falling;

    edge_detector on_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .level(ps2_clk),

        .neg_edge(ps2_clk_falling)
    );

    localparam STATE_IDLE   = 4'd0; // START
    localparam STATE_BIT_0  = 4'd1;
    localparam STATE_BIT_1  = 4'd2;
    localparam STATE_BIT_1  = 4'd3;
    localparam STATE_BIT_1  = 4'd4;
    localparam STATE_BIT_1  = 4'd5;
    localparam STATE_BIT_1  = 4'd6;
    localparam STATE_BIT_1  = 4'd7;
    localparam STATE_BIT_1  = 4'd8;
    localparam STATE_PARITY = 4'd9;
    localparam STATE_STOP   = 4'd10;
    reg [3:0] state;
    reg [9:0] shifter;
    reg parity;
    wire valid_p2s_frame;

    initial begin
        state = STATE_IDLE;
        shifter = 0;
        parity = LOW;
        rx_valid = NO;
        rx_error = NO;
    end

    assign valid_p2s_frame = (shifter[0] == LOW) // START bit
                          && (parity == HIGH)    // ODD parity
                          && (ps2_data == HIGH); // STOP bit

    always @(posedge clk) begin
        if (reset_low == LOW) begin
            state <= STATE_IDLE;
            shifter <= 0;
            parity <= LOW;
            rx_valid <= NO;
            rx_error <= NO;
        end else if (ps2_clk_falling == YES) begin
            if (state == STATE_STOP) begin
                state <= STATE_IDLE;
                rx_valid <= valid_p2s_frame;
                rx_error <= ~valid_p2s_frame;
            end else begin
                state <= state + 1;
                rx_valid <= NO;
            end
            shifter <= {ps2_data, shifter[9:1]};
            parity <= parity ^ ps2_data;
        end else begin
            state <= state;
            shifter <= shifter;
            parity <= parity;
            if (rx_valid == YES && rx_ready == YES) begin
                rx_valid <= NO;
            end else begin
                rx_valid <= rx_valid;
            end
        end
    end

    always @(*) begin
        rx_data = shifter[7:0];
    end

endmodule