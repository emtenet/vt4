`default_nettype none
`timescale 1ns / 1ps
module ps2_key_codes
(
    input   wire        clk,
    input   wire        reset_low,

    output  logic       scan_code_ready,
    input   wire        scan_code_valid,
    input   wire [7:0]  scan_code_byte,
    input   wire        scan_code_extended,
    input   wire        scan_code_special,

    input   wire        num_lock,
    input   wire        control,
    input   wire        caps_lock,
    input   wire        shift,

    input   wire        character_ready,
    output  logic       character_valid,
    output  logic [7:0] character_byte
);

    localparam  CHARACTER_ESCAPE    = 8'd27;

    localparam  STATE_IDLE          = 3'd0;
    localparam  STATE_LOOKUP        = 3'd1;
    localparam  STATE_KEY_CODE_1    = 3'd2;
    localparam  STATE_KEY_CODE_2    = 3'd3;
    localparam  STATE_KEY_CODE_3    = 3'd4;
    localparam  STATE_KEY_CODE_4    = 3'd5;
    localparam  STATE_KEY_CODE_5    = 3'd6;

    localparam  KEY_CODE_NOTHING    = 8'h00;

    logic       scan_code_lookup;

    reg [2:0]   state;
    logic       state_increment;
    logic       state_reset;

    reg [7:0]   key_code;
    wire [7:0]  key_code_q;
    logic       key_code_store;
    logic       key_code_escape;
    logic       key_code_number;
    logic [1:0] key_code_tens;
    logic [3:0] key_code_ones;
    logic       key_code_bracket;
    logic [4:0] key_code_letter;

    initial begin
        state = STATE_IDLE;
        key_code = KEY_CODE_NOTHING;
    end

    always_comb begin
        scan_code_ready = NO;
        scan_code_lookup = NO;

        state_increment = NO;
        state_reset = NO;

        character_valid = NO;
        character_byte = 8'h00;

        key_code_store = NO;
        key_code_escape = key_code[KEY_CODE_ESCAPE];
        key_code_number = key_code[KEY_CODE_NUMBER];
        key_code_tens = key_code[KEY_CODE_TENS_HI:KEY_CODE_TENS_LO];
        key_code_ones = key_code[KEY_CODE_ONES_HI:KEY_CODE_ONES_LO];
        key_code_bracket = key_code[KEY_CODE_BRACKET];
        key_code_letter = key_code[KEY_CODE_LETTER_HI:KEY_CODE_LETTER_LO];

        case (state)
            STATE_IDLE: begin
                scan_code_ready = YES;
                if (scan_code_valid && !scan_code_special) begin
                    scan_code_lookup = YES;
                    state_increment = YES;
                end
            end
            STATE_LOOKUP: begin
                key_code_store = YES;
                if (key_code_q == KEY_CODE_NOTHING) begin
                    state_reset = YES;
                end else begin
                    state_increment = YES;
                end
            end
            STATE_KEY_CODE_1: begin
                if (key_code_escape == YES) begin
                    character_valid = YES;
                    character_byte = CHARACTER_ESCAPE;
                    if (character_ready == YES) begin
                        state_increment = YES;
                    end
                end else begin
                    character_valid = YES;
                    character_byte = key_code;
                    if (character_ready == YES) begin
                        state_reset = YES;
                    end
                end
            end
            STATE_KEY_CODE_2: begin
                character_valid = YES;
                if (key_code_number || key_code_bracket) begin
                    character_byte = "[";
                end else begin
                    character_byte = "O";
                end
                if (character_ready == YES) begin
                    state_increment = YES;
                end
            end
            STATE_KEY_CODE_3: begin
                if (key_code_number) begin
                    if (key_code_tens == 0) begin
                        state_increment = YES;
                    end else begin
                        character_valid = YES;
                        character_byte = "0" | key_code_tens;
                        if (character_ready == YES) begin
                            state_increment = YES;
                        end
                    end
                end else begin
                    character_valid = YES;
                    character_byte = "@" | key_code_letter;
                    if (character_ready == YES) begin
                        state_reset = YES;
                    end
                end
            end
            STATE_KEY_CODE_4: begin
                character_valid = YES;
                character_byte = "0" | key_code_ones;
                if (character_ready == YES) begin
                    state_increment = YES;
                end
            end
            STATE_KEY_CODE_5: begin
                character_valid = YES;
                character_byte = "~";
                if (character_ready == YES) begin
                    state_reset = YES;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (key_code_store) begin
            key_code <= key_code_q;
        end

        if (state_increment) begin
            state <= state + 1;
        end

        if (state_reset) begin
            state <= STATE_IDLE;
            key_code <= KEY_CODE_NOTHING;
        end

        if (reset_low == LOW) begin
            state <= STATE_IDLE;
            key_code <= KEY_CODE_NOTHING;
        end
    end

    key_code lookup
    (
        .clk(clk),

        .ce(scan_code_lookup),

        .extended(scan_code_extended),
        .scan_code(scan_code_byte),
        .num_lock(num_lock),
        .control(control),
        .caps_lock(caps_lock),
        .shift(shift),

        .q(key_code_q)
    );

endmodule