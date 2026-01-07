use anyhow::{
    Context,
    Result,
    bail,
};
use std::collections::HashMap;
use std::str::FromStr;

const ROM_SIZE: usize = 1 << 13;
type ROM = [u8; ROM_SIZE];
const EXTENDED: usize = 1 << 12;
const SCAN_CODE_SHIFT: usize = 4;
const NUM_LOCK: usize = 1 << 3;
const CONTROL: usize = 1 << 2;
const CAPS_LOCK: usize = 1 << 1;
const SHIFT: usize = 1 << 0;

const ENCODE_ESCAPE: u8 = 0b1000_0000;
const ENCODE_NUMBER: u8 = 0b0100_0000;
const ENCODE_TENS_SHIFT: usize = 4;
const ENCODE_TENS_MASK: u8 = 0b0011_0000;
const ENCODE_ONES_SHIFT: usize = 0;
const ENCODE_ONES_MASK: u8 = 0b0000_1111;
const ENCODE_NOT_CONTROL: u8 = 0b0010_0000;
const ENCODE_LETTER_SHIFT: usize = 0;
const ENCODE_LETTER_MASK: u8 = 0b0001_1111;

#[derive(Debug)]
struct Key {
    extended: bool,
    scan_code: u8,
    num_lock: Option<char>,
    normal: Code,
    shift: Code,
    control: Control,
}

#[derive(Clone)]
#[derive(Debug)]
enum Control {
    None,
    Some(Code),
    Similar,
}

#[derive(Clone)]
#[derive(Debug)]
enum Code {
    Basic {
        character: char,
    },
    Letter {
        control: bool,
        letter: char,
    },
    Number {
        tens: char,
        ones: char,
    },
}

impl Code {
    fn can_caps_lock(&self) -> bool {
        match self {
            Code::Basic { character } =>
                character.is_ascii_lowercase(),
            _ =>
                false,
        }
    }

    fn encode(&self) -> u8 {
        match self {
            Code::Basic { character } => {
                u32::from(*character) as u8
            }
            Code::Letter { control, letter } => {
                let letter = u32::from(*letter) as u8;
                let letter = (letter << ENCODE_LETTER_SHIFT) & ENCODE_LETTER_MASK;
                if *control {
                    ENCODE_ESCAPE | letter
                } else {
                    ENCODE_ESCAPE | ENCODE_NOT_CONTROL | letter
                }
            }
            Code::Number { tens, ones } => {
                let tens = u32::from(*tens) as u8;
                let tens = (tens << ENCODE_TENS_SHIFT) & ENCODE_TENS_MASK;
                let ones = u32::from(*ones) as u8;
                let ones = (ones << ENCODE_ONES_SHIFT) & ENCODE_ONES_MASK;
                ENCODE_ESCAPE | ENCODE_NUMBER | tens | ones
            }
        }
    }
}

