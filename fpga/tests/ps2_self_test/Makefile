
run: build/Vps2
	build/Vps2

build/Vps2: ../../src/ps2.v ps2_self_test.cpp
	verilator --cc --exe --build --trace --Mdir build -I../../src -j $^

.PHONY: run