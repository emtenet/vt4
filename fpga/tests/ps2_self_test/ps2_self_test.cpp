#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vps2.h"

class Simulation {
public:
	Simulation(int argc, char **argv);
	~Simulation();
	void cycle_initial();
	void cycle_final();
	void cycle();
	void cycles(int cycles);
	void ps2_cycle(CData data);
	void run();
private:
	std::unique_ptr<VerilatedContext> cx;
	std::unique_ptr<VerilatedVcdC> trace;
    std::unique_ptr<Vps2> model;
};

Simulation::Simulation(int argc, char **argv)
	: cx{new VerilatedContext}
	, trace{}
    , model{}
{
	cx->traceEverOn(true);
    cx->commandArgs(argc, argv);

    // 10ns per half cycle ~ 50MHz
    cx->timeprecision(-8);

    trace.reset(new VerilatedVcdC);

    model.reset(new Vps2{cx.get(), "TOP"});
    model->trace(trace.get(), 1);

    trace->open("waveform.vcd");
}

Simulation::~Simulation() {
    model->final();
    trace->close();
}

void Simulation::cycle_initial() {
	model->clk = 1;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

void Simulation::cycle_final() {
	model->clk = 0;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

void Simulation::cycle() {
	model->clk = 0;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);

	model->clk = 1;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

void Simulation::cycles(int cycles) {
    for (int cycle=0; cycle<cycles; cycle++) {
    	this->cycle();
    }
}

void Simulation::ps2_cycle(CData data) {
	model->ps2_data_in = data;
	cycles(100);
	model->ps2_clk_in = 0;
	cycles(2100);
	model->ps2_clk_in = 1;
	cycles(2000);
}

void Simulation::run() {
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

	// PS/2 frame (self test = AA)
	ps2_cycle(0); // start
	// cannot send commands whilst RECEIVING
	assert(model->command_ready == 0);
	ps2_cycle(0); // bit 0
	ps2_cycle(1);
	ps2_cycle(0);
	ps2_cycle(1);
	ps2_cycle(0);
	ps2_cycle(1);
	ps2_cycle(0);
	ps2_cycle(1); // bit 6
	ps2_cycle(1); // parity (odd)
	ps2_cycle(1); // stop

	// scan_code VALID
	assert(model->scan_code_valid == 1);
	assert(model->scan_code_data == 0xAA);

	// can NOW send commands after RECEIVING
	assert(model->command_ready == 1);

	cycles(10000);

	model->scan_code_ready = 1;
	cycle();
	// scan_code HANDSHAKE
	assert(model->scan_code_valid == 0);

	cycles(10000);

	cycle_final();
}

int main(int argc, char **argv) {
	Verilated::mkdir("logs");
	Simulation simulation(argc, argv);
	simulation.run();
	return 0;
}