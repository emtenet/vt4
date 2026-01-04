`default_nettype none
module ps2
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        ps2_clk_in,
    output  wire        ps2_clk_out,
    output  wire        ps2_clk_oe,
    input   wire        ps2_data_in,
    output  wire        ps2_data_out,
    output  wire        ps2_data_oe,

    output  reg         error,

    output  wire        command_ready,
    input   wire        command_valid,
    input   wire [7:0]  command_byte,

    input   wire        command_ack_ready,
    output  reg         command_ack_valid,
    output  reg         command_ack_error,

    input   wire        scan_code_ready,
    output  reg         scan_code_valid,
    output  wire [7:0]  scan_code_byte
);

    `include "common.vh"

    localparam ACK_BIT      = LOW;
    localparam START_BIT    = LOW;
    localparam STOP_BIT     = HIGH;

    localparam ODD_PARITY   = HIGH;

    //==========================================
    // Sanitize PS/2 clk & data lines
    //==========================================

    wire        ps2_clk;
    wire        ps2_data;
    wire        ps2_clk_rising;
    wire        ps2_clk_falling;

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

    /* verilator lint_off PINMISSING */
    edge_detector on_ps2_clk
    (
        .clk(clk),
        .reset_low(reset_low),

        .level(ps2_clk),

        .pos_edge(ps2_clk_rising),
        .neg_edge(ps2_clk_falling)
    );
    /* verilator lint_on PINMISSING */

    //==========================================
    // State Machine
    //==========================================

    localparam STATE_IDLE   = 2'b00;
    localparam STATE_RX     = 2'b01;
    localparam STATE_TX     = 2'b10;
    reg [1:0]   state;

    localparam FRAME_BIT_0  = 4'd0;
    localparam FRAME_BIT_1  = 4'd1;
    localparam FRAME_BIT_2  = 4'd2;
    localparam FRAME_BIT_3  = 4'd3;
    localparam FRAME_BIT_4  = 4'd4;
    localparam FRAME_BIT_5  = 4'd5;
    localparam FRAME_BIT_6  = 4'd6;
    localparam FRAME_BIT_7  = 4'd7;
    localparam FRAME_PARITY = 4'd8;
    localparam FRAME_STOP   = 4'd9;
    localparam FRAME_ACK    = 4'd10;
    localparam FRAME_REQUEST= 4'd14;
    localparam FRAME_START  = 4'd15;
    reg [3:0]   frame;
    reg         parity;
    reg [9:0]   command;
    reg [7:0]   scan_code;

    // slowest frame @ 10kHz = 1100us
    // is 56,980 cycles at 51.8MHz
    // round up to 65,535 (16 bit counter)
    reg [15:0] watchdog;
    localparam WATCHDOG_START   = 16'b0;
    localparam WATCHDOG_STOP    = 16'b1111_1111_1111_1111;

    // request timer at least 100us
    // is 5,180 cycles at 51.8MHz
    // round up to 8191 (13 bit counter)
    reg [12:0] request;
    localparam REQUEST_START    = 13'b0;
    localparam REQUEST_STOP     = 13'b1_1111_1111_1111;

    wire scan_code_success;
    assign scan_code_success = (parity == ODD_PARITY)
                            && (ps2_data == STOP_BIT); // STOP bit

    wire command_parity;
    assign command_parity = ~(^ command_byte);

    wire command_success;
    assign command_success = (ps2_data == ACK_BIT);

    initial begin
        state = STATE_IDLE;
        frame = FRAME_BIT_0;
        parity = LOW;
        command = 10'b0;
        command_ack_valid = NO;
        command_ack_error = NO;
        scan_code_valid = NO;
        scan_code = 8'b0;
        error = NO;
        watchdog = WATCHDOG_START;
        request = REQUEST_START;
    end

    always @(posedge clk) begin
        if (scan_code_valid == YES && scan_code_ready == YES) begin
            scan_code_valid <= NO;
            scan_code <= 8'b0;
        end

        if (command_ack_valid == YES && command_ack_ready == YES) begin
            command_ack_valid <= NO;
            command_ack_error <= NO;
        end

        case (state)
            STATE_IDLE: begin
                if (command_valid == YES) begin
                    state <= STATE_TX;
                    frame <= FRAME_REQUEST;
                    watchdog <= WATCHDOG_START;
                    request <= REQUEST_START;
                    command <= {command_parity, command_byte, START_BIT};
                    command_ack_valid <= NO;
                    command_ack_error <= NO;
                end else if (ps2_clk_falling == YES) begin
                    // START bit?
                    if (ps2_data == START_BIT) begin
                        state <= STATE_RX;
                        frame <= FRAME_BIT_0;
                        watchdog <= WATCHDOG_START;
                        parity <= LOW;
                        scan_code_valid <= NO;
                    end
                end
            end
            STATE_RX: begin
                watchdog <= watchdog + 1;

                if (ps2_clk_falling == YES) begin
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
                            scan_code_valid <= scan_code_success;
                            error <= ~scan_code_success;
                        end
                    endcase
                end

                if (ps2_clk_rising == YES) begin
                    if (frame == FRAME_ACK) begin
                        state <= STATE_IDLE;
                        frame <= FRAME_BIT_0;
                    end
                end

                if (watchdog == WATCHDOG_STOP) begin
                    state <= STATE_IDLE;
                    error <= YES;
                end
            end
            STATE_TX: begin
                watchdog <= watchdog + 1;

                if (frame == FRAME_REQUEST) begin
                    request <= request + 1;
                    if (request == REQUEST_STOP) begin
                        frame <= frame + 1;
                    end
                end else if (frame == FRAME_ACK) begin
                    if (ps2_clk_rising == YES) begin
                        state <= STATE_IDLE;
                        frame <= FRAME_BIT_0;
                        command_ack_valid <= YES;
                    end
                end else begin
                    if (ps2_clk_falling == YES) begin
                        if (frame == FRAME_START) begin
                            watchdog <= WATCHDOG_START;
                        end

                        frame <= frame + 1;
                        command <= {STOP_BIT, command[9:1]};

                        if (frame == FRAME_STOP) begin
                            command_ack_error <= ~command_success;
                        end
                    end
                end

                if (watchdog == WATCHDOG_STOP) begin
                    state <= STATE_IDLE;
                    command_ack_valid <= YES;
                    command_ack_error <= YES;
                end
            end
            default: begin

            end
        endcase

        if (reset_low == LOW) begin
            state <= STATE_IDLE;
            frame <= FRAME_BIT_0;
            parity <= LOW;
            command <= 10'b0;
            scan_code_valid <= NO;
            scan_code <= 8'b0;
            error <= NO;
            watchdog <= WATCHDOG_START;
            request <= REQUEST_START;
        end
    end

    assign command_ready = (state == STATE_IDLE) && (reset_low == HIGH);
    assign scan_code_byte = scan_code;

    assign ps2_clk_oe = (state == STATE_TX)
                       ? (frame == FRAME_REQUEST)
                       : NO;
    assign ps2_clk_out = LOW;

    assign ps2_data_oe = (state == STATE_TX)
                       ? (frame >= FRAME_REQUEST || frame <= FRAME_PARITY)
                       : NO;
    assign ps2_data_out = command[0];

endmodule
