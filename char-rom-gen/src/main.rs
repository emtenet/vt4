mod bdf;

fn main() -> anyhow::Result<()> {
    let font = bdf::read("Tamzen10x20r.bdf")?;

    assert_eq!(font.width, 10);
    assert_eq!(font.height, 20);
    for (_code_point, glyph) in &font.glyphs {
        assert_eq!(glyph.width, font.width);
        assert_eq!(glyph.height, font.height);
    }

    let mut verilog = String::with_capacity(30000);

    verilog.push_str("`default_nettype none\n");
    verilog.push_str("module char_rom\n");
    verilog.push_str("(\n");
    verilog.push_str("    input wire clk,\n");
    verilog.push_str("    input wire ce,\n");
    verilog.push_str("    input wire [7:0] char,\n");
    verilog.push_str("    input wire [4:0] row,\n");
    verilog.push_str("    output wire [9:0] q\n");
    verilog.push_str(");\n");
    verilog.push_str("\n");
    verilog.push_str("reg [1:0] block;\n");
    verilog.push_str("\n");
    verilog.push_str("always @(posedge clk) begin\n");
    verilog.push_str("    if (ce) begin\n");
    verilog.push_str("        block <= row[3:2];\n");
    verilog.push_str("    end\n");
    verilog.push_str("end\n");
    verilog.push_str("\n");
    verilog.push_str("wire [31:0] block_0_q;\n");
    verilog.push_str("wire [31:0] block_1_q;\n");
    verilog.push_str("wire [31:0] block_2_q;\n");
    verilog.push_str("wire [31:0] block_3_q;\n");
    verilog.push_str("\n");
    verilog.push_str("pROM block_0 (\n");
    verilog.push_str("    .DO(block_0_q),\n");
    verilog.push_str("    .CLK(clk),\n");
    verilog.push_str("    .OCE(1'b1),\n");
    verilog.push_str("    .CE(ce & ~row[4] & ~row[3]),\n");
    verilog.push_str("    .RESET(1'b0),\n");
    verilog.push_str("    .AD({row[2:0],char[7:0],3'b000})\n");
    verilog.push_str(");\n");
    verilog.push_str("defparam block_0.READ_MODE = 1'b0;\n");
    verilog.push_str("defparam block_0.BIT_WIDTH = 8;\n");
    verilog.push_str("defparam block_0.RESET_MODE = \"SYNC\";\n");
    for row in 0..8 {
        for upper in 0..8 {
            let init = (row * 8) + upper;
            let mut line = format!("defparam block_0.INIT_RAM_{init:02X} = 256'h");
            line.reserve(110);
            for lower in (0..32).rev() {
                let glyph = (upper * 32) + lower;
                let glyph = font.glyph(glyph);
                let row = glyph.rows[row];
                line.push(char::from_digit(((row >> 4) & 15) as u32, 16).expect("hex"));
                line.push(char::from_digit(((row >> 0) & 15) as u32, 16).expect("hex"));
            }
            line.push_str(";\n");
            verilog.push_str(&line);
        }
    }
    verilog.push_str("\n");
    verilog.push_str("pROM block_1 (\n");
    verilog.push_str("    .DO(block_1_q),\n");
    verilog.push_str("    .CLK(clk),\n");
    verilog.push_str("    .OCE(1'b1),\n");
    verilog.push_str("    .CE(ce & ~row[4] & row[3]),\n");
    verilog.push_str("    .RESET(1'b0),\n");
    verilog.push_str("    .AD({row[2:0],char[7:0],3'b000})\n");
    verilog.push_str(");\n");
    verilog.push_str("defparam block_1.READ_MODE = 1'b0;\n");
    verilog.push_str("defparam block_1.BIT_WIDTH = 8;\n");
    verilog.push_str("defparam block_1.RESET_MODE = \"SYNC\";\n");
    for row in 8..16 {
        for upper in 0..8 {
            let init = ((row * 8) + upper) & 63;
            let mut line = format!("defparam block_1.INIT_RAM_{init:02X} = 256'h");
            line.reserve(110);
            for lower in (0..32).rev() {
                let glyph = (upper * 32) + lower;
                let glyph = font.glyph(glyph);
                let row = glyph.rows[row];
                line.push(char::from_digit(((row >> 4) & 15) as u32, 16).expect("hex"));
                line.push(char::from_digit(((row >> 0) & 15) as u32, 16).expect("hex"));
            }
            line.push_str(";\n");
            verilog.push_str(&line);
        }
    }
    verilog.push_str("\n");
    verilog.push_str("pROM block_2 (\n");
    verilog.push_str("    .DO(block_2_q),\n");
    verilog.push_str("    .CLK(clk),\n");
    verilog.push_str("    .OCE(1'b1),\n");
    verilog.push_str("    .CE(ce & row[4] & ~row[3]),\n");
    verilog.push_str("    .RESET(1'b0),\n");
    verilog.push_str("    .AD({row[2:0],char[7:0],3'b000})\n");
    verilog.push_str(");\n");
    verilog.push_str("defparam block_2.READ_MODE = 1'b0;\n");
    verilog.push_str("defparam block_2.BIT_WIDTH = 8;\n");
    verilog.push_str("defparam block_2.RESET_MODE = \"SYNC\";\n");
    for row in 16..20 {
        for upper in 0..8 {
            let init = ((row * 8) + upper) & 63;
            let mut line = format!("defparam block_2.INIT_RAM_{init:02X} = 256'h");
            line.reserve(110);
            for lower in (0..32).rev() {
                let glyph = (upper * 32) + lower;
                let glyph = font.glyph(glyph);
                let row = glyph.rows[row];
                line.push(char::from_digit(((row >> 4) & 15) as u32, 16).expect("hex"));
                line.push(char::from_digit(((row >> 0) & 15) as u32, 16).expect("hex"));
            }
            line.push_str(";\n");
            verilog.push_str(&line);
        }
    }
    verilog.push_str("\n");
    verilog.push_str("pROM block_3 (\n");
    verilog.push_str("    .DO(block_3_q),\n");
    verilog.push_str("    .CLK(clk),\n");
    verilog.push_str("    .OCE(1'b1),\n");
    verilog.push_str("    .CE(ce),\n");
    verilog.push_str("    .RESET(1'b0),\n");
    verilog.push_str("    .AD({row[4:0],char[7:0],1'b0})\n");
    verilog.push_str(");\n");
    verilog.push_str("defparam block_3.READ_MODE = 1'b0;\n");
    verilog.push_str("defparam block_3.BIT_WIDTH = 2;\n");
    verilog.push_str("defparam block_3.RESET_MODE = \"SYNC\";\n");
    for row in 0..20 {
        for upper in 0..2 {
            let init = (row * 2) + upper;
            let mut line = format!("defparam block_3.INIT_RAM_{init:02X} = 256'h");
            line.reserve(110);
            let mut digit = 0u32;
            for lower in (0..128).rev() {
                let glyph = (upper * 128) + lower;
                let glyph = font.glyph(glyph);
                let row = glyph.rows[row];
                if lower % 2 == 1 {
                    digit = ((row >> 6) & 12) as u32;
                } else {
                    digit |= ((row >> 8) & 3) as u32;
                    line.push(char::from_digit(digit, 16).expect("hex"));
                }
            }
            line.push_str(";\n");
            verilog.push_str(&line);
        }
    }
    verilog.push_str("\n");
    verilog.push_str("assign q = row[4]\n");
    verilog.push_str("        ? (row[3]\n");
    verilog.push_str("            ? 10'b0000000000\n");
    verilog.push_str("            : {block_3_q[1:0], block_2_q[7:0]})\n");
    verilog.push_str("        : (row[3]\n");
    verilog.push_str("            ? {block_3_q[1:0], block_1_q[7:0]}\n");
    verilog.push_str("            : {block_3_q[1:0], block_0_q[7:0]});\n");
    verilog.push_str("\n");
    verilog.push_str("endmodule\n");

    std::fs::write("../char_rom.v", &verilog)?;

    Ok(())
}