fn main() -> Result<()> {
    let keys = read_keys()?;
    let mut rom: ROM = [0; ROM_SIZE];

    for key in keys.values() {
        let caps_lock = key.normal.can_caps_lock();
        let normal = key.normal.encode();
        let shift = key.shift.encode();

        let mut addr = (key.scan_code as usize) << SCAN_CODE_SHIFT;
        if key.extended {
            addr |= EXTENDED;
        }
        rom[addr] = normal;
        rom[SHIFT | addr] = shift;
        if caps_lock {
            rom[CAPS_LOCK | addr] = shift;
            rom[CAPS_LOCK | SHIFT | addr] = normal;
        } else {
            rom[CAPS_LOCK | addr] = normal;
            rom[CAPS_LOCK | SHIFT | addr] = shift;
        }
        match &key.control {
            Control::None => {

            }
            Control::Some(control) => {
                let control = control.encode();
                rom[CONTROL | addr] = control;
                rom[CONTROL | SHIFT | addr] = control;
                rom[CONTROL | CAPS_LOCK | addr] = control;
                rom[CONTROL | CAPS_LOCK | SHIFT | addr] = control;
            }
            Control::Similar => {
                rom[CONTROL | addr] = rom[addr];
                rom[CONTROL | SHIFT | addr] = rom[SHIFT | addr];
                rom[CONTROL | CAPS_LOCK | addr] = rom[CAPS_LOCK | addr];
                rom[CONTROL | CAPS_LOCK | SHIFT | addr] = rom[CAPS_LOCK | SHIFT | addr];
            }
        }
        rom[NUM_LOCK | addr] = rom[addr];
        rom[NUM_LOCK | SHIFT | addr] = rom[SHIFT | addr];
        rom[NUM_LOCK | CAPS_LOCK | addr] = rom[CAPS_LOCK | addr];
        rom[NUM_LOCK | CAPS_LOCK | SHIFT | addr] = rom[CAPS_LOCK | SHIFT | addr];
        rom[NUM_LOCK | CONTROL | addr] = rom[CONTROL | addr];
        rom[NUM_LOCK | CONTROL | SHIFT | addr] = rom[CONTROL | SHIFT | addr];
        rom[NUM_LOCK | CONTROL | CAPS_LOCK | addr] = rom[CONTROL | CAPS_LOCK | addr];
        rom[NUM_LOCK | CONTROL | CAPS_LOCK | SHIFT | addr] = rom[CONTROL | CAPS_LOCK | SHIFT | addr];
        if let Some(num_lock) = key.num_lock {
            let num_lock = u32::from(num_lock) as u8;
            // Control does nothing
            rom[NUM_LOCK | CONTROL | addr] = 0;
            rom[NUM_LOCK | CAPS_LOCK | CONTROL | addr] = 0;
            // Shift does what normal would do
            rom[NUM_LOCK | SHIFT | addr] = rom[addr];
            rom[NUM_LOCK | CAPS_LOCK | SHIFT | addr] = rom[addr];
            // Normal is now the NUM LOCK special
            rom[NUM_LOCK | addr] = num_lock;
            rom[NUM_LOCK | CAPS_LOCK | addr] = num_lock;
        }
    }

    // println!("TAB   {:?}", &rom[(13<<SCAN_CODE_SHIFT)..(14<<SCAN_CODE_SHIFT)]);
    // println!("2/@   {:?}", &rom[(30<<SCAN_CODE_SHIFT)..(31<<SCAN_CODE_SHIFT)]);
    // println!("SPACE {:?}", &rom[(41<<SCAN_CODE_SHIFT)..(42<<SCAN_CODE_SHIFT)]);

    let mut verilog = String::with_capacity(30000);
    key_code(&rom, &mut verilog);
    std::fs::write("../fpga/src/key_code.sv", &verilog)?;

    Ok(())
}

fn read_keys() -> Result<HashMap<String, Key>> {
    let mut keys = HashMap::new();
    let lines = std::fs::read_to_string("key-code.txt")
        .context("Could not open key-code.txt")?;

    for line in lines.lines() {
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let (name, key) = read_key(line, &keys)?;
        keys.insert(name, key);
    }

    Ok(keys)
}

