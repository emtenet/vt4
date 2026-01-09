`default_nettype none
`timescale 1ns / 1ps
module uart_rx
#(
    parameter CLK = 0, // MHz
    parameter BAUD = 0 // Baud rate
)
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        pin,

    input   wire        data_ready,
    output  reg         data_valid,
    output  reg [7:0]   data_byte
);

    wire        pin_rising;
    wire        pin_falling;
    wire        pin_changed;

    edge_detector on_pin
    (
        .clk(clk),
        .reset_low(reset_low),

        .level(pin),

        .pos_edge(pin_rising),
        .neg_edge(pin_falling),
        .any_edge(pin_changed)
    );

    localparam CYCLES           = (CLK / BAUD);
    localparam CYCLES_STOP      = CYCLES - 1;
    localparam CYCLES_HALF      = (CYCLES / 2);
    localparam CYCLES_WIDTH     = $clog2(CYCLES);

    logic [CYCLES_WIDTH-1:0]    cycles_half;
    logic [CYCLES_WIDTH-1:0]    cycles_stop;

    always_comb begin
        cycles_half = CYCLES_HALF[CYCLES_WIDTH-1:0];
        cycles_stop = CYCLES_STOP[CYCLES_WIDTH-1:0];
    end

    localparam STATE_IDLE       = 4'd0;
    localparam STATE_START_BIT  = 4'd1;
    localparam STATE_0_BIT      = 4'd2;
    localparam STATE_1_BIT      = 4'd3;
    localparam STATE_2_BIT      = 4'd4;
    localparam STATE_3_BIT      = 4'd5;
    localparam STATE_4_BIT      = 4'd6;
    localparam STATE_5_BIT      = 4'd7;
    localparam STATE_6_BIT      = 4'd8;
    localparam STATE_7_BIT      = 4'd9;
    localparam STATE_STOP_BIT   = 4'd10;

    reg [3:0]               state;
    reg [CYCLES_WIDTH-1:0]  cycles;

    initial begin
        data_byte = 0;
        data_valid = NO;
        state = STATE_IDLE;
        cycles = 0;
    end

    always_ff @(posedge clk) begin
        if (data_ready && data_valid) begin
            data_valid <= NO;
        end

        case (state)
            STATE_IDLE: begin
                if (pin_falling) begin
                    // missed it!
                    data_valid <= NO;
                    // start RX
                    state <= state + 1;
                    // find half way between rising & falling edges
                    cycles <= cycles_half;
                end
            end
            STATE_START_BIT: begin
                if (cycles == cycles_stop) begin
                    state <= state + 1;
                    cycles <= 0;
                end else begin
                    cycles <= cycles + 1;
                end
            end
            STATE_0_BIT,
            STATE_1_BIT,
            STATE_2_BIT,
            STATE_3_BIT,
            STATE_4_BIT,
            STATE_5_BIT,
            STATE_6_BIT,
            STATE_7_BIT: begin
                if (cycles == cycles_stop) begin
                    data_byte <= {pin, data_byte[7:1]};
                    state <= state + 1;
                    cycles <= 0;
                end else begin
                    cycles <= cycles + 1;
                end
            end
            STATE_STOP_BIT: begin
                if (cycles == cycles_stop) begin
                    if (pin == HIGH) begin
                        data_valid <= YES;
                    end else begin
                        // error
                    end
                    state <= STATE_IDLE;
                    cycles <= 0;
                end else begin
                    cycles <= cycles + 1;
                end
            end
            default: begin

            end
        endcase

        if (reset_low == LOW) begin
            data_byte <= 0;
            data_valid <= NO;
            state <= STATE_IDLE;
            cycles <= 0;
        end
    end

endmodule
