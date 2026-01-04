
all: self_test.vcd reset.vcd

VERILOG=../../src/types.sv ../../src/ps2.sv
VERILATOR=verilator --build --cc --exe --trace --Mdir build -I../../src --top ps2

self_test.vcd: build/self_test
	build/self_test

build/self_test: ${VERILOG} self_test.cpp
	${VERILATOR} -o self_test $^

reset.vcd: build/reset
	build/reset

build/reset: ${VERILOG} reset.cpp
	${VERILATOR} -o reset $^

.PHONY: all