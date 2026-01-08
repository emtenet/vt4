`default_nettype none
`timescale 1ns / 1ps
module ps2_protocol
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        ps2_clk_in,
    output  logic       ps2_clk_out,
    output  logic       ps2_clk_oe,
    input   wire        ps2_data_in,
    output  logic       ps2_data_out,
    output  logic       ps2_data_oe,

    output  logic       command_ready,
    input   wire        command_valid,
    input   wire [7:0]  command_byte,

    input   wire        command_ack_ready,
    output  reg         command_ack_valid,
    output  reg         command_ack_error,

    input   wire        scan_code_ready,
    output  reg         scan_code_valid,
    output  logic [7:0] scan_code_byte,
    output  reg         scan_code_error
);

    localparam START_BIT    = LOW;
    localparam STOP_BIT     = HIGH;
    localparam ACK_BIT      = LOW;

    localparam ODD_PARITY   = HIGH;

    //==========================================
    // Sanitize PS/2 clk & data lines
    //==========================================

    wire        ps2_clk;
    wire        ps2_data;
    wire        ps2_clk_rising;
    wire        ps2_clk_falling;
    wire        ps2_clk_changed;

    debouncer
    #(
        .CYCLES(255)
    )
    for_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .bit_in(ps2_clk_in),
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

        .bit_in(ps2_data_in),
        .bit_out(ps2_data)
    );

    edge_detector on_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .level(ps2_clk),

        .pos_edge(ps2_clk_rising),
        .neg_edge(ps2_clk_falling),
        .any_edge(ps2_clk_changed)
    );

    //==========================================
    // Timers
    //==========================================

    logic       watchdog_clear;
    logic       watchdog_enabled;
    wire        watchdog_finished;

    // slowest frame is every 11 bits @ 10kHz = 1100us
    timer
    #(
        .CLK_HZ(51_800_000),
        .TIMER_HZ(10_000 / 11)
    )
    watchdog
    (
        .clk(clk),
        .reset_low(reset_low),

        .clear(watchdog_clear),
        .enabled(watchdog_enabled),

        .finished(watchdog_finished)
    );

    logic       delay_clear;
    logic       delay_enabled;
    wire        delay_finished;

    // Used for
    //  - request to tx
    //  - end of rx/tx frames
    // Request to tx must be at least 100us
    timer
    #(
        .CLK_HZ(51_800_000),
        .TIMER_HZ(1_000_000 / 100)
    )
    delay
    (
        .clk(clk),
        .reset_low(reset_low),

        .clear(delay_clear),
        .enabled(delay_enabled),

        .finished(delay_finished)
    );

    //==========================================
    // State Machine
    //==========================================

    localparam STATE_IDLE       = 5'd0;

    localparam STATE_RX_BIT_0   = 5'd5;
    localparam STATE_RX_BIT_1   = 5'd6;
    localparam STATE_RX_BIT_2   = 5'd7;
    localparam STATE_RX_BIT_3   = 5'd8;
    localparam STATE_RX_BIT_4   = 5'd9;
    localparam STATE_RX_BIT_5   = 5'd10;
    localparam STATE_RX_BIT_6   = 5'd11;
    localparam STATE_RX_BIT_7   = 5'd12;
    localparam STATE_RX_PARITY  = 5'd13;
    localparam STATE_RX_STOP    = 5'd14;
    localparam STATE_RX_END     = 5'd15;

    localparam STATE_TX_REQUEST = 5'd19;
    localparam STATE_TX_START   = 5'd20;
    localparam STATE_TX_BIT_0   = 5'd21;
    localparam STATE_TX_BIT_1   = 5'd22;
    localparam STATE_TX_BIT_2   = 5'd23;
    localparam STATE_TX_BIT_3   = 5'd24;
    localparam STATE_TX_BIT_4   = 5'd25;
    localparam STATE_TX_BIT_5   = 5'd26;
    localparam STATE_TX_BIT_6   = 5'd27;
    localparam STATE_TX_BIT_7   = 5'd28;
    localparam STATE_TX_PARITY  = 5'd29;
    localparam STATE_TX_STOP    = 5'd30;
    localparam STATE_TX_ACK     = 5'd31;
    reg [4:0]   state;
    logic       state_is_tx;

    reg [7:0]   scan_code;
    reg         scan_code_parity;
    reg         scan_code_success;

    reg [9:0]   command;
    logic       command_parity;
    reg         command_success;

    always_comb begin
        // STATE_RX is  1..15
        // STATE_TX is 19..31
        state_is_tx = state[4];

        command_ready = (state == STATE_IDLE) && (reset_low == HIGH);
        command_parity = ~(^ command_byte);

        scan_code_byte = scan_code;
    end

    //==========================================
    // State Transitions
    //==========================================

    logic       did_rx_start;
    logic       did_rx_bit;
    logic       did_rx_parity;
    logic       was_rx_success;
    logic       did_rx_end;

    logic       did_tx_start;
    logic       did_tx_bit;
    logic       was_tx_success;
    logic       did_tx_end;

    logic       next_state;

    always_comb begin
        ps2_clk_oe = NO;
        ps2_clk_out = LOW;

        ps2_data_oe = NO;
        ps2_data_out = command[0];

        watchdog_clear = NO;
        watchdog_enabled = (state != STATE_IDLE);

        delay_clear = NO;
        delay_enabled = NO;

        did_rx_start = NO;
        did_rx_bit = NO;
        did_rx_parity = NO;
        was_rx_success = NO;
        did_rx_end = NO;

        did_tx_start = NO;
        did_tx_bit = NO;
        was_tx_success = NO;
        did_tx_end = NO;

        next_state = NO;

        case (state)
            STATE_IDLE: begin
                if (command_valid == YES) begin
                    did_tx_start = YES;
                    watchdog_clear = YES;
                    delay_clear = YES;
                end else if (ps2_clk_falling == YES) begin
                    if (ps2_data == START_BIT) begin
                        did_rx_start = YES;
                        watchdog_clear = YES;
                    end
                end
            end

            // RX states

            STATE_RX_BIT_0,
            STATE_RX_BIT_1,
            STATE_RX_BIT_2,
            STATE_RX_BIT_3,
            STATE_RX_BIT_4,
            STATE_RX_BIT_5,
            STATE_RX_BIT_6,
            STATE_RX_BIT_7: begin
                if (ps2_clk_falling == YES) begin
                    next_state = YES;
                    did_rx_bit = YES;
                    did_rx_parity = YES;
                end
            end
            STATE_RX_PARITY: begin
                if (ps2_clk_falling == YES) begin
                    next_state = YES;
                    did_rx_parity = YES;
                end
            end
            STATE_RX_STOP: begin
                if (ps2_clk_falling == YES) begin
                    next_state = YES;
                    was_rx_success = YES;
                    delay_clear = YES;
                end
            end
            STATE_RX_END: begin
                delay_enabled = YES;
                if (delay_finished == YES) begin
                    did_rx_end = YES;
                end
            end

            // TX states

            STATE_TX_REQUEST: begin
                ps2_clk_oe = YES;
                ps2_data_oe = YES;
                delay_enabled = YES;
                if (delay_finished == YES) begin
                    next_state = YES;
                end
            end
            STATE_TX_START: begin
                ps2_data_oe = YES;
                if (ps2_clk_falling == YES) begin
                    watchdog_clear = YES;
                    next_state = YES;
                    did_tx_bit = YES;
                end
            end
            STATE_TX_BIT_0,
            STATE_TX_BIT_1,
            STATE_TX_BIT_2,
            STATE_TX_BIT_3,
            STATE_TX_BIT_4,
            STATE_TX_BIT_5,
            STATE_TX_BIT_6,
            STATE_TX_BIT_7,
            STATE_TX_PARITY: begin
                ps2_data_oe = YES;
                if (ps2_clk_falling == YES) begin
                    next_state = YES;
                    did_tx_bit = YES;
                end
            end
            STATE_TX_STOP: begin
                if (ps2_clk_falling == YES) begin
                    next_state = YES;
                    was_tx_success = YES;
                    delay_clear = YES;
                end
            end
            STATE_TX_ACK: begin
                delay_enabled = YES;
                if (delay_finished == YES) begin
                    did_tx_end = YES;
                end
            end
            default: begin

            end
        endcase
    end

    initial begin
        state = STATE_IDLE;

        scan_code_valid = NO;
        scan_code = 8'b0;
        scan_code_parity = LOW;
        scan_code_success = NO;
        scan_code_error = NO;

        command = 10'b0;
        command_success = NO;
        command_ack_valid = NO;
        command_ack_error = NO;
    end

    always_ff @(posedge clk) begin
        // Channel handshakes

        if (scan_code_valid == YES && scan_code_ready == YES) begin
            scan_code_valid <= NO;
            scan_code <= 8'b0;
        end

        if (command_ack_valid == YES && command_ack_ready == YES) begin
            command_ack_valid <= NO;
            command_ack_error <= NO;
        end

        // RX transitions

        if (did_rx_start == YES) begin
            state <= STATE_RX_BIT_0;
            scan_code_valid <= NO;
            scan_code_parity <= LOW;
        end

        if (did_rx_bit == YES) begin
            scan_code <= {ps2_data, scan_code[7:1]};
        end

        if (did_rx_parity == YES) begin
            scan_code_parity <= scan_code_parity ^ ps2_data;
        end

        if (was_rx_success == YES) begin
            scan_code_success <= (scan_code_parity == ODD_PARITY)
                              && (ps2_data == STOP_BIT);
        end

        if (did_rx_end == YES) begin
            state <= STATE_IDLE;
            scan_code_valid <= scan_code_success;
            scan_code_error <= ~scan_code_success;
        end

        // TX transitions

        if (did_tx_start == YES) begin
            state <= STATE_TX_REQUEST;
            command <= {command_parity, command_byte, START_BIT};
            command_ack_valid <= NO;
            command_ack_error <= NO;
        end

        if (did_tx_bit == YES) begin
            command <= {STOP_BIT, command[9:1]};
        end

        if (was_tx_success) begin
            command_success <= (ps2_data == ACK_BIT);
        end

        if (did_tx_end) begin
            state <= STATE_IDLE;
            command_ack_valid <= YES;
            command_ack_error <= ~command_success;
        end

        // General transitions

        if (next_state == YES) begin
            state <= state + 1;
        end

        if (watchdog_enabled == YES && watchdog_finished == YES) begin
            state <= STATE_IDLE;
            if (state_is_tx == YES) begin
                command_ack_valid <= YES;
                command_ack_error <= YES;
            end else begin
                scan_code_error <= YES;
            end
        end

        // Reset

        if (reset_low == LOW) begin
            state <= STATE_IDLE;

            scan_code_valid <= NO;
            scan_code <= 8'b0;
            scan_code_parity <= LOW;
            scan_code_success <= NO;
            scan_code_error <= NO;

            command <= 10'b0;
            command_success <= NO;
            command_ack_valid <= NO;
            command_ack_error <= NO;
        end
    end

endmodule
