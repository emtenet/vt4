 TODO
======

 PCB
-----

DONE: Switch to Female DSub 9-pin connector footprint

  GND      TX  RX
  (5) (4) (3) (2) (1)

    (9) (8) (7) (6)

DONE: Handsolder pads on USB-C connector / MAX2323 / FeRAM

DONE: Correct UART 1 & 2 pins on FPGA

DONE: Move PS/2 connector away from HDMI cable runway

 FPGA
------

## Escape Sequences

Escape Sequence `^[[11C` (CUF) "Cursor Forward"

 * Moves cursor right Pn columns. Cursor stops at right margin.

Escape Sequence `^[[K` or `^[[0K` (EL) "Erase In Line"

 * Erases from cursor to end of line, including cursor position.


# Cursor Positioning

The cursor indicates the active screen position where the next character will appear.

The cursor moves:
 * One column to the right when a character appears
 * One line down after a linefeed (LF, octal 012), form feed (FF, octal 014)
   or vertical tab (VT, octal 013)
   (Linefeed/new line may also move the cursor to the left margin)
 * To the left margin after a carriage return (CR, octal 015)
 * One column to the left after a backspace (BS, octal 010)
 * To the next tab stop (or right margin if no tabs are set)
   after a horizontal tab character (HT, octal 011)
 * To the home position when the
   top and bottom margins of the scrolling region (DECSTBM)
   or origin mode (DECOM)
   selection changes.
