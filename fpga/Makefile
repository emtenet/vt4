BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

VERILOG= src/types.sv \
src/button_handshake.sv \
src/char_rom.sv \
src/character_writer.sv \
src/clock_synchronizer.sv \
src/debouncer.sv \
src/edge_detector.sv \
src/hdmi.sv \
src/hdmi_clk.sv \
src/hdmi_encode.sv \
src/hdmi_text_mode.sv \
src/hdmi_timings.sv \
src/hdmi_tmds.sv \
src/key_code.sv \
src/ps2.sv \
src/ps2_protocol.sv \
src/ps2_state.sv \
src/timer.sv \
src/top.sv \
src/vram.sv

all: build/bitstream.fs

build:
	mkdir build

build/synth.json: ${VERILOG} | build
	yosys -p "read_verilog -sv ${VERILOG}; synth_gowin -top top -json build/synth.json"

build/pnr.json: build/synth.json top.cst | build
	nextpnr-himbaechel --json build/synth.json --freq 27 --write build/pnr.json --device ${DEVICE} --vopt family=${FAMILY} --vopt cst=top.cst

build/bitstream.fs: build/pnr.json | build
	~/venv/bin/gowin_pack -d ${FAMILY} -o build/bitstream.fs build/pnr.json

sram: build/bitstream.fs
	sudo openFPGALoader -b ${BOARD} build/bitstream.fs

flash: build/bitstream.fs
	sudo openFPGALoader -b ${BOARD} build/bitstream.fs -f

lint: ${VERILOG}
	verilator -lint-only -Wall -Isrc ${VERILOG}

.PHONY: all sram flash lint
INTERMEDIATE: build/synth.json build/pnr.json
