`default_nettype none
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

    `include "common.vh"

    localparam CYCLES_WIDTH = $clog2(CYCLES);

    wire synced;

    clock_synchronizer for_bit_in
    (
        .clk(clk),

        .bit_in(bit_in),
        .bit_out(synced)
    );

    wire pos_edge;
    wire any_edge;

    edge_detector on_synced
    (
        .clk(clk),
        .reset_low(reset_low),

        .level(synced),

        .pos_edge(pos_edge),
        .any_edge(any_edge)
    );

    reg [CYCLES_WIDTH-1:0] cycles;

    initial begin
        cycles = 0;
        bit_out = LOW;
    end

    always @(posedge clk) begin
        if (reset_low == LOW) begin
            cycles <= 0;
            bit_out <= LOW;
        end else if (cycles > 0) begin
            cycles <= cycles - 1;
        end else if (any_edge == YES) begin
            cycles <= CYCLES;
            bit_out <= pos_edge;
        end
    end

endmodule