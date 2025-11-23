# Backlight enable (Tang Nano 9k)

The LCD backlight can be enabled/disabled via PIN 86 with a little bit of soldering.

The LCD backlight driver's enable pin is wired up to pin 86 via an unpopulated resistor `R24`.
![R24 in backlight schematic](/docs/tangnano9k-backlight-schematic.png)

Make that useable by soldering in a short or 0ohm resistor across the pads of `R24`.
![R24 location on PCB](/docs/tangnano9k-backlight-drawing.png)

Add pin 86 to the `CST` file as an open-drain output (pull to GND when outputing a zero):
```
IO_LOC "lcd_backlight" 86;
IO_PORT "lcd_backlight" IO_TYPE=LVCMOS18 PULL_MODE=NONE OPEN_DRAIN=ON;
```
Assign `1` to `lcd_backlight` to enable and `0` to disbale.
