use anyhow::Context;

mod bdf;

fn main() -> anyhow::Result<()> {
    let bdf = reqwest::blocking::get("https://github.com/sunaku/tamzen-font/raw/refs/heads/master/bdf/Tamzen10x20r.bdf")?
        .text()?;
    let mut font = bdf::parse(&bdf).context("Tamzen10x20r.bdf")?;

    assert_eq!(font.width, 10);
    assert_eq!(font.height, 20);
    for (_code_point, glyph) in &font.glyphs {
        assert_eq!(glyph.width, font.width);
        assert_eq!(glyph.height, font.height);
    }

    // construct "^C" style control codes
    let bdf = reqwest::blocking::get("https://github.com/sunaku/tamzen-font/raw/refs/heads/master/bdf/Tamzen7x14r.bdf")?
        .text()?;
    let small = bdf::parse(&bdf).context("Tamzen7x14r.bdf")?;
    for index in 1..32 {
        // start with the "^" hat
        let mut rows = vec![
            0, 0, 0,
            128, 256+64, 512+32,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0,
            0, 0, 0,
        ];
        // as the small capital letter
        let small = small.glyph(0x40 + index).expect("A..Z");
        for (i, row) in small.rows.iter().enumerate() {
            rows[i + 3] ^= row;
        }
        font.glyph_add(index, rows);
    }

    // construct diagonal two digit hex glpyhs for non-ASCII
    let bdf = reqwest::blocking::get("https://github.com/sunaku/tamzen-font/raw/refs/heads/master/bdf/Tamzen7x13r.bdf")?
        .text()?;
    let small = bdf::parse(&bdf).context("Tamzen7x13r.bdf")?;
    for index in 127..256 {
        // start with empty glyph
        let mut rows = vec![
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
        ];
        // top-left digit
        let digit = (index >> 4) & 15;
        let digit = char::from_digit(digit, 16).expect("hex")
            .to_ascii_uppercase() as usize;
        let digit = small.glyph(digit).expect("0..9 A..F");
        for (i, row) in digit.rows.iter().enumerate() {
            if i > 0 {
                rows[i - 1] ^= row << 3;
            }
        }
        // bottom-right digit
        let digit = index & 15;
        let digit = char::from_digit(digit, 16).expect("hex")
            .to_ascii_uppercase() as usize;
        let digit = small.glyph(digit).expect("0..9 A..F");
        for (i, row) in digit.rows.iter().enumerate() {
            rows[i + 7] ^= row;
        }
        // add glyph
        font.glyph_add(index as usize, rows);
    }

    let mut verilog = String::with_capacity(30000);
    char_rom(&font, &mut verilog);
    std::fs::write("../fpga/src/char_rom.v", &verilog)?;

    Ok(())
}

