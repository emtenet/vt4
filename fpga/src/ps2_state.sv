//  # PS/2 state machine

//  Keep track of keyboard state:

//   * caps-lock
//   * control
//   * num-lock
//   * shift

//  Decode special scan codes:

//   * scan code is ACK
//   * scan code is EXTENDED
//   * scan code is RESEND
//   * scan code is SPECIAL
//   * scan code is STATUS (xxx-lock)

`default_nettype none
`timescale 1ns / 1ps
module ps2_state
(
    input   wire        clk,
    input   wire        reset_low,

    // do not participate in ready/valid handshake
    // just observe
    input   wire        scan_code_ready,
    input   wire        scan_code_valid,
    input   wire [7:0]  scan_code_byte,

    output  reg         num_lock_is_on,
    output  logic       control_is_down,
    output  reg         caps_lock_is_on,
    output  reg         scroll_lock_is_on,
    output  logic       shift_is_down,

    output  logic       scan_code_is_ack,
    output  logic       scan_code_is_extended,
    output  logic       scan_code_is_resend,
    output  logic       scan_code_is_special,
    output  logic       scan_code_is_status,

    input   wire        switch_active_ready,
    output  reg         switch_active_valid,
    output  reg [1:0]   switch_active_to,
);

    localparam  EXTENDED = YES;
    localparam  NORMAL = NO;
    localparam  NORMAL_OR_EXTENDED = 1'bx;

    localparam  SCAN_CODE_ACK           = 8'hFA;
    localparam  SCAN_CODE_ALT           = 8'h11;
    localparam  SCAN_CODE_CAPS_LOCK     = 8'h58;
    localparam  SCAN_CODE_CONTROL       = 8'h14;
    localparam  SCAN_CODE_EXTENDED      = 8'hE0;
    localparam  SCAN_CODE_F1            = 8'h05;
    localparam  SCAN_CODE_F2            = 8'h06;
    localparam  SCAN_CODE_F3            = 8'h04;
    localparam  SCAN_CODE_F4            = 8'h0C;
    localparam  SCAN_CODE_LEFT_SHIFT    = 8'h12;
    localparam  SCAN_CODE_NUM_LOCK      = 8'h77;
    localparam  SCAN_CODE_RELEASED      = 8'hF0;
    localparam  SCAN_CODE_RESEND        = 8'hFE;
    localparam  SCAN_CODE_RIGHT_SHIFT   = 8'h59;
    localparam  SCAN_CODE_SELF_TEST     = 8'hAA;
    localparam  SCAN_CODE_SCROLL_LOCK   = 8'h7E;

    //==========================================
    // incoming SCAN CODE
    //==========================================

    reg         extended;
    reg         released;

    logic       alt_is_down;
    reg         left_alt_is_down;
    reg         right_alt_is_down;
    reg         left_shift_is_down;
    reg         right_shift_is_down;
    reg         left_control_is_down;
    reg         right_control_is_down;

    logic       set_extended;
    logic       set_released;
    logic       toggle_caps_lock;
    logic       toggle_num_lock;
    logic       toggle_scroll_lock;
    logic       set_left_alt_is_down;
    logic       set_right_alt_is_down;
    logic       set_left_shift_is_down;
    logic       set_right_shift_is_down;
    logic       set_left_control_is_down;
    logic       set_right_control_is_down;
    logic       set_switch_active;
    logic [1:0] set_switch_active_to;

    initial begin
        extended = NO;
        released = NO;

        caps_lock_is_on = NO;
        num_lock_is_on = NO;
        scroll_lock_is_on = NO;

        left_alt_is_down = NO;
        right_alt_is_down = NO;
        left_shift_is_down = NO;
        right_shift_is_down = NO;
        left_control_is_down = NO;
        right_control_is_down = NO;

        switch_active_valid = NO;
        switch_active_to = 2'h0;
    end

    always_comb begin
        scan_code_is_extended = extended;
        scan_code_is_special = NO;

        scan_code_is_ack = NO;
        scan_code_is_resend = NO;
        scan_code_is_status = NO;

        set_extended = NO;
        set_released = NO;

        toggle_caps_lock = NO;
        toggle_num_lock = NO;
        toggle_scroll_lock = NO;

        set_left_alt_is_down = NO;
        set_right_alt_is_down = NO;
        set_left_shift_is_down = NO;
        set_right_shift_is_down = NO;
        set_left_control_is_down = NO;
        set_right_control_is_down = NO;

        set_switch_active = NO;
        set_switch_active_to = 2'h0;

        alt_is_down = left_alt_is_down | right_alt_is_down;
        control_is_down = left_control_is_down | right_control_is_down;
        shift_is_down = left_shift_is_down | right_shift_is_down;

        if (scan_code_valid == YES && scan_code_ready == YES) begin
            case ({scan_code_byte, extended})
                {SCAN_CODE_ACK, NORMAL}: begin
                    scan_code_is_special = YES;
                    scan_code_is_ack = YES;
                end
                {SCAN_CODE_ALT, NORMAL}: begin
                    scan_code_is_special = YES;
                    set_left_alt_is_down = YES;
                end
                {SCAN_CODE_ALT, EXTENDED}: begin
                    scan_code_is_special = YES;
                    set_right_alt_is_down = YES;
                end
                {SCAN_CODE_CAPS_LOCK, NORMAL}: begin
                    scan_code_is_special = YES;
                    if (released == NO) begin
                        toggle_caps_lock = YES;
                        scan_code_is_status = YES;
                    end
                end
                {SCAN_CODE_CONTROL, NORMAL}: begin
                    scan_code_is_special = YES;
                    set_left_control_is_down = YES;
                end
                {SCAN_CODE_CONTROL, EXTENDED}: begin
                    scan_code_is_special = YES;
                    set_right_control_is_down = YES;
                end
                {SCAN_CODE_EXTENDED, NORMAL}: begin
                    scan_code_is_special = YES;
                    set_extended = YES;
                end
                {SCAN_CODE_F1, NORMAL}: begin
                    if (released == YES) begin
                        scan_code_is_special = YES;
                    end else begin
                        scan_code_is_special = alt_is_down;
                        set_switch_active = alt_is_down;
                        set_switch_active_to = 2'h0;
                    end
                end
                {SCAN_CODE_F2, NORMAL}: begin
                    if (released == YES) begin
                        scan_code_is_special = YES;
                    end else begin
                        scan_code_is_special = alt_is_down;
                        set_switch_active = alt_is_down;
                        set_switch_active_to = 2'h1;
                    end
                end
                {SCAN_CODE_F3, NORMAL}: begin
                    if (released == YES) begin
                        scan_code_is_special = YES;
                    end else begin
                        scan_code_is_special = alt_is_down;
                        set_switch_active = alt_is_down;
                        set_switch_active_to = 2'h2;
                    end
                end
                {SCAN_CODE_F4, NORMAL}: begin
                    if (released == YES) begin
                        scan_code_is_special = YES;
                    end else begin
                        scan_code_is_special = alt_is_down;
                        set_switch_active = alt_is_down;
                        set_switch_active_to = 2'h3;
                    end
                end
                {SCAN_CODE_LEFT_SHIFT, NORMAL}: begin
                    scan_code_is_special = YES;
                    set_left_shift_is_down = YES;
                end
                {SCAN_CODE_NUM_LOCK, NORMAL}: begin
                    scan_code_is_special = YES;
                    if (released == NO) begin
                        toggle_num_lock = YES;
                        scan_code_is_status = YES;
                    end
                end
                {SCAN_CODE_RELEASED, NORMAL_OR_EXTENDED}: begin
                    scan_code_is_special = YES;
                    set_released = YES;
                end
                {SCAN_CODE_RESEND, NORMAL}: begin
                    scan_code_is_special = YES;
                    scan_code_is_resend = YES;
                end
                {SCAN_CODE_RIGHT_SHIFT, NORMAL}: begin
                    scan_code_is_special = YES;
                    set_right_shift_is_down = YES;
                end
                {SCAN_CODE_SCROLL_LOCK, NORMAL}: begin
                    scan_code_is_special = YES;
                    if (released == NO) begin
                        toggle_scroll_lock = YES;
                        scan_code_is_status = YES;
                    end
                end
                {SCAN_CODE_SELF_TEST, NORMAL}: begin
                    scan_code_is_special = YES;
                    scan_code_is_status = YES;
                end
                default: begin
                    if (released == YES) begin
                        scan_code_is_special = YES;
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
                caps_lock_is_on <= ~caps_lock_is_on;
            end
            if (toggle_num_lock) begin
                num_lock_is_on <= ~num_lock_is_on;
            end
            if (toggle_scroll_lock) begin
                scroll_lock_is_on <= ~scroll_lock_is_on;
            end

            if (set_left_alt_is_down) begin
                left_alt_is_down <= ~released;
            end
            if (set_right_alt_is_down) begin
                right_alt_is_down <= ~released;
            end
            if (set_left_shift_is_down) begin
                left_shift_is_down <= ~released;
            end
            if (set_right_shift_is_down) begin
                right_shift_is_down <= ~released;
            end
            if (set_left_control_is_down) begin
                left_control_is_down <= ~released;
            end
            if (set_right_control_is_down) begin
                right_control_is_down <= ~released;
            end
        end

        if (switch_active_valid && switch_active_ready) begin
            switch_active_valid <= NO;
        end
        if (set_switch_active) begin
            switch_active_valid <= YES;
            switch_active_to <= set_switch_active_to;
        end

        if (reset_low == LOW) begin
            extended <= NO;
            released <= NO;

            caps_lock_is_on <= NO;
            num_lock_is_on <= NO;
            scroll_lock_is_on <= NO;

            left_alt_is_down <= NO;
            right_alt_is_down <= NO;
            left_shift_is_down <= NO;
            right_shift_is_down <= NO;
            left_control_is_down <= NO;
            right_control_is_down <= NO;

            switch_active_valid <= NO;
            switch_active_to <= 2'h0;
        end
    end

endmodule
