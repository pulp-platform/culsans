#include "Variane_ccu_multicore_top.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 100
#define RST_TIME 5
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env)
{
    Variane_ccu_multicore_top* top = new Variane_ccu_multicore_top;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    top->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    while (sim_time < MAX_SIM_TIME) {
        top->clk_i ^= 1;
        if (sim_time < RST_TIME)
            top->rst_ni = 0;
        else
            top->rst_ni = 1;
        top->eval();
        m_trace->dump(sim_time);
       if (top->exit_o & 0x1)
            break;
        sim_time++;
    }

    m_trace->close();
    if (top->exit_o >> 1) {
        delete top;
        exit(EXIT_FAILURE);
    }
    else {
        delete top;
        exit(EXIT_SUCCESS);
    }
        
}