fn read_key(line: &str, keys: &HashMap<String, Key>) -> Result<(String, Key)> {
    let line = line.trim_matches(' ');

    let Some((name, line)) = line.split_once("  ") else {
        bail!("Missing scan code after name in '{line}'");
    };
    let line = line.trim_start_matches(' ');
    let name = name.to_owned();

    let Some((mut scan_code, line)) = line.split_once("  ") else {
        bail!("Missing codes after scan code in '{line}'");
    };
    let mut line = line.trim_start_matches(' ');
    let mut extended = false;
    if let Some(rest) = scan_code.strip_prefix("E0 ") {
        extended = true;
        scan_code = rest;
    }
    let scan_code = u8::from_str_radix(scan_code, 16)
        .with_context(|| format!("Invalid scan code {scan_code}"))?;

    let mut num_lock = None;
    if let Some(rest) = line.strip_prefix("NUM=") {
        let Some((c, rest)) = rest.split_once("  ") else {
            bail!("Missing codes after 'NUM=' in '{rest}'");
        };
        line = rest.trim_start_matches(' ');
        let c = char::from_str(c)
            .with_context(|| format!("Num Lock '{c}' must be a single character"))?;
        num_lock = Some(c);
    }

    let normal: Code;
    let shift: Code;
    let control: Control;

    if let Some(other) = line.strip_prefix("-> ") {
        let Some(other) = keys.get(other) else {
            bail!("Other key '{other}' not found");
        };

        normal = other.normal.clone();
        shift = other.shift.clone();
        control = other.control.clone();
    } else {
        let Some((mut code, mut line)) = line.split_once("  ") else {
            bail!("Missing shift code after normal code in '{line}'");
        };
        line = line.trim_start_matches(' ');

        normal = read_code(code)
            .with_context(|| format!("Invalid code for '{name}'"))?;

        code = line;
        if let Some((s, rest)) = line.split_once("  ") {
            code = s;
            line = rest.trim_start_matches(' ');
        } else {
            line = "";
        }
        if code == "..." {
            shift = normal.clone();
        } else {
            shift = read_code(code)
                .with_context(|| format!("Invalid shift code for '{name}'"))?;
        }

        if line.is_empty() {
            control = Control::None;
        } else if line == "..." {
            control = Control::Similar;
        } else {
            control = Control::Some(
                read_code(line)
                    .with_context(|| format!("Invalid control code for '{name}'"))?
            );
        }
    }

    let key = Key {
        extended,
        scan_code,
        num_lock,
        normal,
        shift,
        control,
    };

    Ok((name, key))
}

