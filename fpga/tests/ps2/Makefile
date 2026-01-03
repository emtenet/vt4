
all: self_test.vcd reset.vcd

self_test.vcd: build/self_test
	build/self_test

build/self_test: ../../src/ps2.v self_test.cpp common.h
	verilator --build --cc --exe -o self_test --trace --Mdir build -I../../src -j ../../src/ps2.v self_test.cpp

reset.vcd: build/reset
	build/reset

build/reset: ../../src/ps2.v reset.cpp common.h
	verilator --build --cc --exe -o reset --trace --Mdir build -I../../src -j ../../src/ps2.v reset.cpp

.PHONY: all