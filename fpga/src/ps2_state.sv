`default_nettype none
`timescale 1ns / 1ps
module ps2_state
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        command_ready,
    output  logic       command_valid,
    output  logic [7:0] command_byte,

    output  logic       command_ack_ready,
    input   wire        command_ack_valid,
    input   wire        command_ack_error,

    output  reg         scan_code_ready,
    input   wire        scan_code_valid,
    input   wire [7:0]  scan_code_byte,

    input   wire        character_ready,
    output  logic       character_valid,
    output  logic [7:0] character_byte
);

    localparam  EXTENDED = YES;
    localparam  NORMAL = NO;
    localparam  NORMAL_OR_EXTENDED = 1'bx;

    localparam  SCROLL_LOCK = NO;

    localparam  SCAN_CODE_SELF_TEST     = 8'hAA;
    localparam  SCAN_CODE_ACKNOWLEDGE   = 8'hFA;
    localparam  SCAN_CODE_CAPS_LOCK     = 8'h58;
    localparam  SCAN_CODE_EXTENDED      = 8'hE0;
    localparam  SCAN_CODE_NUM_LOCK      = 8'h77;
    localparam  SCAN_CODE_RELEASED      = 8'hF0;

    localparam  COMMAND_SET_LEDS    = 8'hED;

    //==========================================
    // set LEDs?
    //==========================================

    reg         set_leds_request;
    logic       set_leds_request_made;
    logic       set_leds_request_taken;

    initial begin
        set_leds_request = NO;
    end

    always_ff @(posedge clk) begin
        if (set_leds_request_taken) begin
            set_leds_request <= NO;
        end

        if (set_leds_request_made) begin
            set_leds_request <= YES;
        end

        if (reset_low == LOW) begin
            set_leds_request <= NO;
        end
    end

    //==========================================
    // Acknowledge
    //==========================================

    reg         acknowledge;
    logic       acknowledge_made;
    logic       acknowledge_taken;

    initial begin
        acknowledge = NO;
    end

    always_ff @(posedge clk) begin
        if (acknowledge_taken) begin
            acknowledge <= NO;
        end

        if (acknowledge_made) begin
            acknowledge <= YES;
        end

        if (reset_low == LOW) begin
            acknowledge <= NO;
        end
    end

    //==========================================
    // incoming SCAN CODE
    //==========================================

    reg [7:0]   scan_code;
    reg         scan_code_extended;

    reg         extended;
    reg         released;

    reg         caps_lock;
    reg         num_lock;

    initial begin
        scan_code_ready = YES;
        scan_code = 0;
        scan_code_extended = NO;

        extended = NO;
        released = NO;

        caps_lock = NO;
        num_lock = YES;
    end

    always_comb begin
        // we have a CHARACTER if SCAN CODE is full
        // and NOT ready for another one
        character_valid = (scan_code_ready == NO);
        if (scan_code_extended == YES) begin
            character_byte = SCAN_CODE_EXTENDED;
        end else begin
            character_byte = scan_code;
        end

        acknowledge_made = NO;
        set_leds_request_made = NO;
        if (scan_code_valid == YES && scan_code_ready == YES) begin
            case ({scan_code_byte, extended})
                {SCAN_CODE_ACKNOWLEDGE, NORMAL}: begin
                    acknowledge_made = YES;
                end
                {SCAN_CODE_CAPS_LOCK, NORMAL},
                {SCAN_CODE_NUM_LOCK, NORMAL}: begin
                    if (released == NO) begin
                        set_leds_request_made = YES;
                    end
                end
                {SCAN_CODE_SELF_TEST, NORMAL}: begin
                    set_leds_request_made = YES;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        // incoming SCAN CODE
        if (scan_code_valid == YES && scan_code_ready == YES) begin
            extended <= NO;
            released <= NO;
            case ({scan_code_byte, extended})
                {SCAN_CODE_ACKNOWLEDGE, NORMAL}: begin
                    released <= NO;
                end
                {SCAN_CODE_CAPS_LOCK, NORMAL}: begin
                    if (released == NO) begin
                        caps_lock <= ~caps_lock;
                    end
                    released <= NO;
                end
                {SCAN_CODE_EXTENDED, NORMAL}: begin
                    extended <= YES;
                end
                {SCAN_CODE_NUM_LOCK, NORMAL}: begin
                    if (released == NO) begin
                        num_lock <= ~num_lock;
                    end
                    released <= NO;
                end
                {SCAN_CODE_RELEASED, NORMAL_OR_EXTENDED}: begin
                    extended <= extended;
                    released <= YES;
                end
                {SCAN_CODE_SELF_TEST, NORMAL}: begin
                    num_lock <= ~num_lock;
                end
                default: begin
                    if (released == NO) begin
                        scan_code_ready <= NO;
                        scan_code_extended <= extended;
                        scan_code <= scan_code_byte;
                    end
                end
            endcase
        end

        // outgoing CHARACERs
        if (character_valid == YES && character_ready == YES) begin
            if (scan_code_extended == YES) begin
                scan_code_extended <= NO;
            end else begin
                scan_code_ready <= YES;
                scan_code <= 0;
            end
        end

        if (reset_low == LOW) begin
            scan_code_ready <= YES;
            scan_code <= 0;
            scan_code_extended <= NO;

            extended <= NO;
            released <= NO;

            caps_lock <= NO;
            num_lock <= YES;
        end
    end

    //==========================================
    // command STATE
    //==========================================

    localparam  STATE_IDLE                      = 3'd0;
    localparam  STATE_SET_LEDS_0                = 3'd1;
    localparam  STATE_SET_LEDS_0_ACK            = 3'd2;
    localparam  STATE_SET_LEDS_0_ACKNOWLEDGE    = 3'd3;
    localparam  STATE_SET_LEDS_1                = 3'd4;
    localparam  STATE_SET_LEDS_1_ACK            = 3'd5;
    localparam  STATE_SET_LEDS_1_ACKNOWLEDGE    = 3'd6;

    reg [2:0]   state;
    logic       next_state;
    logic       next_state_idle;

    initial begin
        state = STATE_IDLE;
    end

    always_comb begin
        acknowledge_taken = NO;
        set_leds_request_taken = NO;

        command_valid = NO;
        command_byte = 0;

        command_ack_ready = NO;

        next_state = NO;
        next_state_idle = NO;
        case (state)
            STATE_IDLE: begin
                if (set_leds_request == YES) begin
                    set_leds_request_taken = YES;
                    next_state = YES;
                end
            end
            STATE_SET_LEDS_0: begin
                command_valid = YES;
                command_byte = COMMAND_SET_LEDS;
                if (command_ready == YES) begin
                    next_state = YES;
                end
            end
            STATE_SET_LEDS_0_ACK: begin
                command_ack_ready = YES;
                if (command_ack_valid == YES) begin
                    next_state = YES;
                end
            end
            STATE_SET_LEDS_0_ACKNOWLEDGE: begin
                if (acknowledge == YES) begin
                    acknowledge_taken = YES;
                    next_state = YES;
                end
            end
            STATE_SET_LEDS_1: begin
                command_valid = YES;
                command_byte = {5'b0, caps_lock, num_lock, SCROLL_LOCK};
                if (command_ready == YES) begin
                    next_state = YES;
                end
            end
            STATE_SET_LEDS_1_ACK: begin
                command_ack_ready = YES;
                if (command_ack_valid == YES) begin
                    next_state = YES;
                end
            end
            STATE_SET_LEDS_1_ACKNOWLEDGE: begin
                if (acknowledge == YES) begin
                    acknowledge_taken = YES;
                    next_state_idle = YES;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (next_state == YES) begin
            state <= state + 1;
        end

        if (next_state_idle == YES) begin
            state <= STATE_IDLE;
        end

        if (reset_low == LOW) begin
            state <= STATE_IDLE;
        end
    end

endmodule
