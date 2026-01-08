`default_nettype none
`timescale 1ns / 1ps
module ps2_state
(
    input   wire        clk,
    input   wire        reset_low,

    output  reg         scan_code_ready,
    input   wire        scan_code_valid,
    input   wire [7:0]  scan_code_byte,

    output  logic       acknowledge,

    output  logic       resend,

    output  logic       set_status,
    output  logic       set_status_caps_lock,
    output  logic       set_status_num_lock,
    output  logic       set_status_scroll_lock,

    input   wire        character_ready,
    output  logic       character_valid,
    output  logic [7:0] character_byte
);

    localparam  EXTENDED = YES;
    localparam  NORMAL = NO;
    localparam  NORMAL_OR_EXTENDED = 1'bx;

    localparam  SCAN_CODE_SELF_TEST     = 8'hAA;
    localparam  SCAN_CODE_ACKNOWLEDGE   = 8'hFA;
    localparam  SCAN_CODE_CAPS_LOCK     = 8'h58;
    localparam  SCAN_CODE_EXTENDED      = 8'hE0;
    localparam  SCAN_CODE_NUM_LOCK      = 8'h77;
    localparam  SCAN_CODE_RELEASED      = 8'hF0;
    localparam  SCAN_CODE_RESEND        = 8'hFE;
    localparam  SCAN_CODE_SCROLL_LOCK   = 8'h7E;

    //==========================================
    // incoming SCAN CODE
    //==========================================

    reg [7:0]   scan_code;
    reg         scan_code_extended;

    reg         extended;
    reg         released;

    reg         caps_lock;
    reg         num_lock;
    reg         scroll_lock;

    initial begin
        scan_code_ready = YES;
        scan_code = 0;
        scan_code_extended = NO;

        extended = NO;
        released = NO;

        caps_lock = NO;
        num_lock = NO;
        scroll_lock = NO;
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

        acknowledge = NO;
        resend = NO;
        set_status = NO;
        set_status_caps_lock = caps_lock;
        set_status_num_lock = num_lock;
        set_status_scroll_lock = scroll_lock;

        if (scan_code_valid == YES && scan_code_ready == YES) begin
            case ({scan_code_byte, extended})
                {SCAN_CODE_ACKNOWLEDGE, NORMAL}: begin
                    acknowledge = YES;
                end
                {SCAN_CODE_CAPS_LOCK, NORMAL},
                {SCAN_CODE_NUM_LOCK, NORMAL},
                {SCAN_CODE_SCROLL_LOCK, NORMAL}: begin
                    if (released == NO) begin
                        set_status = YES;
                    end
                end
                {SCAN_CODE_RESEND, NORMAL}: begin
                    resend = YES;
                end
                {SCAN_CODE_SELF_TEST, NORMAL}: begin
                    set_status = YES;
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
                {SCAN_CODE_SCROLL_LOCK, NORMAL}: begin
                    if (released == NO) begin
                        scroll_lock <= ~scroll_lock;
                    end
                    released <= NO;
                end
                {SCAN_CODE_RESEND, NORMAL}: begin

                end
                {SCAN_CODE_SELF_TEST, NORMAL}: begin

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
            num_lock <= NO;
            scroll_lock <= NO;
        end
    end

endmodule
