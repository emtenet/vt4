`default_nettype none
`timescale 1ns / 1ps
module uart_tx
#(
    parameter CLK = 0, // MHz
    parameter BAUD = 0 // Baud rate
)
(
    input   wire        clk,
    input   wire        reset_low,

    output  logic       pin,

    output  logic       data_ready,
    input   wire        data_valid,
    input   wire [7:0]  data_byte
);

    localparam CYCLES           = (CLK / BAUD);
    localparam CYCLES_STOP      = CYCLES - 1;
    localparam CYCLES_WIDTH     = $clog2(CYCLES);

    logic [CYCLES_WIDTH-1:0]    cycles_stop;

    always_comb begin
        cycles_stop = CYCLES_STOP[CYCLES_WIDTH-1:0];
    end

    localparam STATE_STOP_BIT   = 4'd0;
    localparam STATE_START_BIT  = 4'd7;
    localparam STATE_0_BIT      = 4'd8;
    localparam STATE_1_BIT      = 4'd9;
    localparam STATE_2_BIT      = 4'd10;
    localparam STATE_3_BIT      = 4'd11;
    localparam STATE_4_BIT      = 4'd12;
    localparam STATE_5_BIT      = 4'd13;
    localparam STATE_6_BIT      = 4'd14;
    localparam STATE_7_BIT      = 4'd15;

    reg [3:0]               state;
    reg [CYCLES_WIDTH-1:0]  cycles;
    reg                     start;
    reg [7:0]               data;

    initial begin
        state = STATE_STOP_BIT;
        cycles = 0;
        start = NO;
        data = 0;
    end

    always_comb begin
        data_ready = NO;
        pin = HIGH;

        case (state)
            STATE_STOP_BIT: begin
                data_ready = ~start;
            end
            STATE_START_BIT: begin
                pin = LOW;
            end
            STATE_0_BIT,
            STATE_1_BIT,
            STATE_2_BIT,
            STATE_3_BIT,
            STATE_4_BIT,
            STATE_5_BIT,
            STATE_6_BIT,
            STATE_7_BIT: begin
                pin = data[0];
            end
            default: begin

            end
        endcase

        if (reset_low == LOW) begin
            data_ready = NO;
        end
    end

    always_ff @(posedge clk) begin
        if (data_ready && data_valid) begin
            start <= YES;
            data <= data_byte;
        end

        // transition at baud rate
        if (cycles == cycles_stop) begin
            cycles <= 0;

            case (state)
                STATE_STOP_BIT: begin
                    if (start) begin
                        start <= NO;
                        state <= STATE_START_BIT;
                    end
                end
                STATE_START_BIT: begin
                    state <= state + 1;
                end
                STATE_0_BIT,
                STATE_1_BIT,
                STATE_2_BIT,
                STATE_3_BIT,
                STATE_4_BIT,
                STATE_5_BIT,
                STATE_6_BIT,
                STATE_7_BIT: begin
                    data <= {LOW, data[7:1]};
                    // will roll over to STATE_STOP_BIT
                    state <= state + 1;
                end
                default: begin

                end
            endcase
        end else begin
            cycles <= cycles + 1;
        end

        if (reset_low == LOW) begin
            state <= STATE_STOP_BIT;
            cycles <= 0;
            start <= NO;
            data <= 0;
        end
    end

endmodule
