#include "common.h"

class Simulation: public SimulationBase {
public:
	Simulation(): SimulationBase() {};
	virtual ~Simulation() {};
	virtual void simulation() override;
};

void Simulation::simulation() {
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
}

int main(int argc, char **argv) {
	Simulation simulation;
	simulation.start(argc, argv, "self_test.vcd");
	return 0;
}
