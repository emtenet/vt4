module character_writer
(
    input   wire        clk,
    input   wire        reset_low,

    // character input
    output  wire        character_ready,
    input   wire        character_valid,
    input   wire [7:0]  character_byte,

    // write output
    input   wire        write_ready,
    output  reg         write_valid,
    output  reg [4:0]   write_row,
    output  reg [6:0]   write_col,
    output  wire [7:0]  write_byte
);

    initial begin
        write_row = 5'b0;
        write_col = 7'b0;
    end

    always @(posedge clk) begin
        if (reset_low == LOW) begin
            write_row <= 5'b0;
            write_col <= 7'b0;
        end else if (write_valid == YES) begin
            if (write_ready == YES) begin
                write_col <= write_col + 1;
                if (write_col == 7'd99) begin
                    write_row <= write_row + 1;
                    write_col <= 7'b0;
                end
            end
        end
    end

    assign write_valid = character_valid;
    assign write_byte = character_byte;
    assign character_ready = write_ready;

endmodule