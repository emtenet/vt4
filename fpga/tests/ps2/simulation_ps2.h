#ifndef SIMULATION_PS2_H
#define SIMULATION_PS2_H

#include "../../simulation_base.h"
#include "Vps2_protocol.h"

// PS/2 clock 11.9kHz (10kHz .. 16.7kHz)
// cycle period ~ 84us
#define	DURATION_ps2_half() DURATION(42, us)
#define	DURATION_ps2_setup() DURATION(4, us)

class SimulationPS2: public SimulationBase<Vps2_protocol> {
public:
	SimulationPS2(): SimulationBase() {};
	virtual ~SimulationPS2() {};
	virtual void initialize() override;
	virtual void during_reset() override;
	virtual void after_reset() override;
protected:
	void ps2_rx_cycle();
	void ps2_rx_cycle_ack();
	void ps2_tx_cycle(CData data);
	void command_rx(CData command, const char* file, int line);
	void command_ack_handshake(const char* file, int line);
	void scan_code_tx(CData scan_code, const char* file, int line);
	void scan_code_handshake(const char* file, int line);
};

#define ASSERT_clk_DRIVEN(msg) \
	ASSERT_EQ("host DRIVING clk " msg, model->ps2_clk_oe, 1)
#define ASSERT_clk_IS(msg, clk) \
	ASSERT_EQ("host CLK driven IS " msg, model->ps2_clk_out, clk)
#define ASSERT_clk_RELEASED(msg) \
	ASSERT_EQ("host RELEASED clk " msg, model->ps2_clk_oe, 0)
#define ASSERT_command_BUSY(msg) \
	ASSERT_EQ("CANNOT send a command " msg, model->command_ready, 0)
#define ASSERT_command_READY(msg) \
	ASSERT_EQ("CAN send a command " msg, model->command_ready, 1)
#define ASSERT_command_ack_OK(msg) \
	ASSERT_EQ("command ack OK " msg, model->command_ack_error, 0)
#define ASSERT_command_ack_EMPTY(msg) \
	ASSERT_EQ("command ack EMPTY " msg, model->command_ack_valid, 0)
#define ASSERT_data_DRIVEN(msg) \
	ASSERT_EQ("host DRIVING data " msg, model->ps2_data_oe, 1)
#define ASSERT_data_IS(msg, data) \
	ASSERT_EQ("host DATA driven IS " msg, model->ps2_data_out, data)
#define ASSERT_data_RELEASED(msg) \
	ASSERT_EQ("host RELEASED data " msg, model->ps2_data_oe, 0)
#define ASSERT_scan_code_VALID(msg) \
	ASSERT_EQ("scan code is VALID " msg, model->scan_code_valid, 1)
#define ASSERT_scan_code_IS(msg, scan_code) \
	ASSERT_EQ("scan code IS " msg, model->scan_code_byte, scan_code)
#define ASSERT_scan_code_EMPTY(msg) \
	ASSERT_EQ("scan code EMPTY " msg, model->scan_code_valid, 0)
#define COMMAND(msg, command) \
	command_rx(command, __FILE__, __LINE__)
#define COMMAND_ACK_handshake() \
	command_ack_handshake(__FILE__, __LINE__)
#define SCAN_CODE(msg, scan_code) \
	scan_code_tx(scan_code, __FILE__, __LINE__)
#define SCAN_CODE_handshake() \
	scan_code_handshake(__FILE__, __LINE__)

void SimulationPS2::initialize() {
	model->ps2_clk_in = 1;
	model->ps2_data_in = 1;
	model->command_valid = 0;
	model->command_ack_ready = 0;
	model->scan_code_ready = 0;
}

void SimulationPS2::during_reset() {
	ASSERT_command_BUSY("DURING reset");
}

void SimulationPS2::after_reset() {
    ASSERT_command_READY("AFTER reset");
}

void SimulationPS2::ps2_rx_cycle() {
	cycles(DURATION_ps2_setup());
	model->ps2_clk_in = 0;
	cycles(DURATION_ps2_half());
	model->ps2_clk_in = 1;
	cycles(DURATION_ps2_half() - DURATION_ps2_setup());
}

void SimulationPS2::ps2_rx_cycle_ack() {
	model->ps2_data_in = 0;
	cycles(DURATION_ps2_setup());
	model->ps2_clk_in = 0;
	cycles(DURATION_ps2_half());
	model->ps2_clk_in = 1;
	model->ps2_data_in = 1;
}

