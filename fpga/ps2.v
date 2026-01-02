`default_nettype none
module ps2
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        ps2_clk_pin,
    input   wire        ps2_data_pin,

    output  reg         frame_error,

    input   wire        scan_code_ready,
    output  reg         scan_code_valid,
    output  reg [7:0]   scan_code
);

    `include "common.vh"

    wire        ps2_clk;

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

    wire        ps2_data;

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

    localparam STATE_IDLE   = 1'd0;
    localparam STATE_RX     = 1'd1;

    localparam FRAME_BIT_0  = 4'd0;
    localparam FRAME_BIT_1  = 4'd1;
    localparam FRAME_BIT_1  = 4'd2;
    localparam FRAME_BIT_1  = 4'd3;
    localparam FRAME_BIT_1  = 4'd4;
    localparam FRAME_BIT_1  = 4'd5;
    localparam FRAME_BIT_1  = 4'd6;
    localparam FRAME_BIT_1  = 4'd7;
    localparam FRAME_PARITY = 4'd8;
    localparam FRAME_STOP   = 4'd9;
    reg state;
    reg [3:0] frame;
    reg parity;

    // slowest frame @ 10kHz = 1100us
    // is 56,980 cycles at 51.8MHz
    // round up to 65,535 (16 bit counter)
    reg [15:0] watchdog;
    localparam WATCHDOG_START   = 16'b0;
    localparam WATCHDOG_END     = 16'b1111_1111_1111_1111;

    wire frame_is_valid;
    assign frame_is_valid = (parity == HIGH)    // ODD parity
                         && (ps2_data == HIGH); // STOP bit

    initial begin
        state = STATE_IDLE;
        frame = FRAME_BIT_0;
        parity = LOW;
        scan_code_valid = NO;
        scan_code = 8'b0;
        frame_error = NO;
        watchdog = WATCHDOG_START;
    end

    always @(posedge clk) begin
        if (scan_code_valid == YES && scan_code_ready == YES) begin
            scan_code_valid <= NO;
        end

        if (ps2_clk_falling == YES) begin
            case (state)
                STATE_IDLE: begin
                    // START bit?
                    if (ps2_data == LOW) begin
                        state <= STATE_RX;
                        frame <= FRAME_BIT_0;
                        parity <= LOW;
                        scan_code_valid <= NO;
                        watchdog <= WATCHDOG_START;
                    end
                end
                STATE_RX: begin
                    frame <= frame + 1;
                    case (frame)
                        default: begin
                            scan_code <= {ps2_data, scan_code[7:1]};
                            parity <= parity ^ ps2_data;
                        end
                        FRAME_PARITY: begin
                            parity <= parity ^ ps2_data;
                        end
                        FRAME_STOP: begin
                            state <= STATE_IDLE;
                            scan_code_valid <= frame_is_valid;
                            frame_error <= ~frame_is_valid;
                        end
                    endcase
                end
            endcase
        end

        if (state == STATE_RX) begin
            watchdog <= watchdog + 1;
            if (watchdog == WATCHDOG_END) begin
                state <= STATE_IDLE;
                frame_error <= YES;
            end
        end

        if (reset_low == LOW) begin
            state <= STATE_IDLE;
            frame <= FRAME_BIT_0;
            parity <= LOW;
            scan_code_valid <= NO;
            scan_code <= 8'b0;
            frame_error <= NO;
            watchdog <= WATCHDOG_START;
        end
    end

endmodule