fn char_rom(font: &bdf::Font, verilog: &mut String) {
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
    verilog.push_str("    reg [1:0] block;\n");
    verilog.push_str("\n");
    verilog.push_str("    always @(posedge clk) begin\n");
    verilog.push_str("        if (ce) begin\n");
    verilog.push_str("            block <= row[3:2];\n");
    verilog.push_str("        end\n");
    verilog.push_str("    end\n");
    verilog.push_str("\n");
    verilog.push_str("    wire [31:0] block_0_q;\n");
    verilog.push_str("    wire [31:0] block_1_q;\n");
    verilog.push_str("    wire [31:0] block_2_q;\n");
    verilog.push_str("    wire [31:0] block_3_q;\n");
    verilog.push_str("\n");
    verilog.push_str("    pROM\n");
    verilog.push_str("    #(\n");
    verilog.push_str("        .READ_MODE(1'b0),\n");
    verilog.push_str("        .BIT_WIDTH(8),\n");
    verilog.push_str("        .RESET_MODE(\"SYNC\"");
    for row in 0..8 {
        for upper in 0..8 {
            verilog.push_str("),\n");
            let init = (row * 8) + upper;
            let mut line = format!("        .INIT_RAM_{init:02X}(256'h");
            line.reserve(110);
            for lower in (0..32).rev() {
                let glyph = (upper * 32) + lower;
                let glyph = font.glyph_or_blank(glyph);
                let row = glyph.rows[row];
                line.push(char::from_digit(((row >> 4) & 15) as u32, 16).expect("hex"));
                line.push(char::from_digit(((row >> 0) & 15) as u32, 16).expect("hex"));
            }
            verilog.push_str(&line);
        }
    }
    verilog.push_str(")\n");
    verilog.push_str("    )\n");
    verilog.push_str("    block_0\n");
    verilog.push_str("    (\n");
    verilog.push_str("        .DO(block_0_q),\n");
    verilog.push_str("        .CLK(clk),\n");
    verilog.push_str("        .OCE(1'b1),\n");
    verilog.push_str("        .CE(ce & ~row[4] & ~row[3]),\n");
    verilog.push_str("        .RESET(1'b0),\n");
    verilog.push_str("        .AD({row[2:0],char[7:0],3'b000})\n");
    verilog.push_str("    );\n");
    verilog.push_str("\n");
    verilog.push_str("    pROM\n");
    verilog.push_str("    #(\n");
    verilog.push_str("        .READ_MODE(1'b0),\n");
    verilog.push_str("        .BIT_WIDTH(8),\n");
    verilog.push_str("        .RESET_MODE(\"SYNC\"");
    for row in 8..16 {
        for upper in 0..8 {
            verilog.push_str("),\n");
            let init = ((row * 8) + upper) & 63;
            let mut line = format!("        .INIT_RAM_{init:02X}(256'h");
            line.reserve(110);
            for lower in (0..32).rev() {
                let glyph = (upper * 32) + lower;
                let glyph = font.glyph_or_blank(glyph);
                let row = glyph.rows[row];
                line.push(char::from_digit(((row >> 4) & 15) as u32, 16).expect("hex"));
                line.push(char::from_digit(((row >> 0) & 15) as u32, 16).expect("hex"));
            }
            verilog.push_str(&line);
        }
    }
    verilog.push_str(")\n");
    verilog.push_str("    )\n");
    verilog.push_str("    block_1\n");
    verilog.push_str("    (\n");
    verilog.push_str("        .DO(block_1_q),\n");
    verilog.push_str("        .CLK(clk),\n");
    verilog.push_str("        .OCE(1'b1),\n");
    verilog.push_str("        .CE(ce & ~row[4] & row[3]),\n");
    verilog.push_str("        .RESET(1'b0),\n");
    verilog.push_str("        .AD({row[2:0],char[7:0],3'b000})\n");
    verilog.push_str("    );\n");
    verilog.push_str("\n");
    verilog.push_str("    pROM\n");
    verilog.push_str("    #(\n");
    verilog.push_str("        .READ_MODE(1'b0),\n");
    verilog.push_str("        .BIT_WIDTH(8),\n");
    verilog.push_str("        .RESET_MODE(\"SYNC\"");
    for row in 16..20 {
        for upper in 0..8 {
            verilog.push_str("),\n");
            let init = ((row * 8) + upper) & 63;
            let mut line = format!("        .INIT_RAM_{init:02X}(256'h");
            line.reserve(110);
            for lower in (0..32).rev() {
                let glyph = (upper * 32) + lower;
                let glyph = font.glyph_or_blank(glyph);
                let row = glyph.rows[row];
                line.push(char::from_digit(((row >> 4) & 15) as u32, 16).expect("hex"));
                line.push(char::from_digit(((row >> 0) & 15) as u32, 16).expect("hex"));
            }
            verilog.push_str(&line);
        }
    }
    verilog.push_str(")\n");
    verilog.push_str("    )\n");
    verilog.push_str("    block_2\n");
    verilog.push_str("    (\n");
    verilog.push_str("        .DO(block_2_q),\n");
    verilog.push_str("        .CLK(clk),\n");
    verilog.push_str("        .OCE(1'b1),\n");
    verilog.push_str("        .CE(ce & row[4] & ~row[3]),\n");
    verilog.push_str("        .RESET(1'b0),\n");
    verilog.push_str("        .AD({row[2:0],char[7:0],3'b000})\n");
    verilog.push_str("    );\n");
    verilog.push_str("\n");
    verilog.push_str("    pROM\n");
    verilog.push_str("    #(\n");
    verilog.push_str("        .READ_MODE(1'b0),\n");
    verilog.push_str("        .BIT_WIDTH(2),\n");
    verilog.push_str("        .RESET_MODE(\"SYNC\"");
    for row in 0..20 {
        for upper in 0..2 {
            verilog.push_str("),\n");
            let init = (row * 2) + upper;
            let mut line = format!("        .INIT_RAM_{init:02X}(256'h");
            line.reserve(110);
            let mut digit = 0u32;
            for lower in (0..128).rev() {
                let glyph = (upper * 128) + lower;
                let glyph = font.glyph_or_blank(glyph);
                let row = glyph.rows[row];
                if lower % 2 == 1 {
                    digit = ((row >> 6) & 12) as u32;
                } else {
                    digit |= ((row >> 8) & 3) as u32;
                    line.push(char::from_digit(digit, 16).expect("hex"));
                }
            }
            verilog.push_str(&line);
        }
    }
    verilog.push_str(")\n");
    verilog.push_str("    )\n");
    verilog.push_str("    block_3\n");
    verilog.push_str("    (\n");
    verilog.push_str("        .DO(block_3_q),\n");
    verilog.push_str("        .CLK(clk),\n");
    verilog.push_str("        .OCE(1'b1),\n");
    verilog.push_str("        .CE(ce),\n");
    verilog.push_str("        .RESET(1'b0),\n");
    verilog.push_str("        .AD({row[4:0],char[7:0],1'b0})\n");
    verilog.push_str("    );\n");
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
}
