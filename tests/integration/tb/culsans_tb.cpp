#include "Variane_ccu_multicore_top.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <getopt.h>
#include <chrono>
#include <ctime>
#include <signal.h>
#include <unistd.h>

#include <fesvr/dtm.h>
#include <fesvr/htif_hexwriter.h>
#include <fesvr/elfloader.h>
#include <fesvr/htif.h>

#define MAX_SIM_TIME 100
#define RST_TIME 5
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env)
{
    static struct option htif_long_options [] = { HTIF_LONG_OPTIONS };
    struct option * htif_option = &htif_long_options[0];
    std::string arg = optarg;
    char ** htif_argv = NULL;
    bool done = false;
    while (htif_option->name) {
        if (arg.substr(1, strlen(htif_option->name)) == htif_option->name) {
            optind--;
            done = true;
        }
        htif_option++;
    }
    if (done == false)
	std::cerr << argv[0] << ": invalid plus-arg (Verilog or HTIF) \""
                  << arg << "\"\n";

    int htif_argc = 1 + argc - optind;
    htif_argv = (char **) malloc((htif_argc) * sizeof (char *));
    htif_argv[0] = argv[0];
    for (int i = 1; optind < argc;) htif_argv[i++] = argv[optind++];

    const char *vcd_file = NULL;
    Verilated::commandArgs(argc, argv);
    Variane_ccu_multicore_top* top = new Variane_ccu_multicore_top;

    // Use an hitf hexwriter to read the binary data.
    htif_hexwriter_t htif(0x0, 1, -1);
    memif_t memif(&htif);
    reg_t entry;
    load_elf(htif_argv[1], &memif, &entry);

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
	if (sim_time == RST_TIME) {
            // Preload memory.
            size_t mem_size = 0xFFFFFF;
            memif.read(0x80000000, mem_size, (void *)top->ariane_ccu_multicore_top__DOT__i_sram__DOT__gen_cut__BRA__0__KET____DOT__gen_mem__DOT__i_tc_sram_wrapper__DOT__i_tc_sram__DOT__sram);
	}
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
