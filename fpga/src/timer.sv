`default_nettype none
`timescale 1ns / 1ps
module timer
#(
    parameter CLK_HZ = 0,
    parameter TIMER_HZ = 0
)
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        clear,
    input   wire        enabled,

    output  logic       finished
);

    localparam CYCLES = CLK_HZ / TIMER_HZ;
    localparam CYCLES_WIDTH = (CYCLES == 0) ? 0 : $clog2(CYCLES);
    localparam CYCLES_START = {CYCLES_WIDTH{1'b0}};
    localparam CYCLES_STOP  = {CYCLES_WIDTH{1'b1}};

    reg [CYCLES_WIDTH-1:0] cycles;

    initial begin
        cycles = CYCLES_START;
    end

    always_comb begin
        finished = (cycles == CYCLES_STOP);
    end

    always_ff @(posedge clk) begin
        if (reset_low == LOW) begin
            cycles <= CYCLES_START;
        end else if (clear == YES) begin
            cycles <= CYCLES_START;
        end else if (enabled == YES) begin
            cycles <= cycles + 1;
        end
    end

endmodule