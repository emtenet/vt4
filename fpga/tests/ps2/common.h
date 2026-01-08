#ifndef COMMON_H
#define COMMON_H

#include <verilated.h>
#include <verilated_vcd_c.h>
#include <stdio.h>
#include "Vps2_protocol.h"

#define  FOR_20_ns	1
#define FOR_100_ns	5
#define   FOR_1_us  50
#define  FOR_10_us  500
#define FOR_100_us  5000
#define   FOR_1_ms  50000

// PS/2 clock 11.9kHz (10kHz .. 16.7kHz)
// cycle period ~ 84us
#define PS2_HALF_CYCLES		(42 * FOR_1_us)
#define PS2_SETUP_CYCLES	(4 * FOR_1_us)

unsigned bounded_rand(unsigned range)
{
    for (unsigned x, r;;)
        if (x = std::rand(), r = x % range, x - r <= -range)
            return r;
}

class SimulationBase {
public:
	SimulationBase();
	virtual ~SimulationBase();
	void start(int argc, char **argv, const char* waveform);
	virtual void simulation()=0;
protected:
	void assert_eq(const char* message, int lhs, int rhs, const char* expr, const char* file, int line);
	void assert_lt(const char* message, const char* expr, const char* file, int line);
	void cycle_initial();
	void cycle_final();
	void cycle();
	void cycles(int cycles);
	void ps2_rx_cycle();
	void ps2_rx_cycle_ack();
	void ps2_tx_cycle(CData data);
	void command_rx(CData command, const char* file, int line);
	void command_ack_handshake(const char* file, int line);
	void scan_code_tx(CData scan_code, const char* file, int line);
	void scan_code_handshake(const char* file, int line);
protected:
	std::unique_ptr<VerilatedContext> cx;
	std::unique_ptr<VerilatedVcdC> trace;
    std::unique_ptr<Vps2_protocol> model;
private:
	void assert_start(const char* message, const char* expr, const char* file, int line);
	void assert_end();
	void assert_push(const char* file, int line);
	void assert_pop();
private:
	const char* assert_file;
	int assert_line;
};

SimulationBase::SimulationBase()
	: cx{}
	, trace{}
    , model{}
	, assert_file(nullptr)
	, assert_line(0)
{
}

SimulationBase::~SimulationBase() {
    model->final();
    trace->close();
}

