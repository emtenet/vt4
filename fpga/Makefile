BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

VERILOG=top.v \
  char_rom.v \
  hdmi/hdmi.v \
  hdmi/hdmi_clk.v \
  hdmi/hdmi_encode.v \
  hdmi/hdmi_text_mode.v \
  hdmi/hdmi_timings.v \
  hdmi/hdmi_tmds.v \
  ps2.v \
  utility/clock_synchronizer.v \
  utility/button_handshake.v \
  utility/debouncer.v \
  utility/edge_detector.v \
  vram.v

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
