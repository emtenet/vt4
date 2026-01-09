#include "../simulation.h"
#include "Vtop_rx.h"

// UART at 115200 baud, cycles ~8.68us
#define	CYCLES_uart() cycles(CYCLES_ns(8680))

#define ASSERT_data_VALID(msg) \
	ASSERT_EQ("data is VALID " msg, model->data_valid, 1)
#define ASSERT_data_IS(msg, byte) \
	ASSERT_EQ("data IS " msg, model->data_byte, byte)
#define ASSERT_data_EMPTY(msg) \
	ASSERT_EQ("data EMPTY " msg, model->data_valid, 0)

class Simulation: public SimulationBase<Vtop_rx> {
public:
	Simulation(): SimulationBase() {};
	virtual ~Simulation() {};
	virtual void initialize() override;
	virtual void during_reset() override;
	virtual void after_reset() override;
	virtual void simulation() override;
	void pin_cycle(CData data);
};

void Simulation::pin_cycle(CData data) {
	model->pin = data;
	CYCLES_uart();
}

void Simulation::initialize() {
    model->pin = 1;
    model->data_ready = 0;
}

void Simulation::during_reset() {
	ASSERT_data_EMPTY("DURING reset");
}

void Simulation::after_reset() {
    ASSERT_data_EMPTY("AFTER reset");
}

void Simulation::simulation() {
	CData byte = bounded_rand(256);

	pin_cycle(0); // START bit
	for(int bits = 0; bits < 8; bits++) {
		CData bit = (byte >> bits) & 1;
		pin_cycle(bit);
	}
	model->pin = 1; // STOP bit

	ASSERT_data_EMPTY("at STOP bit");

	int stop_cycles = 0;
	while (model->data_valid == 0) {
		ASSERT_LT("stop TOO long", stop_cycles, CYCLES_ms(1));

		cycle();
		stop_cycles++;
	}

	ASSERT_data_VALID();
	ASSERT_data_IS("received", byte);

	CYCLES(100, us);

	model->data_ready = 1;
	cycle();
	ASSERT_data_EMPTY("after handshake");
	model->data_ready = 0;
}

int main(int argc, char **argv) {
	Simulation simulation;
	simulation.start(argc, argv, "uart_rx.vcd");
	return 0;
}
