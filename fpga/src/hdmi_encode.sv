`default_nettype none
module hdmi_encode
(
    input wire          clk,
    input wire          clk_5x,
    input wire          reset_low,

    input wire          active,
    input wire          h_sync,
    input wire          v_sync,
    input wire [23:0]   rgb,

    output wire         hdmi_clk_n,
    output wire         hdmi_clk_p,
    output wire [2:0]   hdmi_data_n,
    output wire [2:0]   hdmi_data_p
);

    wire [2:0] tmds;
    wire [2:0] tmds_0, tmds_1, tmds_2, tmds_3, tmds_4;
    wire [2:0] tmds_5, tmds_6, tmds_7, tmds_8, tmds_9;

    hdmi_tmds tmds_blue (
        .clk(clk),
        .reset_low(reset_low),

        .active(active),
        .h_sync(h_sync),
        .v_sync(v_sync),

        .data_in(rgb[7:0]),
        .data_out({
            tmds_9[0], tmds_8[0], tmds_7[0], tmds_6[0], tmds_5[0],
            tmds_4[0], tmds_3[0], tmds_2[0], tmds_1[0], tmds_0[0]
        })
    );

    hdmi_tmds tmds_green (
        .clk(clk),
        .reset_low(reset_low),

        .active(active),
        .h_sync(NO),
        .v_sync(NO),

        .data_in(rgb[15:8]),
        .data_out({
            tmds_9[1], tmds_8[1], tmds_7[1], tmds_6[1], tmds_5[1],
            tmds_4[1], tmds_3[1], tmds_2[1], tmds_1[1], tmds_0[1]
        })
    );

    hdmi_tmds tmds_red (
        .clk(clk),
        .reset_low(reset_low),

        .active(active),
        .h_sync(NO),
        .v_sync(NO),

        .data_in(rgb[23:16]),
        .data_out({
            tmds_9[2], tmds_8[2], tmds_7[2], tmds_6[2], tmds_5[2],
            tmds_4[2], tmds_3[2], tmds_2[2], tmds_1[2], tmds_0[2]
        })
    );

    OSER10 tmds_serdes [2:0] (
        .Q(tmds),
        .D0(tmds_0),
        .D1(tmds_1),
        .D2(tmds_2),
        .D3(tmds_3),
        .D4(tmds_4),
        .D5(tmds_5),
        .D6(tmds_6),
        .D7(tmds_7),
        .D8(tmds_8),
        .D9(tmds_9),
        .PCLK(clk),
        .FCLK(clk_5x),
        .RESET(~reset_low)
    );

    ELVDS_OBUF tmds_buffer [3:0] (
        .I({clk, tmds}),
        .O({hdmi_clk_p, hdmi_data_p}),
        .OB({hdmi_clk_n, hdmi_data_n})
    );

endmodule