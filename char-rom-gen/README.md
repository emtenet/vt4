# vt4

## char-rom-gen

Generate Verilog source containing a 10x20 character ROM.

Based on the 10x20 Tamzen font:

 * [BDF file](https://github.com/sunaku/tamzen-font/blob/master/bdf/Tamzen10x20r.bdf)
 * [BDF format](https://en.wikipedia.org/wiki/Glyph_Bitmap_Distribution_Format)

Run `make` from this directory.

## Address layout

The needs to be a 256 x 20 x 10 bit array (50Kbit) mapped onto 16/18Kbit BSRAM blocks.

The 10 bit width will waste a 1K x 16/18bit block, and a 2K x 8/9bit block is not wide enough. Build the width from 2bit + 8bit.

Want to address 256 x 20 rows (5K rows, 0..13FF). A 8K x 2bit block takes care of the short side. The long side will need three 2K x 8bit blocks.

In total use 4 BSRAM blocks.

```
    output | 9 8 | 7 6 5 4 3 2 1 0 |
address    |=====|=================|
0000..03FF |     |                 |
0400..07FF |     |                 |
           |     |-----------------|
0800..0BFF |     |                 |
0C00..0FFF |     |                 |
           |     |-----------------|
1000..13FF |     |                 |
1400..17FF | ### | ############### | unused
           |     |-----------------|
1800..1BFF | ### |
1C00..1FFF | ### |
           |-----|
```

