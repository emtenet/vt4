`default_nettype none
`timescale 1ns / 1ps
module ps2_state
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        scan_code_ready,
    input   wire        scan_code_valid,
    input   wire [7:0]  scan_code_byte,
    output  logic       scan_code_extended,
    output  logic       scan_code_special,

    output  reg         num_lock,
    output  logic       control,
    output  reg         caps_lock,
    output  logic       shift,

    output  logic       acknowledge,

    output  logic       resend,

    output  logic       set_status,
    output  logic       set_status_caps_lock,
    output  logic       set_status_num_lock,
    output  logic       set_status_scroll_lock
);

    localparam  EXTENDED = YES;
    localparam  NORMAL = NO;
    localparam  NORMAL_OR_EXTENDED = 1'bx;

    localparam  SCAN_CODE_SELF_TEST     = 8'hAA;
    localparam  SCAN_CODE_ACKNOWLEDGE   = 8'hFA;
    localparam  SCAN_CODE_CAPS_LOCK     = 8'h58;
    localparam  SCAN_CODE_CONTROL       = 8'h14;
    localparam  SCAN_CODE_EXTENDED      = 8'hE0;
    localparam  SCAN_CODE_LEFT_SHIFT    = 8'h12;
    localparam  SCAN_CODE_NUM_LOCK      = 8'h77;
    localparam  SCAN_CODE_RELEASED      = 8'hF0;
    localparam  SCAN_CODE_RESEND        = 8'hFE;
    localparam  SCAN_CODE_RIGHT_SHIFT   = 8'h59;
    localparam  SCAN_CODE_SCROLL_LOCK   = 8'h7E;

    //==========================================
    // incoming SCAN CODE
    //==========================================

    reg         extended;
    reg         released;

    reg         scroll_lock;
    reg         left_shift;
    reg         right_shift;
    reg         left_control;
    reg         right_control;

    logic       set_extended;
    logic       set_released;
    logic       toggle_caps_lock;
    logic       toggle_num_lock;
    logic       toggle_scroll_lock;
    logic       set_left_shift;
    logic       set_right_shift;
    logic       set_left_control;
    logic       set_right_control;

    initial begin
        extended = NO;
        released = NO;

        caps_lock = NO;
        num_lock = NO;
        scroll_lock = NO;

        left_shift = NO;
        right_shift = NO;
        left_control = NO;
        right_control = NO;
    end

    always_comb begin
        scan_code_extended = extended;
        scan_code_special = NO;

        acknowledge = NO;
        resend = NO;
        set_status = NO;
        set_status_caps_lock = caps_lock;
        set_status_num_lock = num_lock;
        set_status_scroll_lock = scroll_lock;

        set_extended = NO;
        set_released = NO;

        toggle_caps_lock = NO;
        toggle_num_lock = NO;
        toggle_scroll_lock = NO;

        set_left_shift = NO;
        set_right_shift = NO;
        set_left_control = NO;
        set_right_control = NO;

        control = left_control | right_control;
        shift = left_shift | right_shift;

        if (scan_code_valid == YES && scan_code_ready == YES) begin
            case ({scan_code_byte, extended})
                {SCAN_CODE_ACKNOWLEDGE, NORMAL}: begin
                    scan_code_special = YES;
                    acknowledge = YES;
                end
                {SCAN_CODE_CAPS_LOCK, NORMAL}: begin
                    scan_code_special = YES;
                    if (released == NO) begin
                        toggle_caps_lock = YES;
                        set_status = YES;
                    end
                end
                {SCAN_CODE_CONTROL, NORMAL}: begin
                    scan_code_special = YES;
                    set_left_control = YES;
                    set_status = YES;
                end
                {SCAN_CODE_CONTROL, EXTENDED}: begin
                    scan_code_special = YES;
                    set_right_control = YES;
                    set_status = YES;
                end
                {SCAN_CODE_LEFT_SHIFT, NORMAL}: begin
                    scan_code_special = YES;
                    set_left_shift = YES;
                    set_status = YES;
                end
                {SCAN_CODE_NUM_LOCK, NORMAL}: begin
                    scan_code_special = YES;
                    if (released == NO) begin
                        toggle_num_lock = YES;
                        set_status = YES;
                    end
                end
                {SCAN_CODE_RIGHT_SHIFT, NORMAL}: begin
                    scan_code_special = YES;
                    set_right_shift = YES;
                    set_status = YES;
                end
                {SCAN_CODE_SCROLL_LOCK, NORMAL}: begin
                    scan_code_special = YES;
                    if (released == NO) begin
                        toggle_scroll_lock = YES;
                        set_status = YES;
                    end
                end
                {SCAN_CODE_EXTENDED, NORMAL}: begin
                    scan_code_special = YES;
                    set_extended = YES;
                end
                {SCAN_CODE_RELEASED, NORMAL_OR_EXTENDED}: begin
                    scan_code_special = YES;
                    set_released = YES;
                end
                {SCAN_CODE_RESEND, NORMAL}: begin
                    scan_code_special = YES;
                    resend = YES;
                end
                {SCAN_CODE_SELF_TEST, NORMAL}: begin
                    scan_code_special = YES;
                    set_status = YES;
                end
                default: begin
                    if (released == YES) begin
                        scan_code_special = YES;
                    end
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (scan_code_valid == YES && scan_code_ready == YES) begin
            extended <= NO;
            released <= NO;

            if (set_extended) begin
                extended <= YES;
            end
            if (set_released) begin
                extended <= extended;
                released <= YES;
            end

            if (toggle_caps_lock) begin
                caps_lock <= ~caps_lock;
            end
            if (toggle_num_lock) begin
                num_lock <= ~num_lock;
            end
            if (toggle_scroll_lock) begin
                scroll_lock <= ~scroll_lock;
            end

            if (set_left_shift) begin
                left_shift <= ~released;
            end
            if (set_right_shift) begin
                right_shift <= ~released;
            end
            if (set_left_control) begin
                left_control <= ~released;
            end
            if (set_right_control) begin
                right_control <= ~released;
            end
        end

        if (reset_low == LOW) begin
            extended <= NO;
            released <= NO;

            caps_lock <= NO;
            num_lock <= NO;
            scroll_lock <= NO;

            left_shift <= NO;
            right_shift <= NO;
            left_control <= NO;
            right_control <= NO;
        end
    end

endmodule
