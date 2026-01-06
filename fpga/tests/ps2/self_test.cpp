#include "common.h"

class Simulation: public SimulationBase {
public:
	Simulation(): SimulationBase() {};
	virtual ~Simulation() {};
	virtual void simulation() override;
};

void Simulation::simulation() {
	SCAN_CODE("self test", 0xAA);

	cycles(FOR_100_us);

	SCAN_CODE_handshake();
}

int main(int argc, char **argv) {
	Simulation simulation;
	simulation.start(argc, argv, "self_test.vcd");
	return 0;
}