fn read_code(code: &str) -> Result<Code> {
    if code == "TAB" {
        return Ok(Code::Basic { character: '\t' });
    }
    if code == "ENTER" {
        return Ok(Code::Basic { character: '\n' });
    }
    if code == "BACKSPACE" {
        return Ok(Code::Basic { character: '\x7F' });
    }
    if code == "SPACE" {
        return Ok(Code::Basic { character: ' ' });
    }
    let mut chars = code.chars();
    let Some(mut character) = chars.next() else {
        bail!("Code '{code}' is empty");
    };
    // single ASCII code?
    if let Some(next) = chars.next() {
        if character != '^' {
            bail!("Code '{code}' does not start with '^'");
        }
        character = next;
    } else {
        if !character.is_ascii() {
            bail!("Code '{code}' is not ASCII");
        }
        if character.is_ascii_control() {
            bail!("Code '{code}' is CONTROL");
        }
        return Ok(Code::Basic { character });
    }
    // single CONTROL code?
    if let Some(next) = chars.next() {
        if character != '[' {
            bail!("Code '{code}' does not start with '^['");
        }
        character = next;
    } else {
        match character {
            '@' => return Ok(Code::Basic { character: '\x00' }),
            'A' => return Ok(Code::Basic { character: '\x01' }),
            'B' => return Ok(Code::Basic { character: '\x02' }),
            'C' => return Ok(Code::Basic { character: '\x03' }),
            'D' => return Ok(Code::Basic { character: '\x04' }),
            'E' => return Ok(Code::Basic { character: '\x05' }),
            'F' => return Ok(Code::Basic { character: '\x06' }),
            'G' => return Ok(Code::Basic { character: '\x07' }),
            'H' => return Ok(Code::Basic { character: '\x08' }),
            'I' => return Ok(Code::Basic { character: '\x09' }),
            'J' => return Ok(Code::Basic { character: '\x0A' }),
            'K' => return Ok(Code::Basic { character: '\x0B' }),
            'L' => return Ok(Code::Basic { character: '\x0C' }),
            'M' => return Ok(Code::Basic { character: '\x0D' }),
            'N' => return Ok(Code::Basic { character: '\x0E' }),
            'O' => return Ok(Code::Basic { character: '\x0F' }),
            'P' => return Ok(Code::Basic { character: '\x10' }),
            'Q' => return Ok(Code::Basic { character: '\x11' }),
            'R' => return Ok(Code::Basic { character: '\x12' }),
            'S' => return Ok(Code::Basic { character: '\x13' }),
            'T' => return Ok(Code::Basic { character: '\x14' }),
            'U' => return Ok(Code::Basic { character: '\x15' }),
            'V' => return Ok(Code::Basic { character: '\x16' }),
            'W' => return Ok(Code::Basic { character: '\x17' }),
            'X' => return Ok(Code::Basic { character: '\x18' }),
            'Y' => return Ok(Code::Basic { character: '\x19' }),
            'Z' => return Ok(Code::Basic { character: '\x1A' }),
            '[' => return Ok(Code::Basic { character: '\x1B' }),
            '\\' => return Ok(Code::Basic { character: '\x1C' }),
            ']' => return Ok(Code::Basic { character: '\x1D' }),
            '^' => return Ok(Code::Basic { character: '\x1E' }),
            '_' => return Ok(Code::Basic { character: '\x1F' }),
            _ => bail!("Invalid CONTROL code '{code}'"),
        }
    }
    if character == 'O' {
        if let Some(character) = chars.next() {
            if character.is_ascii_uppercase() {
                return Ok(Code::Letter { control: true, letter: character });
            } else {
                bail!("Invalid ESC O code '{code}' is not UPPER case");
            }
        } else {
            bail!("Invalid ESC O code '{code}'");
        }
    }
    if character != '[' {
        bail!("Invalid ESC code '{code}' is not O or [");
    }
    let Some(character) = chars.next() else {
        bail!("Invalid ESC [ code '{code}' is too short");
    };
    if character.is_ascii_uppercase() {
        if chars.next().is_some() {
            bail!("Invalid ESC [ ALPHA code '{code}' is too long");
        }
        return Ok(Code::Letter { control: false, letter: character });
    }
    if !character.is_ascii_digit() {
        bail!("Invalid ESC [ code '{code}' is not ALPHA or DIGIT");
    }
    let mut tens = '0';
    let mut ones = character;
    let Some(mut character) = chars.next() else {
        bail!("Invalid ESC [ DIGIT code '{code}' is too short");
    };
    if character.is_ascii_digit() {
        if ones > '3' {
            bail!("Invalid ESC [ DIGIT code '{code}' is greater than 39");
        }
        tens = ones;
        ones = character;
        let Some(c) = chars.next() else {
            bail!("Invalid ESC [ DIGIT code '{code}' is too short");
        };
        character = c;
    }
    if character != '~' {
        bail!("Invalid ESC [ DIGIT code '{code}' does not end with '~'");
    }
    if let Some(_) = chars.next() {
        bail!("Invalid ESC [ DIGIT ~ code '{code}' is too long");
    }
    Ok(Code::Number { tens, ones })
}

