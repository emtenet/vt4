`default_nettype none
module button_handshake
(
    input   wire        clk,
    input   wire        reset_low,

    input   wire        button,

    input   wire        ready,
    output  reg 		valid
);

    wire debounced;

    debouncer
    #(
        .CYCLES(255)
    )
    for_button
    (
        .clk(clk),
        .reset_low(reset_low),

        .bit_in(button),
        .bit_out(debounced)
    );

    wire neg_edge;

    edge_detector on_debounced
    (
        .clk(clk),
        .reset_low(reset_low),

        .level(debounced),

        .neg_edge(neg_edge)
    );

    initial begin
        valid = NO;
    end

    always @(posedge clk) begin
        // handshake complete
        if (ready == YES) begin
            valid <= NO;
        end

        // button pressed
        if (neg_edge == YES) begin
            valid <= YES;
        end
    end

endmodule