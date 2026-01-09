#include "simulation_ps2.h"

class Simulation: public SimulationPS2 {
public:
	Simulation(): SimulationPS2() {};
	virtual ~Simulation() {};
	virtual void simulation() override;
};

void Simulation::simulation() {
	SCAN_CODE("self test", 0xAA);

	CYCLES(100, us);

	SCAN_CODE_handshake();
}

int main(int argc, char **argv) {
	Simulation simulation;
	simulation.start(argc, argv, "self_test.vcd");
	return 0;
}
