`default_nettype none
module hdmi_timings
(
    input wire      clk,
    input wire      reset_n,

    output reg      active,
    output reg      h_sync,
    output reg      v_sync,

    output reg      h_start,
    output reg      v_start
);

    `include "common.vh"

    localparam  H_ACTIVE    = 1024;
    localparam  H_FRONT     = 48;
    localparam  H_SYNC      = 32;
    localparam  H_BACK      = 266;

    localparam  V_ACTIVE    = 600;
    localparam  V_FRONT     = 3;
    localparam  V_SYNC      = 6;
    localparam  V_BACK      = 21;

    localparam  H_TOTAL     = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
    localparam  V_TOTAL     = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    localparam  H_BITS      = $clog2(H_TOTAL);
    localparam  V_BITS      = $clog2(V_TOTAL);

    reg [H_BITS-1:0] h_index;
    reg [V_BITS-1:0] v_index;

    always @(posedge clk) begin
        if (reset_n == LOW) begin
            active <= NO;
            h_sync <= NO;
            v_sync <= NO;

            h_start <= NO;
            v_start <= NO;

            h_index <= NO;
            v_index <= NO;
        end else begin
            active <= YES;
            h_sync <= NO;
            v_sync <= NO;

            if (h_index < H_ACTIVE) begin
                // active
            end else if (h_index < H_ACTIVE + H_FRONT) begin
                active <= NO;
            end else if (h_index < H_ACTIVE + H_FRONT + H_SYNC) begin
                active <= NO;
                h_sync <= YES;
            end else begin
                active <= NO;
            end

            if (v_index < V_ACTIVE) begin
                // active
            end else if (v_index < V_ACTIVE + V_FRONT) begin
                active <= NO;
            end else if (v_index < V_ACTIVE + V_FRONT + V_SYNC) begin
                active <= NO;
                v_sync <= YES;
            end else begin
                active <= NO;
            end

            h_start <= NO;
            v_start <= NO;

            if (v_index < V_ACTIVE) begin
                if (h_index == 0) begin
                    h_start <= YES;
                    if (v_index == 0) begin
                        v_start <= YES;
                    end
                end
            end

            if (h_index == H_TOTAL-1) begin
                h_index <= 0;
                if (v_index == V_TOTAL-1) begin
                    v_index <= 0;
                end else begin
                    v_index <= v_index + 1;
                end
            end else begin
                h_index <= h_index + 1;
            end
        end
    end

endmodule