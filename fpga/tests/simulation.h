#ifndef SIMULATION_H
#define SIMULATION_H

#include <cstdlib>
#include <ctime>
#include <stdio.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

// simulation with a 50MHz clock
#define	TIME_PRECISION -8 // 10ns per half cycle
#define	CYCLES_ns(ns) (ns / 20)
#define	CYCLES_us(us) ((1000 * us) / 20)
#define	CYCLES_ms(ms) ((1000000 * ms) / 20)

unsigned bounded_rand(unsigned range)
{
    for (unsigned x, r;;)
        if (x = std::rand(), r = x % range, x - r <= -range)
            return r;
}

unsigned bounded_rand(unsigned min, unsigned max)
{
	return min + bounded_rand(max + 1 - min);
}

template<class V>
class SimulationBase {
public:
	SimulationBase();
	virtual ~SimulationBase();
	void start(int argc, char **argv, const char* waveform);
	virtual void initialize()=0;
	virtual void during_reset()=0;
	virtual void after_reset()=0;
	virtual void simulation()=0;
protected:
	void assert_eq(const char* message, int lhs, int rhs, const char* expr, const char* file, int line);
	void assert_lt(const char* message, const char* expr, const char* file, int line);
	void cycle();
	void cycles(int cycles);
protected:
	std::unique_ptr<VerilatedContext> cx;
	std::unique_ptr<VerilatedVcdC> trace;
    std::unique_ptr<V> model;
private:
	void assert_start(const char* message, const char* expr, const char* file, int line);
	void assert_end();
	void assert_push(const char* file, int line);
	void assert_pop();
	void cycle_initial();
	void cycle_final();
private:
	const char* assert_file;
	int assert_line;
};

template<class V>
SimulationBase<V>::SimulationBase()
	: cx{}
	, trace{}
    , model{}
	, assert_file(nullptr)
	, assert_line(0)
{
}

template<class V>
SimulationBase<V>::~SimulationBase() {
    model->final();
    trace->close();
}

#define ASSERT_EQ(message, lhs, rhs) \
	if ((lhs) != (rhs)) { \
		assert_eq(message, lhs, rhs, #lhs " == " #rhs, __FILE__, __LINE__); \
	}
#define ASSERT_LT(message, lhs, rhs) \
	if ((lhs) >= (rhs)) { \
		assert_lt(message, #lhs " < " #rhs, __FILE__, __LINE__); \
	}
#define CYCLES(count, unit) cycles(CYCLES_##unit(count))

template<class V>
void SimulationBase<V>::assert_eq(const char* message, int lhs, int rhs, const char* expr, const char* file, int line) {
	assert_start(message, expr, file, line);
	printf("    LHS = %d\n", lhs);
	printf("    RHS = %d\n", rhs);
	assert_end();
}

template<class V>
void SimulationBase<V>::assert_lt(const char* message, const char* expr, const char* file, int line) {
	assert_start(message, expr, file, line);
	assert_end();
}

template<class V>
void SimulationBase<V>::assert_start(const char* message, const char* expr, const char* file, int line) {
	printf("ASSERTION FAILED\n");
	if (assert_file) {
		printf("    @ %s:%d\n", assert_file, assert_line);
	}
	printf("    @ %s:%d\n", file, line);
	printf("    %s\n", message);
	printf("    %s\n", expr);
}

template<class V>
void SimulationBase<V>::assert_end() {
	cycle_final();

    model->final();
    trace->close();
	exit(1);
}

template<class V>
void SimulationBase<V>::assert_push(const char* file, int line) {
	assert_file = file;
	assert_line = line;
}

template<class V>
void SimulationBase<V>::assert_pop() {
	assert_file = nullptr;
	assert_line = 0;
}

template<class V>
void SimulationBase<V>::cycle_initial() {
	model->clk = 1;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

template<class V>
void SimulationBase<V>::cycle_final() {
	model->clk = 0;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

template<class V>
void SimulationBase<V>::cycle() {
	model->clk = 0;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);

	model->clk = 1;
    model->eval();
    trace->dump(cx->time());
    cx->timeInc(1);
}

template<class V>
void SimulationBase<V>::cycles(int cycles) {
    for (int cycle=0; cycle<cycles; cycle++) {
    	this->cycle();
    }
}

template<class V>
void SimulationBase<V>::start(int argc, char **argv, const char* waveform) {
	std::srand(std::time({}));

	cx.reset(new VerilatedContext);

	cx->traceEverOn(true);
    cx->commandArgs(argc, argv);

    cx->timeprecision(TIME_PRECISION);

    trace.reset(new VerilatedVcdC);

    model.reset(new V{cx.get(), "TOP"});
    model->trace(trace.get(), 1);

    trace->open(waveform);

	model->reset_low = 0;
	initialize();

	cycle_initial();
	during_reset();

	CYCLES(100, us);
    model->reset_low = 1;
    cycle();
    after_reset();

	CYCLES(100, us);

	simulation();

	CYCLES(100, us);

	cycle_final();
}

#endif