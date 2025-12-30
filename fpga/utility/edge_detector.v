`default_nettype none
module edge_detector
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        level,

    output  wire        pos_edge,
    output  wire        neg_edge,
    output  wire        any_edge
);

    `include "common.vh"

    reg previous = LOW;

    always @(posedge clk) begin
        if (reset_low == LOW) begin
            previous = LOW;
        end else begin
            previous <= level;
        end
    end

    always @(*) begin
        pos_edge = (level == HIGH) && (previous == LOW);
        neg_edge = (level == LOW) && (previous == HIGH);
        any_edge = pos_edge | neg_edge;
    end

endmodule