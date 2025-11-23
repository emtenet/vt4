BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

VERILOG=top.v char_rom.v vram.v vga.v vga_axis.v

all: build/bitstream.fs

build:
	mkdir build

build/synth.json: ${VERILOG} | build
	yosys -p "read_verilog ${VERILOG}; synth_gowin -top top -json build/synth.json"

build/pnr.json: build/synth.json | build
	nextpnr-himbaechel --json build/synth.json --freq 27 --write build/pnr.json --device ${DEVICE} --vopt family=${FAMILY} --vopt cst=${BOARD}.cst

build/bitstream.fs: build/pnr.json | build
	~/venv/bin/gowin_pack -d ${FAMILY} -o build/bitstream.fs build/pnr.json

sram: build/bitstream.fs
	sudo openFPGALoader -b ${BOARD} build/bitstream.fs

flash: build/bitstream.fs
	sudo openFPGALoader -b ${BOARD} build/bitstream.fs -f

.PHONY: all sram flash
INTERMEDIATE: build/synth.json build/pnr.json
