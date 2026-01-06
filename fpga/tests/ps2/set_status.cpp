#include <cstdlib>
#include <ctime>
#include "common.h"

class Simulation: public SimulationBase {
public:
	Simulation(): SimulationBase() {};
	virtual ~Simulation() {};
	virtual void simulation() override;
};

void Simulation::simulation() {
	SCAN_CODE("NUM LOCK", 0x77);
	SCAN_CODE_handshake();

	COMMAND("SET STATUS", 0xED);
	SCAN_CODE("ACKNOWLEDGE", 0xFA);
	SCAN_CODE_handshake();

	COMMAND("all LEDS on", 0x07);
	SCAN_CODE("ACKNOWLEDGE", 0xFA);
	SCAN_CODE_handshake();

	cycles(FOR_1_ms);

	SCAN_CODE("RELEASED", 0xF0);
	SCAN_CODE_handshake();

	cycles(FOR_1_ms);

	SCAN_CODE("NUM LOCK", 0x77);
	SCAN_CODE_handshake();
}

int main(int argc, char **argv) {
	std::srand(std::time({}));

	Simulation simulation;
	simulation.start(argc, argv, "set_status.vcd");
	return 0;
}
