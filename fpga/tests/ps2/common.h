#ifndef COMMON_H
#define COMMON_H

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vps2.h"

class SimulationBase {
public:
	SimulationBase();
	virtual ~SimulationBase();
	void start(int argc, char **argv, const char* waveform);
	virtual void simulation()=0;
protected:
	void cycle_initial();
	void cycle_final();
	void cycle();
	void cycles(int cycles);
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

void SimulationBase::ps2_cycle(CData data) {
	model->ps2_data_in = data;
	cycles(100);
	model->ps2_clk_in = 0;
	cycles(2100);
	model->ps2_clk_in = 1;
	cycles(2000);
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
	// cannot send commands whilst under RESET
	assert(model->command_ready == 0);

	cycles(10);
    model->reset_low = 1;
    cycle();
    // can NOW send commands after reset
    assert(model->command_ready == 1);

	cycles(10000);

	simulation();

	cycles(10000);

	cycle_final();
}

#endif