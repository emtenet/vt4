
.PHONY: all
all: self_test.vcd reset.vcd set_status.vcd

VERILOG=../../src/types.sv ../../src/ps2_protocol.sv
VERILATOR=verilator --build --cc --exe --trace --Mdir build -I../../src --top ps2_protocol

self_test.vcd: build/self_test
	build/self_test

build/self_test: ${VERILOG} self_test.cpp common.h
	${VERILATOR} -o self_test ${VERILOG} self_test.cpp

reset.vcd: build/reset
	build/reset

build/reset: ${VERILOG} reset.cpp common.h
	${VERILATOR} -o reset ${VERILOG} reset.cpp

set_status.vcd: build/set_status
	build/set_status

build/set_status: ${VERILOG} set_status.cpp common.h
	${VERILATOR} -o set_status ${VERILOG} set_status.cpp
