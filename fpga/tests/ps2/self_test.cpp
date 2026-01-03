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
	ASSERT_command_BUSY("whilst RECEIVING");
	ps2_cycle(0); // bit 0
	ps2_cycle(1);
	ps2_cycle(0);
	ps2_cycle(1);
	ps2_cycle(0);
	ps2_cycle(1);
	ps2_cycle(0);
	ps2_cycle(1); // bit 7
	ps2_cycle(1); // parity (odd)
	ps2_cycle(1); // stop

	ASSERT_scan_code_VALID();
	ASSERT_scan_code_EQ(0xAA);

	ASSERT_command_READY("after RECEIVING");

	cycles(FOR_100_us);

	model->scan_code_ready = 1;
	cycle();
	ASSERT_scan_code_TAKEN("with handshake");
}

int main(int argc, char **argv) {
	Simulation simulation;
	simulation.start(argc, argv, "self_test.vcd");
	return 0;
}
