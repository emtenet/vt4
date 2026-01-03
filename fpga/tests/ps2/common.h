#ifndef COMMON_H
#define COMMON_H

#include <verilated.h>
#include <verilated_vcd_c.h>
#include <stdio.h>
#include "Vps2.h"

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
	void cycle_initial();
	void cycle_final();
	void cycle();
	void cycles(int cycles);
	void ps2_cycle();
	void ps2_cycle(CData data);
protected:
	std::unique_ptr<VerilatedContext> cx;
	std::unique_ptr<VerilatedVcdC> trace;
    std::unique_ptr<Vps2> model;
};

SimulationBase::SimulationBase()
	: cx{}
	, trace{}
    , model{}
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
#define ASSERT_data_DRIVEN(msg) \
	ASSERT_EQ("host DRIVING data " msg, model->ps2_data_oe, 1)
#define ASSERT_data_IS(msg, data) \
	ASSERT_EQ("host DATA driven IS " msg, model->ps2_data_out, data)
#define ASSERT_data_RELEASED(msg) \
	ASSERT_EQ("host RELEASED data " msg, model->ps2_data_oe, 0)
#define ASSERT_scan_code_VALID(msg) \
	ASSERT_EQ("scan code is VALID " msg, model->scan_code_valid, 1)
#define ASSERT_scan_code_EQ(scan_code) \
	ASSERT_EQ("scan code EXPECTED", model->scan_code_data, scan_code)
#define ASSERT_scan_code_TAKEN(msg) \
	ASSERT_EQ("scan code TAKEN " msg, model->scan_code_valid, 0)

void SimulationBase::assert_eq(const char* message, int lhs, int rhs, const char* expr, const char* file, int line) {
	printf("ASSERTION FAILED in %s:%d\n", file, line);
	printf("    %s\n", message);
	printf("    %s\n", expr);
	printf("    LHS = %d\n", lhs);
	printf("    RHS = %d\n", rhs);

	cycles(FOR_100_us);

	cycle_final();

    model->final();
    trace->close();
	exit(1);
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

void SimulationBase::ps2_cycle() {
	cycles(PS2_SETUP_CYCLES);
	model->ps2_clk_in = 0;
	cycles(PS2_HALF_CYCLES);
	model->ps2_clk_in = 1;
	cycles(PS2_HALF_CYCLES - PS2_SETUP_CYCLES);
}

void SimulationBase::ps2_cycle(CData data) {
	model->ps2_data_in = data;
	ps2_cycle();
}

void SimulationBase::start(int argc, char **argv, const char* waveform) {
	cx.reset(new VerilatedContext);

	cx->traceEverOn(true);
    cx->commandArgs(argc, argv);

    // 10ns per half cycle ~ 50MHz
    cx->timeprecision(-8);

    trace.reset(new VerilatedVcdC);

    model.reset(new Vps2{cx.get(), "TOP"});
    model->trace(trace.get(), 1);

    trace->open(waveform);

	model->reset_low = 0;
	model->ps2_clk_in = 1;
	model->ps2_data_in = 1;

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