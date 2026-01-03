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
	model->command_data = 0xFF; // RESET
	model->command_valid = 1;
	cycle();
	ASSERT_command_BUSY("until this one completes");
	model->command_data = 0;
	model->command_valid = 0;

	// Host to Keyboard request with CLK pulled LOW
	ASSERT_clk_DRIVEN("for REQUEST to send");
	ASSERT_clk_IS("REQUEST to send", 0);

	int request_cycles = 0;
	while (model->ps2_clk_oe == 1) {
		ASSERT_clk_IS("REQUEST to send", 0);
		// only need to request for 100us, bail at 1ms
		assert(request_cycles < FOR_1_ms);

		cycle();
		request_cycles++;
	}

	// request at least for 100us
	assert(request_cycles >= FOR_100_us);

	ASSERT_data_DRIVEN("for REQUEST to send");
	ASSERT_data_IS("REQUEST to send", 0);

	// Delay before keyboard starts clocking
	cycles(FOR_1_us + bounded_rand(FOR_100_us));

	// START bit
	ASSERT_data_DRIVEN("for START bit");
	ASSERT_data_IS("START bit", 0);

	CData command = 0;
	CData parity = 0;

	for (int bits = 0; bits < 8; bits++) {
		// DATA bit
		ps2_cycle();
		ASSERT_data_DRIVEN("for DATA bits");
		CData bit = model->ps2_data_out & 1;
		command = (bit << 7) | (command >> 1);
		parity ^= bit;
	}

	ASSERT_EQ("sent RESET", command, 0xFF);

	// PARITY bit
	ps2_cycle();
	ASSERT_data_DRIVEN("for PARITY bit");
	CData bit = model->ps2_data_out & 1;
	parity ^= bit;

	ASSERT_EQ("parity is ODD", parity, 1);

	// STOP bit
	ps2_cycle();
	ASSERT_data_RELEASED("for STOP bit");

	// ACK bit
	ps2_cycle(0);
	model->ps2_data_in = 1;
	cycle();

	ASSERT_command_READY("after SENDING");

	cycles(FOR_100_us);

	// PS/2 frame (self test = FA)
	ps2_cycle(0); // start
	ASSERT_command_BUSY("whilst RECEIVING");
	ps2_cycle(0); // bit 0
	ps2_cycle(1);
	ps2_cycle(0);
	ps2_cycle(1);
	ps2_cycle(1);
	ps2_cycle(1);
	ps2_cycle(1);
	ps2_cycle(1); // bit 7
	ps2_cycle(1); // parity (odd)
	ps2_cycle(1); // stop

	ASSERT_scan_code_VALID("after RECEIVING");
	ASSERT_scan_code_IS("acknowledge", 0xFA);

	ASSERT_command_READY("after RECEIVING");

	cycles(FOR_10_us);

	model->scan_code_ready = 1;
	cycle();
	ASSERT_scan_code_TAKEN("with handshake");
	model->scan_code_ready = 0;

	cycles(FOR_1_ms);

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

	ASSERT_scan_code_VALID("after RECEIVING");
	ASSERT_scan_code_IS("self test", 0xAA);

	ASSERT_command_READY("after RECEIVING");

	cycles(FOR_100_us);

	model->scan_code_ready = 1;
	cycle();
	ASSERT_scan_code_TAKEN("with handshake");
	model->scan_code_ready = 0;
}

int main(int argc, char **argv) {
	std::srand(std::time({}));

	Simulation simulation;
	simulation.start(argc, argv, "reset.vcd");
	return 0;
}
