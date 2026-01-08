`default_nettype none
`timescale 1ns / 1ps
module ps2_commands
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        command_ready,
    output  logic       command_valid,
    output  reg [7:0]   command_byte,

    output  logic       command_ack_ready,
    input   wire        command_ack_valid,
    input   wire        command_ack_error,

    input   wire        acknowledge,

    input   wire        resend,

    input   wire        set_status,
    input   wire        set_status_caps_lock,
    input   wire        set_status_num_lock,
    input   wire        set_status_scroll_lock
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

        .made(resend),
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

        .made(set_status),
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
    logic       command_acknowledge;

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
                if (command_acknowledge) begin
                    state <= STATE_IDLE;
                end
            end
            STATE_SET_STATUS: begin
                if (command_acknowledge) begin
                    state <= STATE_SET_STATUS_LEDS;
                end
            end
            STATE_SET_STATUS_LEDS: begin
                if (command_acknowledge) begin
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
    localparam  COMMAND_STATE_ACK           = 2'd2;
    localparam  COMMAND_STATE_ACKNOWLEDGE   = 2'd3;

    reg [1:0]   command_state;

    initial begin
        command_state = COMMAND_STATE_IDLE;
        command_valid = NO;
        command_byte = 8'h00;
    end

    always_comb begin
        command_valid = NO;
        command_ack_ready = NO;
        command_acknowledge = NO;

        case (command_state)
            COMMAND_STATE_IDLE: begin
            end
            COMMAND_STATE_SEND: begin
                command_valid = YES;
            end
            COMMAND_STATE_ACK: begin
                command_ack_ready = YES;
            end
            COMMAND_STATE_ACKNOWLEDGE: begin
                command_acknowledge = acknowledge;
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
                    command_byte <= COMMAND_SET_STATUS;
                end

                if (command_set_status_leds) begin
                    command_state <= COMMAND_STATE_SEND;
                    command_byte <= {5'b0, set_status_caps_lock, set_status_num_lock, set_status_scroll_lock};
                end
            end
            COMMAND_STATE_SEND: begin
                if (command_ready == YES) begin
                    command_state <= COMMAND_STATE_ACK;
                end
            end
            COMMAND_STATE_ACK: begin
                if (command_ack_valid == YES) begin
                    command_state <= COMMAND_STATE_ACKNOWLEDGE;
                end
            end
            COMMAND_STATE_ACKNOWLEDGE: begin
                if (acknowledge) begin
                    command_state <= COMMAND_STATE_IDLE;
                end
            end
        endcase

        if (reset_low == LOW) begin
            command_state <= COMMAND_STATE_IDLE;
            command_byte <= 8'h00;
        end
    end

endmodule