void SimulationPS2::ps2_tx_cycle(CData data) {
	model->ps2_data_in = data;
	cycles(DURATION_ps2_setup());
	model->ps2_clk_in = 0;
	cycles(DURATION_ps2_half());
	model->ps2_clk_in = 1;
	cycles(DURATION_ps2_half() - DURATION_ps2_setup());
}

void SimulationPS2::command_rx(CData command, const char* file, int line) {
	assert_push(file, line);

	model->command_byte = command;
	model->command_valid = 1;
	model->command_ack_ready = 1;
	cycle();
	ASSERT_command_BUSY("until this one completes");
	model->command_byte = 0;
	model->command_valid = 0;

	// Host to Keyboard request with CLK pulled LOW
	ASSERT_clk_DRIVEN("for REQUEST to send");
	ASSERT_clk_IS("REQUEST to send", 0);

	int request_cycles = 0;
	while (model->ps2_clk_oe == 1) {
		ASSERT_clk_IS("REQUEST to send", 0);
		ASSERT_LT("request TOO long", request_cycles, DURATION(1, ms));

		cycle();
		request_cycles++;
	}

	ASSERT_LT("request for at least 100us", DURATION(100, us), request_cycles);

	ASSERT_data_DRIVEN("for REQUEST to send");
	ASSERT_data_IS("REQUEST to send", 0);

	// Delay before keyboard starts clocking
	cycles(DURATION(1, us) + bounded_rand(DURATION(100, us)));

	// START bit
	ASSERT_data_DRIVEN("for START bit");
	ASSERT_data_IS("START bit", 0);

	CData rx_command = 0;
	CData rx_parity = 0;

	for (int bits = 0; bits < 8; bits++) {
		// DATA bit
		ps2_rx_cycle();
		ASSERT_data_DRIVEN("for DATA bits");
		CData bit = model->ps2_data_out & 1;
		rx_command = (bit << 7) | (rx_command >> 1);
		rx_parity ^= bit;
	}

	ASSERT_EQ("sent COMMAND", rx_command, command);

	// PARITY bit
	ps2_rx_cycle();
	ASSERT_data_DRIVEN("for PARITY bit");
	CData bit = model->ps2_data_out & 1;
	rx_parity ^= bit;

	ASSERT_EQ("parity is ODD", rx_parity, 1);

	// STOP bit
	ps2_rx_cycle();
	ASSERT_data_RELEASED("for STOP bit");

	// ACK bit
	ps2_tx_cycle(0);

	ASSERT_command_BUSY("after ACK bit");
	ASSERT_command_ack_EMPTY("before ACK wait");

	int ack_cycles = 0;
	while (model->command_ack_valid == 0) {
		ASSERT_LT("ack TOO long", ack_cycles, DURATION(1, ms));

		cycle();
		ack_cycles++;
	}
	ASSERT_command_ack_OK("after SENDING");
	ASSERT_command_READY("after SENDING");

	cycle();
	ASSERT_command_ack_EMPTY("after ACK handshake");
	model->command_ack_ready = 0;

	assert_pop();
}

void SimulationPS2::scan_code_tx(CData scan_code, const char* file, int line) {
	assert_push(file, line);

	// PS/2 frame
	ps2_tx_cycle(0); // START bit
	ASSERT_command_BUSY("after START bit");
	CData parity = 1;
	for(int bits = 0; bits < 8; bits++) {
		CData bit = (scan_code >> bits) & 1;
		parity ^= bit;
		ps2_tx_cycle(bit);
	}
	ps2_tx_cycle(parity);
	ps2_tx_cycle(1); // STOP bit

	ASSERT_command_BUSY("after STOP bit");
	ASSERT_scan_code_EMPTY("after STOP bit");

	int stop_cycles = 0;
	while (model->scan_code_valid == 0) {
		ASSERT_LT("stop TOO long", stop_cycles, DURATION(1, ms));

		cycle();
		stop_cycles++;
	}

	ASSERT_scan_code_VALID();
	ASSERT_scan_code_IS("received", scan_code);
	ASSERT_command_READY("after SCAN CODE");

	assert_pop();
}

void SimulationPS2::scan_code_handshake(const char* file, int line) {
	assert_push(file, line);

	ASSERT_scan_code_VALID();

	model->scan_code_ready = 1;
	cycle();
	ASSERT_scan_code_EMPTY("after handshake");
	model->scan_code_ready = 0;

	assert_pop();
}

#endif