fn key_code(rom: &ROM, verilog: &mut String) {
    verilog.push_str("`default_nettype none\n");
    verilog.push_str("`timescale 1ns / 1ps\n");
    verilog.push_str("module key_code\n");
    verilog.push_str("(\n");
    verilog.push_str("    input   wire        clk,\n");
    verilog.push_str("\n");
    verilog.push_str("    input   wire        ce,\n");
    verilog.push_str("\n");
    verilog.push_str("    input   wire        extended,\n");
    verilog.push_str("    input   wire [7:0]  scan_code,\n");
    verilog.push_str("    input   wire        num_lock,\n");
    verilog.push_str("    input   wire        control,\n");
    verilog.push_str("    input   wire        caps_lock,\n");
    verilog.push_str("    input   wire        shift,\n");
    verilog.push_str("\n");
    verilog.push_str("    output  logic [7:0] q\n");
    verilog.push_str(");\n");
    verilog.push_str("\n");
    verilog.push_str("    logic [13:0]    addr;\n");
    verilog.push_str("    wire [31:0]     block_3_q;\n");
    verilog.push_str("    wire [31:0]     block_2_q;\n");
    verilog.push_str("    wire [31:0]     block_1_q;\n");
    verilog.push_str("    wire [31:0]     block_0_q;\n");
    verilog.push_str("\n");
    verilog.push_str("    always_comb begin\n");
    verilog.push_str("        addr = {extended, scan_code, num_lock, control, caps_lock, shift, 1'b0};\n");
    verilog.push_str("        q = {block_3_q[1:0], block_2_q[1:0], block_1_q[1:0], block_0_q[1:0]};\n");
    verilog.push_str("    end\n");
    verilog.push_str("\n");
    for block in 0..4 {
        verilog.push_str("    pROM\n");
        verilog.push_str("    #(\n");
        verilog.push_str("        .READ_MODE(1'b0),\n");
        verilog.push_str("        .BIT_WIDTH(2),\n");
        verilog.push_str("        .RESET_MODE(\"SYNC\"");
        for row in 0..64 {
            verilog.push_str("),\n");
            let mut line = format!("        .INIT_RAM_{row:02X}(256'h");
            line.reserve(110);
            for col in (0..64).rev() {
                let addr = (row * 128) + (col * 2);
                let init = match block {
                    3 => {
                        let upper = rom[addr + 1] & 0b1100_0000;
                        let lower = rom[addr + 0] & 0b1100_0000;
                        (upper >> 4) | (lower >> 6)
                    },
                    2 => {
                        let upper = rom[addr + 1] & 0b0011_0000;
                        let lower = rom[addr + 0] & 0b0011_0000;
                        (upper >> 2) | (lower >> 4)
                    },
                    1 => {
                        let upper = rom[addr + 1] & 0b0000_1100;
                        let lower = rom[addr + 0] & 0b0000_1100;
                        (upper >> 0) | (lower >> 2)
                    },
                    0 => {
                        let upper = rom[addr + 1] & 0b0000_0011;
                        let lower = rom[addr + 0] & 0b0000_0011;
                        (upper << 2) | (lower >> 0)
                    },
                    _ => unreachable!(),
                };
                line.push(char::from_digit(init as u32, 16).expect("hex"));
            }
            verilog.push_str(&line);
        }
        verilog.push_str(")\n");
        verilog.push_str("    )\n");
        verilog.push_str(&format!("    block_{block}\n"));
        verilog.push_str("    (\n");
        verilog.push_str(&format!("        .DO(block_{block}_q),\n"));
        verilog.push_str("        .CLK(clk),\n");
        verilog.push_str("        .OCE(1'b1),\n");
        verilog.push_str("        .CE(ce),\n");
        verilog.push_str("        .RESET(1'b0),\n");
        verilog.push_str("        .AD(addr)\n");
        verilog.push_str("    );\n");
        verilog.push_str("\n");
    }
    verilog.push_str("\n");
    verilog.push_str("endmodule\n");
    verilog.push_str("\n");
    verilog.push_str("localparam  KEY_CODE_ESCAPE = 7;\n");
    verilog.push_str("localparam  KEY_CODE_NUMBER = 6;\n");
    verilog.push_str("localparam  KEY_CODE_TENS_HI = 5;\n");
    verilog.push_str("localparam  KEY_CODE_TENS_LO = 4;\n");
    verilog.push_str("localparam  KEY_CODE_ONES_HI = 3;\n");
    verilog.push_str("localparam  KEY_CODE_ONES_LO = 0;\n");
    verilog.push_str("localparam  KEY_CODE_BRACKET = 5;\n");
    verilog.push_str("localparam  KEY_CODE_LETTER_HI = 4;\n");
    verilog.push_str("localparam  KEY_CODE_LETTER_LO = 0;\n");
}
