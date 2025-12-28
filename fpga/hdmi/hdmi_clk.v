`default_nettype none
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

	rPLL pll (
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
	defparam pll.FCLKIN = "27";
	defparam pll.DYN_IDIV_SEL = "false";
	defparam pll.IDIV_SEL = 4;
	defparam pll.DYN_FBDIV_SEL = "false";
	defparam pll.FBDIV_SEL = 47;
	defparam pll.DYN_ODIV_SEL = "false";
	defparam pll.ODIV_SEL = 2;
	defparam pll.PSDA_SEL = "0000";
	defparam pll.DYN_DA_EN = "true";
	defparam pll.DUTYDA_SEL = "1000";
	defparam pll.CLKOUT_FT_DIR = 1'b1;
	defparam pll.CLKOUTP_FT_DIR = 1'b1;
	defparam pll.CLKOUT_DLY_STEP = 0;
	defparam pll.CLKOUTP_DLY_STEP = 0;
	defparam pll.CLKFB_SEL = "internal";
	defparam pll.CLKOUT_BYPASS = "false";
	defparam pll.CLKOUTP_BYPASS = "false";
	defparam pll.CLKOUTD_BYPASS = "false";
	defparam pll.DYN_SDIV_SEL = 2;
	defparam pll.CLKOUTD_SRC = "CLKOUT";
	defparam pll.CLKOUTD3_SRC = "CLKOUT";
	defparam pll.DEVICE = "GW1NR-9C";

	CLKDIV div (
	    .HCLKIN(clk_5x),
	    .CLKOUT(clk),
	    .RESETN(lock),
	    .CALIB(gw_gnd)
	);
	defparam div.DIV_MODE = "5";
	defparam div.GSREN = "false";

endmodule