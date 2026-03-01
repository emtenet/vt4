`default_nettype none
`timescale 1ns / 1ps
module top
(
    input wire          xtal,

    inout wire          ps2_clk,
    inout wire          ps2_data,

    input wire [3:0]    uart_rx,
    output wire [3:0]   uart_tx,

    input wire [1:0]    button,
    output wire [5:0]   led,
    output wire [3:0]   diagnosis,

    output wire         hdmi_clk_n,
    output wire         hdmi_clk_p,
    output wire [2:0]   hdmi_data_n,
    output wire [2:0]   hdmi_data_p
);

    //==========================================
    // Prepare HDMI pipeline
    //==========================================

    wire        clk;
    wire        clk_5x;
    wire        lock;
    wire        reset_low;

    hdmi_clk hdmi_clk
    (
        .xtal(xtal),
        .clk(clk),
        .clk_5x(clk_5x),
        .lock(lock)
    );

    clock_synchronizer for_reset
    (
        .clk(clk),

        .bit_in(lock),
        .bit_out(reset_low)
    );

    //==========================================
    // Port switching
    //==========================================

    // switch during V-SYNC
    wire        v_sync;
    reg [1:0]   active_port;
    wire        switch_active_ready;
    wire        switch_active_valid;
    wire [1:0]  switch_active_to;

    initial begin
        active_port = 2'h0;
    end

    always_comb begin
        switch_active_ready = v_sync;
    end

    always_ff @(posedge clk) begin
        if (switch_active_valid == YES && switch_active_ready == YES) begin
            active_port <= switch_active_to;
        end
    end

    //==========================================
    // PS/2 frame logic
    //==========================================

    wire        character_ready;
    wire        character_valid;
    wire [7:0]  character_byte;

    ps2 ps2
    (
        .clk(clk),
        .reset_low(reset_low),

        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),

        .switch_active_ready(switch_active_ready),
        .switch_active_valid(switch_active_valid),
        .switch_active_to(switch_active_to),

        .character_ready(character_ready),
        .character_valid(character_valid),
        .character_byte(character_byte),
    );

    wire        key_code_ready [3:0];
    wire        key_code_valid [3:0];
    wire [7:0]  key_code_byte [3:0];

    always_comb begin
        key_code_valid[0] = NO;
        key_code_byte[0] = 8'h00;

        key_code_valid[1] = NO;
        key_code_byte[1] = 8'h00;

        character_ready = key_code_ready[2];
        key_code_valid[2] = character_valid;
        key_code_byte[2] = character_byte;

        key_code_valid[3] = NO;
        key_code_byte[3] = 8'h00;
    end

    //==========================================
    // Write characters to VRAM
    //==========================================

    wire        vram_read_ready [3:0];
    wire        vram_read_valid [3:0];
    wire [4:0]  vram_read_row [3:0];
    wire [6:0]  vram_read_col [3:0];
    wire [7:0]  vram_read_byte [3:0];

    wire [4:0]  top_row [3:0];

    wire [4:0]  cursor_row [3:0];
    wire [6:0]  cursor_col [3:0];

    generate
        genvar i;

        for(i=0; i<4; i=i+1) begin : vt_ports
            vt
            #(
                .CLK(51_800_000),
                .BAUD(115200)
            )
            vt
            (
                .clk(clk),
                .reset_low(reset_low),

                .uart_rx_pin(uart_rx[i]),
                .uart_tx_pin(uart_tx[i]),

                .key_code_ready(key_code_ready[i]),
                .key_code_valid(key_code_valid[i]),
                .key_code_byte(key_code_byte[i]),

                .top_row(top_row[i]),

                .cursor_row(cursor_row[i]),
                .cursor_col(cursor_col[i]),

                .vram_read_ready(vram_read_ready[i]),
                .vram_read_valid(vram_read_valid[i]),
                .vram_read_row(vram_read_row[i]),
                .vram_read_col(vram_read_col[i]),
                .vram_read_byte(vram_read_byte[i]),
            );
        end
    endgenerate

    //==========================================
    // Display VRAM to HDMI
    //==========================================

    wire [4:0]  active_top_row;
    wire [4:0]  active_cursor_row;
    wire [6:0]  active_cursor_col;
    wire        active_vram_read_valid;
    wire [4:0]  active_vram_read_row;
    wire [6:0]  active_vram_read_col;
    wire [7:0]  active_vram_read_byte;

    always_comb begin
        // inputs to HDMI
        active_top_row = top_row[active_port];
        active_cursor_row = cursor_row[active_port];
        active_cursor_col = cursor_col[active_port];
        active_vram_read_byte = vram_read_byte[active_port];
    end

    generate
        genvar i;

        for(i=0; i<4; i=i+1) begin : active_wiring
            always_comb begin
                if (active_port == i) begin
                    vram_read_valid[i] = active_vram_read_valid;
                    vram_read_row[i] = active_vram_read_row;
                    vram_read_col[i] = active_vram_read_col;
                end else begin
                    vram_read_valid[i] = NO;
                    vram_read_row[i] = 0;
                    vram_read_col[i] = 0;
                end
            end
        end
    endgenerate

    hdmi hdmi
    (
        .clk(clk),
        .clk_5x(clk_5x),
        .reset_low(reset_low),

        .top_row(active_top_row),

        .cursor_row(active_cursor_row),
        .cursor_col(active_cursor_col),

        .vram_valid(active_vram_read_valid),
        .vram_row(active_vram_read_row),
        .vram_col(active_vram_read_col),
        .vram_byte(active_vram_read_byte),

        .active_port(active_port),
        .v_sync(v_sync),

        .hdmi_clk_n(hdmi_clk_n),
        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_data_n(hdmi_data_n),
        .hdmi_data_p(hdmi_data_p)
    );

endmodule
