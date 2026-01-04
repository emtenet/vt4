BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

VERILOG=src/top.v \
src/button_handshake.v \
src/char_rom.v \
src/character_writer.v \
src/clock_synchronizer.v \
src/debouncer.v \
src/edge_detector.v \
src/hdmi.v \
src/hdmi_clk.v \
src/hdmi_encode.v \
src/hdmi_text_mode.v \
src/hdmi_timings.v \
src/hdmi_tmds.v \
src/ps2.v \
src/vram.v

all: build/bitstream.fs

build:
	mkdir build

build/synth.json: ${VERILOG} | build
	yosys -p "read_verilog ${VERILOG}; synth_gowin -top top -json build/synth.json"

build/pnr.json: build/synth.json top.cst | build
	nextpnr-himbaechel --json build/synth.json --freq 27 --write build/pnr.json --device ${DEVICE} --vopt family=${FAMILY} --vopt cst=top.cst

build/bitstream.fs: build/pnr.json | build
	~/venv/bin/gowin_pack -d ${FAMILY} -o build/bitstream.fs build/pnr.json

sram: build/bitstream.fs
	sudo openFPGALoader -b ${BOARD} build/bitstream.fs

flash: build/bitstream.fs
	sudo openFPGALoader -b ${BOARD} build/bitstream.fs -f

lint: ${VERILOG}
	verilator -lint-only -Wall ${VERILOG}

.PHONY: all sram flash lint
INTERMEDIATE: build/synth.json build/pnr.json
