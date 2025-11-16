mod bdf;

fn main() -> anyhow::Result<()> {
    let font = bdf::read("Tamzen10x20r.bdf")?;

    assert_eq!(font.width, 10);
    assert_eq!(font.height, 20);
    for (_code_point, glyph) in font.glyphs {
        assert_eq!(glyph.width, font.width);
        assert_eq!(glyph.height, font.height);
    }

    Ok(())
}
