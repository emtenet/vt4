
.PHONY: all
all: uart_rx.vcd uart_tx.vcd

VERILOG=../../src/types.sv ../../src/uart_rx.sv ../../src/uart_tx.sv
VERILATOR=verilator --build --cc --exe --trace --Mdir build -I../../src

uart_rx.vcd: build/uart_rx ALWAYS
	build/uart_rx

build/uart_rx: ${VERILOG} uart_rx.cpp top_rx.sv ../simulation_base.h
	${VERILATOR} --top top_rx -o uart_rx ${VERILOG} uart_rx.cpp top_rx.sv

uart_tx.vcd: build/uart_tx ALWAYS
	build/uart_tx

build/uart_tx: ${VERILOG} uart_tx.cpp top_tx.sv ../simulation_base.h
	${VERILATOR} --top top_tx -o uart_tx ${VERILOG} uart_tx.cpp top_tx.sv

.PHONY: ALWAYS
ALWAYS: