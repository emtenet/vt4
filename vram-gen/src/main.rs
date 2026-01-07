use anyhow::Context;

fn main() -> anyhow::Result<()> {
    let mut vram = [b' '; 32 * 128];

    let init = std::fs::read_to_string("init.txt").context("init.txt")?;
    for (i, line) in init.lines().enumerate() {
        for (j, c) in line.chars().enumerate() {
            if j < 128 && c.is_ascii() {
                let addr = (i * 128) + j;
                vram[addr] = c as u8;
            }
        }
    }

    let mut verilog = String::with_capacity(30000);
    verilog.push_str("`default_nettype none\n");
    verilog.push_str("`timescale 1ns / 1ps\n");
    verilog.push_str("module vram\n");
    verilog.push_str("(\n");
    verilog.push_str("    input   wire       clk,\n");
    verilog.push_str("\n");
    verilog.push_str("    output  wire       read_ready,\n");
    verilog.push_str("    input   wire       read_valid,\n");
    verilog.push_str("    input   wire [4:0] read_row,\n");
    verilog.push_str("    input   wire [6:0] read_col,\n");
    verilog.push_str("    output  wire [7:0] read_byte,\n");
    verilog.push_str("\n");
    verilog.push_str("    output  wire       write_ready,\n");
    verilog.push_str("    input   wire       write_valid,\n");
    verilog.push_str("    input   wire [4:0] write_row,\n");
    verilog.push_str("    input   wire [6:0] write_col,\n");
    verilog.push_str("    input   wire [7:0] write_byte\n");
    verilog.push_str(");\n");
    verilog.push_str("\n");
    verilog.push_str("    assign read_ready = 1'b1;\n");
    verilog.push_str("    assign write_ready = (read_valid == 1'b0);\n");
    verilog.push_str("\n");
    verilog.push_str("    wire read_enable;\n");
    verilog.push_str("    wire write_enable;\n");
    verilog.push_str("    assign read_enable = (read_valid == 1'b1) && (read_ready == 1'b1);\n");
    verilog.push_str("    assign write_enable = (write_valid == 1'b1) && (write_ready == 1'b1);\n");
    verilog.push_str("\n");
    verilog.push_str("    wire [31:0] read_upper;\n");
    verilog.push_str("    wire [31:0] read_lower;\n");
    verilog.push_str("    assign read_byte = {read_upper[3:0], read_lower[3:0]};\n");
    verilog.push_str("\n");
    verilog.push_str("    SDPB\n");
    verilog.push_str("    #(\n");
    verilog.push_str("        .READ_MODE(1'b0),\n");
    verilog.push_str("        .BIT_WIDTH_0(4),\n");
    verilog.push_str("        .BIT_WIDTH_1(4),\n");
    verilog.push_str("        .BLK_SEL_0(3'b000),\n");
    verilog.push_str("        .BLK_SEL_1(3'b000),\n");
    verilog.push_str("        .RESET_MODE(\"SYNC\"");
    for row in 0..32 {
        for high in 0..2 {
            verilog.push_str("),\n");
            let init = (row * 2) + high;
            let mut line = format!("        .INIT_RAM_{init:02X}(256'h");
            line.reserve(110);
            for low in (0..64).rev() {
                let addr = (row * 128) + (high * 64) + low;
                let data = (vram[addr] >> 4) & 15;
                line.push(char::from_digit(data as u32, 16).expect("hex"));
            }
            verilog.push_str(&line);
        }
    }
    verilog.push_str(")\n");
    verilog.push_str("    )\n");
    verilog.push_str("    upper\n");
    verilog.push_str("    (\n");
    verilog.push_str("        // port A = write\n");
    verilog.push_str("        .CLKA(clk),\n");
    verilog.push_str("        .CEA(write_enable),\n");
    verilog.push_str("        .RESETA(1'b0),\n");
    verilog.push_str("        .BLKSELA(3'b0),\n");
    verilog.push_str("        .ADA({write_row, write_col, 2'b0}),\n");
    verilog.push_str("        .DI({28'b0, write_byte[7:4]}),\n");
    verilog.push_str("\n");
    verilog.push_str("        // port B = read\n");
    verilog.push_str("        .CLKB(clk),\n");
    verilog.push_str("        .CEB(read_enable),\n");
    verilog.push_str("        .RESETB(1'b0),\n");
    verilog.push_str("        .OCE(1'b1),\n");
    verilog.push_str("        .BLKSELB(3'b0),\n");
    verilog.push_str("        .ADB({read_row, read_col, 2'b0}),\n");
    verilog.push_str("        .DO(read_upper)\n");
    verilog.push_str("    );\n");
    verilog.push_str("\n");
    verilog.push_str("    SDPB\n");
    verilog.push_str("    #(\n");
    verilog.push_str("        .READ_MODE(1'b0),\n");
    verilog.push_str("        .BIT_WIDTH_0(4),\n");
    verilog.push_str("        .BIT_WIDTH_1(4),\n");
    verilog.push_str("        .BLK_SEL_0(3'b000),\n");
    verilog.push_str("        .BLK_SEL_1(3'b000),\n");
    verilog.push_str("        .RESET_MODE(\"SYNC\"");
    for row in 0..32 {
        for high in 0..2 {
            verilog.push_str("),\n");
            let init = (row * 2) + high;
            let mut line = format!("        .INIT_RAM_{init:02X}(256'h");
            line.reserve(110);
            for low in (0..64).rev() {
                let addr = (row * 128) + (high * 64) + low;
                let data = vram[addr] & 15;
                line.push(char::from_digit(data as u32, 16).expect("hex"));
            }
            verilog.push_str(&line);
        }
    }
    verilog.push_str(")\n");
    verilog.push_str("    )\n");
    verilog.push_str("    lower\n");
    verilog.push_str("    (\n");
    verilog.push_str("        // port A = write\n");
    verilog.push_str("        .CLKA(clk),\n");
    verilog.push_str("        .CEA(write_enable),\n");
    verilog.push_str("        .RESETA(1'b0),\n");
    verilog.push_str("        .BLKSELA(3'b0),\n");
    verilog.push_str("        .ADA({write_row, write_col, 2'b0}),\n");
    verilog.push_str("        .DI({28'b0, write_byte[3:0]}),\n");
    verilog.push_str("\n");
    verilog.push_str("        // port B = read\n");
    verilog.push_str("        .CLKB(clk),\n");
    verilog.push_str("        .CEB(read_enable),\n");
    verilog.push_str("        .RESETB(1'b0),\n");
    verilog.push_str("        .OCE(1'b1),\n");
    verilog.push_str("        .BLKSELB(3'b0),\n");
    verilog.push_str("        .ADB({read_row, read_col, 2'b0}),\n");
    verilog.push_str("        .DO(read_lower)\n");
    verilog.push_str("    );\n");
    verilog.push_str("\n");
    verilog.push_str("endmodule\n");
    std::fs::write("../fpga/src/vram.sv", &verilog)?;

    Ok(())
}
