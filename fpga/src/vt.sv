`default_nettype none
`timescale 1ns / 1ps
module vt
(
    input   wire        clk,
    input   wire        reset_low,

    output  logic       host_ready,
    input   wire        host_valid,
    input   wire [7:0]  host_byte,

    input   wire        vram_ready,
    output  logic       vram_valid,
    output  logic [4:0] vram_row,
    output  logic [6:0] vram_col,
    output  logic [7:0] vram_byte,

    output  reg [4:0]   top_row,

    output  reg [4:0]   cursor_row,
    output  reg [6:0]   cursor_col
);

    localparam  LEFT_COL            = 7'd0;
    localparam  RIGHT_COL           = 7'd99;

    localparam  INITIAL_TOP_ROW     = 5'd0;
    localparam  INITIAL_BOTTOM_ROW  = 5'd29;
    localparam  INITIAL_CURSOR_ROW  = 5'd1;
    localparam  INITIAL_CURSOR_COL  = 7'd0;

    localparam  CONTROL_BS          = 8'd8;
    localparam  CONTROL_CR          = 8'd13;
    localparam  CONTROL_ESC         = 8'd27;
    localparam  CONTROL_LF          = 8'd10;

    localparam  STATE_IDLE          = 2'd0;
    localparam  STATE_DISPLAY       = 2'd1;
    localparam  STATE_SCROLL        = 2'd2;

    reg [4:0]   bottom_row;
    reg [7:0]   bottom_col;
    reg [1:0]   state;
    reg [7:0]   display_byte;

    logic       display;
    logic       cursor_down;
    logic       cursor_home;
    logic       cursor_left;
    logic       cursor_right;
    logic       scroll_down;
    logic       scroll_right;
    logic       state_idle;

    initial begin
        top_row = INITIAL_TOP_ROW;
        bottom_row = INITIAL_BOTTOM_ROW;
        bottom_col = LEFT_COL;

        cursor_row = INITIAL_CURSOR_ROW;
        cursor_col = INITIAL_CURSOR_COL;

        state = STATE_IDLE;
    end

    always_comb begin
        host_ready = NO;

        vram_valid = NO;
        vram_row = cursor_row;
        vram_col = cursor_col;
        vram_byte = display_byte;

        display = NO;
        cursor_down = NO;
        cursor_home = NO;
        cursor_left = NO;
        cursor_right = NO;
        scroll_down = NO;
        scroll_right = NO;
        state_idle = NO;

        case (state)
            STATE_IDLE: begin
                host_ready = YES;

                if (host_valid) begin
                    case (host_byte)
                        CONTROL_BS: begin
                            if (cursor_col != LEFT_COL) begin
                                cursor_left = YES;
                            end
                        end
                        CONTROL_CR: begin
                            cursor_home = YES;
                        end
                        CONTROL_LF: begin
                            cursor_down = YES;
                            if (cursor_row == bottom_row) begin
                                scroll_down = YES;
                            end
                        end
                        default: begin
                            display = YES;
                        end
                    endcase
                end
            end
            STATE_DISPLAY: begin
                vram_valid = YES;
                if (vram_ready) begin
                    if (vram_col == RIGHT_COL) begin
                        cursor_home = YES;
                        cursor_down = YES;
                        if (cursor_row == bottom_row) begin
                            scroll_down = YES;
                        end
                    end else begin
                        cursor_right = YES;
                    end
                    state_idle = YES;
                end
            end
            STATE_SCROLL: begin
                vram_valid = YES;
                vram_row = bottom_row;
                vram_col = bottom_col;
                vram_byte = " ";
                if (vram_ready) begin
                    if (bottom_col == RIGHT_COL) begin
                        state_idle = YES;
                    end else begin
                        scroll_right = YES;
                    end
                end
            end
            default: begin

            end
        endcase
    end

    always @(posedge clk) begin
        if (display) begin
            state <= STATE_DISPLAY;
            display_byte <= host_byte;
        end
        if (cursor_down) begin
            cursor_row <= cursor_row + 1;
        end
        if (cursor_home) begin
            cursor_col <= LEFT_COL;
        end
        if (cursor_left) begin
            cursor_col <= cursor_col - 1;
        end
        if (cursor_right) begin
            cursor_col <= cursor_col + 1;
        end
        if (scroll_down) begin
            state <= STATE_SCROLL;
            top_row <= top_row + 1;
            bottom_row <= bottom_row + 1;
            bottom_col <= LEFT_COL;
        end
        if (scroll_right) begin
            bottom_col <= bottom_col + 1;
        end
        if (state_idle) begin
            state <= STATE_IDLE;
        end

        if (reset_low == LOW) begin
            top_row <= INITIAL_TOP_ROW;
            bottom_row <= INITIAL_BOTTOM_ROW;
            bottom_col <= LEFT_COL;

            cursor_row <= INITIAL_CURSOR_ROW;
            cursor_col <= INITIAL_CURSOR_COL;

            state <= STATE_IDLE;
        end
    end

endmodule
