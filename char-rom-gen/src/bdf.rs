use anyhow::{
	bail,
	Context,
	Result,
};
use std::collections::HashMap;

pub struct Font {
	pub height: usize,
	pub width: usize,
	pub glyphs: HashMap<usize, Glyph>,
	pub blank: Glyph,
}

#[derive(Clone)]
pub struct Glyph {
	pub height: usize,
	pub width: usize,
	pub rows: Vec<usize>,
}

pub fn parse(lines: &str) -> Result<Font> {
	Font::parse(lines)
}

impl Font {
	fn parse(lines: &str) -> Result<Self> {
		let mut lines = Lines::new(&lines);
		let mut got_size = false;
		let mut height = 0usize;
		let mut width = 0usize;
		let mut glyphs = HashMap::new();

		lines.next()?;

		if lines.line != "STARTFONT 2.1" {
			bail!("Expecting 'STARTFONT 2.1' found '{}'", lines.line);
		}
		lines.next()?;

		// Global Font information
		loop {
			let Some((name, values)) = lines.line.split_once(' ') else {
				bail!("Expecting Global Font information, found '{}'", lines.line);
			};
			if name == "CHARS" {
				if !got_size {
					bail!("Missing 'FONTBOUNDINGBOX' before 'CHARS'");
				}
				lines.next()?;
				break;
			}
			if name == "FONTBOUNDINGBOX" {
				got_size = true;
				let mut values = values.split(' ');
				let Some(value) = values.next() else {
					bail!("Missing 'FONTBOUNDINGBOX' <width>");
				};
				width = value.parse().context("FONTBOUNDINGBOX <width>")?;
				let Some(value) = values.next() else {
					bail!("Missing 'FONTBOUNDINGBOX' <height>");
				};
				height = value.parse().context("FONTBOUNDINGBOX <height>")?;
				lines.next()?;
				continue;
			}
			if name == "STARTPROPERTIES" {
				lines.next()?;
				while !lines.line.starts_with("ENDPROPERTIES") {
					lines.next()?;
				}
				lines.next()?;
				continue;
			}
			// ignore
			lines.next()?;
		}

		// Characters / Glyphs
		loop {
			if lines.line.is_empty() {
				lines.next()?;
				continue;
			}
			if lines.line == "ENDFONT" {
				break;
			}
			let Some(("STARTCHAR", code_point)) = lines.line.split_once(' ') else {
				bail!("Expecting 'STARTCHAR' found '{}'", lines.line);
			};
			let Some(code_point) = code_point.strip_prefix("U+") else {
				bail!("Expecting STARTCHAR 'U+' found '{}'", code_point);
			};
			let code_point = u32::from_str_radix(code_point, 16).context("STARTCHAR")? as usize;
			let mut glyph = Glyph {
				width: 0,
				height: 0,
				rows: Vec::new(),
			};
			got_size = false;
			lines.next()?;
			while !lines.line.starts_with("BITMAP") {
				let Some((name, values)) = lines.line.split_once(' ') else {
					bail!("Expecting Global Font information, found '{}'", lines.line);
				};
				if name == "BBX" {
					got_size = true;
					let mut values = values.split(' ');
					let Some(value) = values.next() else {
						bail!("Missing 'BBX' <width>");
					};
					glyph.width = value.parse().context("BBX <width>")?;
					let Some(value) = values.next() else {
						bail!("Missing 'BBX' <height>");
					};
					glyph.height = value.parse().context("BBX <height>")?;
					lines.next()?;
					continue;
				}
				// ignore
				lines.next()?;
			}
			if !got_size {
				bail!("Missing 'BBX' before 'BITMAP'");
			}
			lines.next()?;
			for _ in 0..glyph.height {
				let wide = lines.line.len() * 4;
				if wide > usize::BITS as usize {
					bail!("BITMAP wider than usize, '{}'", lines.line);
				}
				if wide < glyph.width {
					bail!("BITMAP narrower than BBX {}, '{}'", glyph.width, lines.line);
				}
				let mut row = usize::from_str_radix(lines.line, 16).context("BITMAP")?;
				if wide > glyph.width {
					row >>= wide - glyph.width;
				}
				lines.next()?;
				glyph.rows.push(row);
			}
			if !lines.line.starts_with("ENDCHAR") {
				bail!("Expecing 'ENDCHAR', found '{}'", lines.line);
			}
			lines.next()?;
			glyphs.insert(code_point, glyph);
		}

		let mut blank = Glyph {
			width,
			height,
			rows: Vec::new(),
		};
		for _ in 0..height {
			blank.rows.push(0);
		}

		Ok(Font {
			width,
			height,
			glyphs,
			blank,
		})
	}

	pub fn glyph_add(&mut self, index: usize, mut rows: Vec<usize>) {
		rows.resize(self.height, 0);
		let mask = (1 << self.width) - 1;
		for row in rows.iter_mut() {
			*row &= mask;
		}
		self.glyphs.insert(index, Glyph {
			width: self.width,
			height: self.height,
			rows,
		});
	}

	pub fn glyph_copy(&mut self, from: usize, to: usize) {
		if let Some(glyph) = self.glyphs.get(&from) {
			let glyph = glyph.clone();
			self.glyphs.insert(to, glyph);
		}
	}

	pub fn glyph(&self, index: usize) -> Option<&Glyph> {
		self.glyphs.get(&index)
	}

	pub fn glyph_or_blank(&self, index: usize) -> &Glyph {
		if let Some(glyph) = self.glyphs.get(&index) {
			glyph
		} else {
			&self.blank
		}
	}
}

struct Lines<'a> {
	lines: std::str::Lines<'a>,
	line: &'a str,
}

impl<'a> Lines<'a> {
	fn new(str: &'a str) -> Self {
		Lines {
			lines: str.lines(),
			line: "",
		}
	}

	fn next(&mut self) -> Result<()> {
		if let Some(line) = self.lines.next() {
			self.line = line;
			Ok(())
		} else {
			bail!("Unexpected EOF");
		}
	}
}
