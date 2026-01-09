#include "../simulation.h"
#include "Vtop_tx.h"

// UART at 115200 baud, cycles ~8.68us
#define	CYCLES_full() cycles(CYCLES_ns(8680))
#define	CYCLES_half() cycles(CYCLES_ns(8680))

#define ASSERT_data_BUSY(msg) \
	ASSERT_EQ("CANNOT send data " msg, model->data_ready, 0)
#define ASSERT_data_READY(msg) \
	ASSERT_EQ("CAN send data " msg, model->data_ready, 1)
#define ASSERT_pin_IS(msg, is) \
	ASSERT_EQ("pin IS " msg, model->pin, is)

class Simulation: public SimulationBase<Vtop_tx> {
public:
	Simulation(): SimulationBase() {};
	virtual ~Simulation() {};
	virtual void initialize() override;
	virtual void during_reset() override;
	virtual void after_reset() override;
	virtual void simulation() override;
	void pin_cycle(CData data);
};

void Simulation::initialize() {
    model->data_valid = 0;
    model->data_byte = 0;
}

void Simulation::during_reset() {
	ASSERT_data_BUSY("DURING reset");
	ASSERT_pin_IS("DURING reset", 1);
}

void Simulation::after_reset() {
    ASSERT_data_READY("AFTER reset");
    ASSERT_pin_IS("AFTER reset", 1);
}

void Simulation::simulation() {
	CData tx_byte = bounded_rand(256);

    model->data_valid = 1;
    model->data_byte = tx_byte;
    cycle();
    ASSERT_data_BUSY("AFTER handshake");

	int start_cycles = 0;
	while (model->pin == 1) {
		ASSERT_LT("start TOO long", start_cycles, CYCLES_ms(1));

		cycle();
		start_cycles++;
	}
    model->data_valid = 0;
    model->data_byte = 0;

	CYCLES_half(); // START bit

	CData rx_byte = 0;
	for (int bits = 0; bits < 8; bits++) {
		CYCLES_full();
		CData bit = model->pin & 1;
		rx_byte |= bit << bits;
	}

	CYCLES_full();
	ASSERT_pin_IS("STOP bit", 1);
	ASSERT_EQ("DATA", tx_byte, rx_byte);

	// back to back transmit
	tx_byte = ~tx_byte;
    model->data_valid = 1;
    model->data_byte = tx_byte;

    CYCLES_full();
    ASSERT_pin_IS("START bit", 0);
    model->data_valid = 0;
    model->data_byte = 0;

	rx_byte = 0;
	for (int bits = 0; bits < 8; bits++) {
		CYCLES_full();
		CData bit = model->pin & 1;
		rx_byte |= bit << bits;
	}

	CYCLES_full();
	ASSERT_pin_IS("STOP bit", 1);
	ASSERT_EQ("DATA", tx_byte, rx_byte);
}

int main(int argc, char **argv) {
	Simulation simulation;
	simulation.start(argc, argv, "uart_tx.vcd");
	return 0;
}
