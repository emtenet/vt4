`default_nettype none
`timescale 1ns / 1ps
module hdmi_clk
(
	input wire xtal,
	output wire clk,
	output wire clk_5x,
	output wire lock
);

	// Input 27MHz
	// Output 51.8MHz and 259.2MHz (5x)

	wire clkoutp_o;
	wire clkoutd_o;
	wire clkoutd3_o;
	wire gw_gnd;

	assign gw_gnd = 1'b0;

	rPLL
	#(
		.FCLKIN("27"),
		.DYN_IDIV_SEL("false"),
		.IDIV_SEL(4),
		.DYN_FBDIV_SEL("false"),
		.FBDIV_SEL(47),
		.DYN_ODIV_SEL("false"),
		.ODIV_SEL(2),
		.PSDA_SEL("0000"),
		.DYN_DA_EN("true"),
		.DUTYDA_SEL("1000"),
		.CLKOUT_FT_DIR(1'b1),
		.CLKOUTP_FT_DIR(1'b1),
		.CLKOUT_DLY_STEP(0),
		.CLKOUTP_DLY_STEP(0),
		.CLKFB_SEL("internal"),
		.CLKOUT_BYPASS("false"),
		.CLKOUTP_BYPASS("false"),
		.CLKOUTD_BYPASS("false"),
		.DYN_SDIV_SEL(2),
		.CLKOUTD_SRC("CLKOUT"),
		.CLKOUTD3_SRC("CLKOUT"),
		.DEVICE("GW1NR-9C")
	)
	pll
	(
	    .CLKOUT(clk_5x),
	    .LOCK(lock),
	    .CLKOUTP(clkoutp_o),
	    .CLKOUTD(clkoutd_o),
	    .CLKOUTD3(clkoutd3_o),
	    .RESET(gw_gnd),
	    .RESET_P(gw_gnd),
	    .CLKIN(xtal),
	    .CLKFB(gw_gnd),
	    .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
	    .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
	    .ODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
	    .PSDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
	    .DUTYDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
	    .FDLY({gw_gnd,gw_gnd,gw_gnd,gw_gnd})
	);

	CLKDIV
	#(
		.DIV_MODE("5"),
		.GSREN("false")
	)
	div
	(
	    .HCLKIN(clk_5x),
	    .CLKOUT(clk),
	    .RESETN(lock),
	    .CALIB(gw_gnd)
	);

endmodule
