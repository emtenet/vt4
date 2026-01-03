
all: self_test.vcd

self_test.vcd: build/self_test
	build/self_test

build/self_test: ../../src/ps2.v self_test.cpp common.h
	verilator --build --cc --exe -o self_test --trace --Mdir build -I../../src -j ../../src/ps2.v self_test.cpp

.PHONY: all