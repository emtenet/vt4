`default_nettype none
`timescale 1ns / 1ps
module debouncer
#(
    parameter CYCLES = 0
)
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        bit_in,
    output  reg         bit_out
);

    localparam CYCLES_WIDTH = (CYCLES == 0) ? 0 : $clog2(CYCLES);
    localparam CYCLES_ZERO = {CYCLES_WIDTH{1'b0}};

    wire synced;

    clock_synchronizer for_bit_in
    (
        .clk(clk),

        .bit_in(bit_in),
        .bit_out(synced)
    );

    wire pos_edge;
    wire any_edge;

    /* verilator lint_off PINMISSING */
    edge_detector on_synced
    (
        .clk(clk),
        .reset_low(reset_low),

        .level(synced),

        .pos_edge(pos_edge),
        .any_edge(any_edge)
    );
    /* verilator lint_on PINMISSING */

    reg [CYCLES_WIDTH-1:0] cycles;

    initial begin
        cycles = CYCLES_ZERO;
        bit_out = LOW;
    end

    always @(posedge clk) begin
        if (reset_low == LOW) begin
            cycles <= CYCLES_ZERO;
            bit_out <= LOW;
        end else if (cycles > CYCLES_ZERO) begin
            cycles <= cycles - 1;
        end else if (any_edge == YES) begin
            cycles <= CYCLES;
            bit_out <= pos_edge;
        end
    end

endmodule
