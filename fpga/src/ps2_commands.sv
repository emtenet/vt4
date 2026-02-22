//  # PS/2 commands

//  Translate high level PS/2 commands to individual
//  command codes and their acknowledgements.

`default_nettype none
`timescale 1ns / 1ps
module ps2_commands
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        scan_code_is_ack,
    input   wire        scan_code_is_resend,
    input   wire        scan_code_is_status,

    input   wire        caps_lock_is_on,
    input   wire        num_lock_is_on,
    input   wire        scroll_lock_is_on,

    input   wire        command_code_ready,
    output  logic       command_code_valid,
    output  reg [7:0]   command_code_byte,

    output  logic       command_code_ack_ready,
    input   wire        command_code_ack_valid,
    input   wire        command_code_ack_error,
);

    //==========================================
    // RESEND request
    //==========================================

    wire        resend_request;
    logic       resend_taken;

    request_latch for_resend
    (
        .clk(clk),
        .reset_low(reset_low),

        .made(scan_code_is_resend),
        .request(resend_request),
        .taken(resend_taken)
    );

    //==========================================
    // SET STATUS request
    //==========================================

    wire        set_status_request;
    logic       set_status_taken;

    request_latch for_set_status
    (
        .clk(clk),
        .reset_low(reset_low),

        .made(scan_code_is_status),
        .request(set_status_request),
        .taken(set_status_taken)
    );

    //==========================================
    // state machine
    //==========================================

    // internal requests
    logic       command_resend;
    logic       command_set_status;
    logic       command_set_status_leds;
    // internal acknowledge
    logic       command_acknowledged;

    localparam  STATE_IDLE                  = 2'd0;
    localparam  STATE_RESEND                = 2'd1;
    localparam  STATE_SET_STATUS            = 2'd2;
    localparam  STATE_SET_STATUS_LEDS       = 2'd3;

    reg [1:0]   state;

    initial begin
        state = STATE_IDLE;
    end

    always_comb begin
        resend_taken = NO;
        set_status_taken = NO;

        command_resend = NO;
        command_set_status = NO;
        command_set_status_leds = NO;

        case (state)
            STATE_IDLE: begin
                if (resend_request) begin
                    resend_taken = YES;
                end else if (set_status_request) begin
                    set_status_taken = YES;
                end
            end
            STATE_RESEND: begin
                command_resend = YES;
            end
            STATE_SET_STATUS: begin
                command_set_status = YES;
            end
            STATE_SET_STATUS_LEDS: begin
                command_set_status_leds = YES;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                if (resend_request) begin
                    state <= STATE_RESEND;
                end else if (set_status_request) begin
                    state <= STATE_SET_STATUS;
                end
            end
            STATE_RESEND: begin
                if (command_acknowledged) begin
                    state <= STATE_IDLE;
                end
            end
            STATE_SET_STATUS: begin
                if (command_acknowledged) begin
                    state <= STATE_SET_STATUS_LEDS;
                end
            end
            STATE_SET_STATUS_LEDS: begin
                if (command_acknowledged) begin
                    state <= STATE_IDLE;
                end
            end
        endcase

        if (reset_low == LOW) begin
            state <= STATE_IDLE;
        end
    end

    //==========================================
    // single COMMAND byte
    //==========================================

    localparam  COMMAND_SET_STATUS  = 8'hED;

    localparam  COMMAND_STATE_IDLE          = 2'd0;
    localparam  COMMAND_STATE_SEND          = 2'd1;
    localparam  COMMAND_STATE_RECEIVED      = 2'd2;
    localparam  COMMAND_STATE_ACKNOWLEDGE   = 2'd3;

    reg [1:0]   command_state;

    initial begin
        command_state = COMMAND_STATE_IDLE;
        command_code_valid = NO;
        command_code_byte = 8'h00;
    end

    always_comb begin
        command_code_valid = NO;
        command_code_ack_ready = NO;
        command_acknowledged = NO;

        case (command_state)
            COMMAND_STATE_IDLE: begin
            end
            COMMAND_STATE_SEND: begin
                command_code_valid = YES;
            end
            COMMAND_STATE_RECEIVED: begin
                command_code_ack_ready = YES;
            end
            COMMAND_STATE_ACKNOWLEDGE: begin
                command_acknowledged = scan_code_is_ack;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case (command_state)
            COMMAND_STATE_IDLE: begin
                if (command_resend) begin
                    command_state <= COMMAND_STATE_SEND;
                end

                if (command_set_status) begin
                    command_state <= COMMAND_STATE_SEND;
                    command_code_byte <= COMMAND_SET_STATUS;
                end

                if (command_set_status_leds) begin
                    command_state <= COMMAND_STATE_SEND;
                    command_code_byte <= {
                        5'b0,
                        caps_lock_is_on,
                        num_lock_is_on,
                        scroll_lock_is_on
                    };
                end
            end
            COMMAND_STATE_SEND: begin
                if (command_code_ready == YES) begin
                    command_state <= COMMAND_STATE_RECEIVED;
                end
            end
            COMMAND_STATE_RECEIVED: begin
                if (command_code_ack_valid == YES) begin
                    command_state <= COMMAND_STATE_ACKNOWLEDGE;
                end
            end
            COMMAND_STATE_ACKNOWLEDGE: begin
                if (scan_code_is_ack) begin
                    command_state <= COMMAND_STATE_IDLE;
                end
            end
        endcase

        if (reset_low == LOW) begin
            command_state <= COMMAND_STATE_IDLE;
            command_code_byte <= 8'h00;
        end
    end

endmodule