#define ASSERT_EQ(message, lhs, rhs) \
	if ((lhs) != (rhs)) { \
		assert_eq(message, lhs, rhs, #lhs " == " #rhs, __FILE__, __LINE__); \
	}
#define ASSERT_LT(message, lhs, rhs) \
	if ((lhs) >= (rhs)) { \
		assert_lt(message, #lhs " < " #rhs, __FILE__, __LINE__); \
	}
#define ASSERT_clk_DRIVEN(msg) \
	ASSERT_EQ("host DRIVING clk " msg, model->ps2_clk_oe, 1)
#define ASSERT_clk_IS(msg, clk) \
	ASSERT_EQ("host CLK driven IS " msg, model->ps2_clk_out, clk)
#define ASSERT_clk_RELEASED(msg) \
	ASSERT_EQ("host RELEASED clk " msg, model->ps2_clk_oe, 0)
#define ASSERT_command_BUSY(msg) \
	ASSERT_EQ("CANNOT send a command " msg, model->command_ready, 0)
#define ASSERT_command_READY(msg) \
	ASSERT_EQ("CAN send a command " msg, model->command_ready, 1)
#define ASSERT_command_ack_OK(msg) \
	ASSERT_EQ("command ack OK " msg, model->command_ack_error, 0)
#define ASSERT_command_ack_EMPTY(msg) \
	ASSERT_EQ("command ack EMPTY " msg, model->command_ack_valid, 0)
#define ASSERT_data_DRIVEN(msg) \
	ASSERT_EQ("host DRIVING data " msg, model->ps2_data_oe, 1)
#define ASSERT_data_IS(msg, data) \
	ASSERT_EQ("host DATA driven IS " msg, model->ps2_data_out, data)
#define ASSERT_data_RELEASED(msg) \
	ASSERT_EQ("host RELEASED data " msg, model->ps2_data_oe, 0)
#define ASSERT_scan_code_VALID(msg) \
	ASSERT_EQ("scan code is VALID " msg, model->scan_code_valid, 1)
#define ASSERT_scan_code_IS(msg, scan_code) \
	ASSERT_EQ("scan code IS " msg, model->scan_code_byte, scan_code)
#define ASSERT_scan_code_EMPTY(msg) \
	ASSERT_EQ("scan code EMPTY " msg, model->scan_code_valid, 0)
#define COMMAND(msg, command) \
	command_rx(command, __FILE__, __LINE__)
#define COMMAND_ACK_handshake() \
	command_ack_handshake(__FILE__, __LINE__)
#define SCAN_CODE(msg, scan_code) \
	scan_code_tx(scan_code, __FILE__, __LINE__)
#define SCAN_CODE_handshake() \
	scan_code_handshake(__FILE__, __LINE__)

void SimulationBase::assert_eq(const char* message, int lhs, int rhs, const char* expr, const char* file, int line) {
	assert_start(message, expr, file, line);
	printf("    LHS = %d\n", lhs);
	printf("    RHS = %d\n", rhs);
	assert_end();
}

void SimulationBase::assert_lt(const char* message, const char* expr, const char* file, int line) {
	assert_start(message, expr, file, line);
	assert_end();
}

void SimulationBase::assert_start(const char* message, const char* expr, const char* file, int line) {
	printf("ASSERTION FAILED\n");
	if (assert_file) {
		printf("    @ %s:%d\n", assert_file, assert_line);
	}
	printf("    @ %s:%d\n", file, line);
	printf("    %s\n", message);
	printf("    %s\n", expr);
}

void SimulationBase::assert_end() {
	cycle_final();

    model->final();
    trace->close();
	exit(1);
}

void SimulationBase::assert_push(const char* file, int line) {
	assert_file = file;
	assert_line = line;
}

void SimulationBase::assert_pop() {
	assert_file = nullptr;
	assert_line = 0;
}

void SimulationBase::cycle_initial() {
	model->clk = 1;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

void SimulationBase::cycle_final() {
	model->clk = 0;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

void SimulationBase::cycle() {
	model->clk = 0;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);

	model->clk = 1;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

void SimulationBase::cycles(int cycles) {
    for (int cycle=0; cycle<cycles; cycle++) {
    	this->cycle();
    }
}

void SimulationBase::ps2_rx_cycle() {
	cycles(PS2_SETUP_CYCLES);
	model->ps2_clk_in = 0;
	cycles(PS2_HALF_CYCLES);
	model->ps2_clk_in = 1;
	cycles(PS2_HALF_CYCLES - PS2_SETUP_CYCLES);
}

void SimulationBase::ps2_rx_cycle_ack() {
	model->ps2_data_in = 0;
	cycles(PS2_SETUP_CYCLES);
	model->ps2_clk_in = 0;
	cycles(PS2_HALF_CYCLES);
	model->ps2_clk_in = 1;
	model->ps2_data_in = 1;
}

void SimulationBase::ps2_tx_cycle(CData data) {
	model->ps2_data_in = data;
	cycles(PS2_SETUP_CYCLES);
	model->ps2_clk_in = 0;
	cycles(PS2_HALF_CYCLES);
	model->ps2_clk_in = 1;
	cycles(PS2_HALF_CYCLES - PS2_SETUP_CYCLES);
}

void SimulationBase::command_rx(CData command, const char* file, int line) {
	assert_push(file, line);

	model->command_byte = command;
	model->command_valid = 1;
	model->command_ack_ready = 1;
	cycle();
	ASSERT_command_BUSY("until this one completes");
	model->command_byte = 0;
	model->command_valid = 0;

	// Host to Keyboard request with CLK pulled LOW
	ASSERT_clk_DRIVEN("for REQUEST to send");
	ASSERT_clk_IS("REQUEST to send", 0);

	int request_cycles = 0;
	while (model->ps2_clk_oe == 1) {
		ASSERT_clk_IS("REQUEST to send", 0);
		ASSERT_LT("request TOO long", request_cycles, FOR_1_ms);

		cycle();
		request_cycles++;
	}

	ASSERT_LT("request for at least 100us", FOR_100_us, request_cycles);

	ASSERT_data_DRIVEN("for REQUEST to send");
	ASSERT_data_IS("REQUEST to send", 0);

	// Delay before keyboard starts clocking
	cycles(FOR_1_us + bounded_rand(FOR_100_us));

	// START bit
	ASSERT_data_DRIVEN("for START bit");
	ASSERT_data_IS("START bit", 0);

	CData rx_command = 0;
	CData rx_parity = 0;

	for (int bits = 0; bits < 8; bits++) {
		// DATA bit
		ps2_rx_cycle();
		ASSERT_data_DRIVEN("for DATA bits");
		CData bit = model->ps2_data_out & 1;
		rx_command = (bit << 7) | (rx_command >> 1);
		rx_parity ^= bit;
	}

	ASSERT_EQ("sent COMMAND", rx_command, command);

	// PARITY bit
	ps2_rx_cycle();
	ASSERT_data_DRIVEN("for PARITY bit");
	CData bit = model->ps2_data_out & 1;
	rx_parity ^= bit;

	ASSERT_EQ("parity is ODD", rx_parity, 1);

	// STOP bit
	ps2_rx_cycle();
	ASSERT_data_RELEASED("for STOP bit");

	// ACK bit
	ps2_tx_cycle(0);

	ASSERT_command_BUSY("after ACK bit");
	ASSERT_command_ack_EMPTY("before ACK wait");

	int ack_cycles = 0;
	while (model->command_ack_valid == 0) {
		ASSERT_LT("ack TOO long", ack_cycles, FOR_1_ms);

		cycle();
		ack_cycles++;
	}
	ASSERT_command_ack_OK("after SENDING");
	ASSERT_command_READY("after SENDING");

	cycle();
	ASSERT_command_ack_EMPTY("after ACK handshake");
	model->command_ack_ready = 0;

	assert_pop();
}

void SimulationBase::scan_code_tx(CData scan_code, const char* file, int line) {
	assert_push(file, line);

	// PS/2 frame
	ps2_tx_cycle(0); // START bit
	ASSERT_command_BUSY("after START bit");
	CData parity = 1;
	for(int bits = 0; bits < 8; bits++) {
		CData bit = (scan_code >> bits) & 1;
		parity ^= bit;
		ps2_tx_cycle(bit);
	}
	ps2_tx_cycle(parity);
	ps2_tx_cycle(1); // STOP bit

	ASSERT_command_BUSY("after STOP bit");
	ASSERT_scan_code_EMPTY("after STOP bit");

	int stop_cycles = 0;
	while (model->scan_code_valid == 0) {
		ASSERT_LT("stop TOO long", stop_cycles, FOR_1_ms);

		cycle();
		stop_cycles++;
	}

	ASSERT_scan_code_VALID();
	ASSERT_scan_code_IS("received", scan_code);
	ASSERT_command_READY("after SCAN CODE");

	assert_pop();
}

void SimulationBase::scan_code_handshake(const char* file, int line) {
	assert_push(file, line);

	ASSERT_scan_code_VALID();

	model->scan_code_ready = 1;
	cycle();
	ASSERT_scan_code_EMPTY("after handshake");
	model->scan_code_ready = 0;

	assert_pop();
}

void SimulationBase::start(int argc, char **argv, const char* waveform) {
	cx.reset(new VerilatedContext);

	cx->traceEverOn(true);
    cx->commandArgs(argc, argv);

    // 10ns per half cycle ~ 50MHz
    cx->timeprecision(-8);

    trace.reset(new VerilatedVcdC);

    model.reset(new Vps2_protocol{cx.get(), "TOP"});
    model->trace(trace.get(), 1);

    trace->open(waveform);

	model->reset_low = 0;
	model->ps2_clk_in = 1;
	model->ps2_data_in = 1;
	model->command_valid = 0;
	model->command_ack_ready = 0;
	model->scan_code_ready = 0;

	cycle_initial();
	ASSERT_command_BUSY("whilst under RESET");

	cycles(FOR_100_ns);
    model->reset_low = 1;
    cycle();
    ASSERT_command_READY("after reset");

	cycles(FOR_100_us);

	simulation();

	cycles(FOR_100_us);

	cycle_final();
}

#endif