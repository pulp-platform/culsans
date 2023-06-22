# Check that RTL is aligned with the NB_CORES setting

RTL_NBCORES_DEF = "localparam NB_CORES = $(NB_CORES);"

.PHONY: nb_cores_rtl
nb_cores_rtl:
	@if ! grep -q $(RTL_NBCORES_DEF) ../../rtl/include/culsans_pkg.sv; then \
		sed -i 's/localparam NB_CORES = [0-9]\+;/localparam NB_CORES = $(NB_CORES);/' ../../rtl/include/culsans_pkg.sv; \
	fi

# Compile the RTL


CVA6_DIR = $(root-dir)

CULSANS_DIR := ../../rtl
CULSANS_PKG := $(wildcard $(CULSANS_DIR)/include/*_pkg.sv)

CULSANS_SRC += $(CVA6_DIR)/vendor/pulp-platform/axi/src/ace_intf.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/pulp-platform/axi/src/snoop_intf.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/pulp-platform/axi/src/ccu_fsm.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/pulp-platform/axi/src/ace_trs_dec.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/pulp-platform/axi/src/ace_ccu_top.sv
CULSANS_SRC += $(CVA6_DIR)/corev_apu/tb/common/mock_uart.sv
CULSANS_SRC += $(filter-out $(CULSANS_DIR)/src/culsans_xilinx.sv, $(wildcard $(CULSANS_DIR)/src/*.sv))
CULSANS_INCDIR := $(CULSANS_DIR)/include
CULSANS_INCDIR := $(foreach dir, ${CULSANS_INCDIR}, +incdir+$(dir))

# Compile the test bench

CVA6_TEST += $(CVA6_DIR)/corev_apu/tb/common_verification/src/rand_id_queue.sv
CVA6_TEST += $(CVA6_DIR)/vendor/pulp-platform/axi/src/axi_test.sv
CVA6_TEST += $(CVA6_DIR)/vendor/pulp-platform/axi/src/ace_test.sv
CVA6_TEST += $(CVA6_DIR)/vendor/pulp-platform/axi/src/snoop_test.sv
CVA6_TEST += $(CVA6_DIR)/corev_apu/axi/test/tb_ace_ccu_pkg.sv
CVA6_TEST += $(CVA6_DIR)/corev_apu/tb/tb_std_cache_subsystem/hdl/dcache_intf.sv
CVA6_TEST += $(CVA6_DIR)/corev_apu/tb/tb_std_cache_subsystem/hdl/sram_intf.sv
CVA6_TEST += $(CVA6_DIR)/corev_apu/tb/tb_std_cache_subsystem/hdl/amo_intf.sv
CVA6_TEST += $(CVA6_DIR)/corev_apu/tb/tb_std_cache_subsystem/hdl/tb_std_cache_subsystem_pkg.sv

list_incdir += $(CULSANS_INCDIR)

TB_DIR = ./tb
TB_SRC := $(wildcard $(TB_DIR)/*.sv)

TOP_LEVEL := culsans_tb

VERILATOR_LIB = work_verilate
DEFINES = 

#VLOG_FLAGS += +cover=bcfst+/dut -incr -64 -nologo -quiet -suppress 13262 -suppress 2583 -permissive +define+$(defines)
#VLOG_FLAGS += -incr -64 -nologo -quiet -suppress 13262 -suppress 2583 -permissive +define+$(defines)
VLOG_FLAGS += -svinputport=compat -incr -64 -nologo -quiet -suppress 13262 -suppress 2583 -O0
VLOG_FLAGS += -suppress 2986 # (vlog-2986) The hierarchical reference 'aw_chan_i.id' is not legal in a constant expression context.
VLOG_FLAGS += -suppress 2879 # allow calling tasks in final procedure
ifneq ($(DEFINES), "")
VLOG_FLAGS += $(foreach def, $(DEFINES), +define+$(def))
endif

verilate_command := $(verilator) $(CVA6_DIR)/verilator_config.vlt                                                \
                    -f $(CVA6_DIR)/core/Flist.cva6                                                               \
                    $(filter-out %.vhd, $(ariane_pkg))                                                           \
                    $(filter-out $(CVA6_DIR)/core/fpu_wrap.sv, $(filter-out %.vhd, $(src)))                      \
                    +define+$(defines)$(if $(TRACE_FAST),+VM_TRACE)$(if $(TRACE_COMPACT),+VM_TRACE+VM_TRACE_FST) \
                    $(CVA6_DIR)/corev_apu/tb/common/mock_uart.sv                                                 \
                    +incdir+$(CVA6_DIR)/corev_apu/axi_node                                                       \
                    $(CULSANS_PKG) $(CULSANS_SRC)                                                                \
                    $(if $(verilator_threads), --threads $(verilator_threads))                                   \
                    --unroll-count 256                                                                           \
                    -Wall                                                                                        \
                    -Werror-PINMISSING                                                                           \
                    -Werror-IMPLICIT                                                                             \
                    -Wno-fatal                                                                                   \
                    -Wno-PINCONNECTEMPTY                                                                         \
                    -Wno-ASSIGNDLY                                                                               \
                    -Wno-DECLFILENAME                                                                            \
                    -Wno-UNUSED                                                                                  \
                    -Wno-UNOPTFLAT                                                                               \
                    -Wno-BLKANDNBLK                                                                              \
                    -Wno-style                                                                                   \
                    $(if ($(PRELOAD)!=""), -DPRELOAD=1,)                                                         \
                    $(if $(PROFILE),--stats --stats-vars --profile-cfuncs,)                                      \
                    $(if $(DEBUG), --trace-structs,)                                                             \
                    $(if $(TRACE_COMPACT), --trace-fst $(VERILATOR_ROOT)/include/verilated_fst_c.cpp)            \
                    $(if $(TRACE_FAST), --trace $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp,)                  \
                    -LDFLAGS "-L$(RISCV)/lib -L$(SPIKE_ROOT)/lib -Wl,-rpath,$(RISCV)/lib -Wl,-rpath,$(SPIKE_ROOT)/lib -lfesvr$(if $(PROFILE), -g -pg,) -lpthread $(if $(TRACE_COMPACT), -lz,)" \
                    -CFLAGS "$(CFLAGS)$(if $(PROFILE), -g -pg,) -DVL_DEBUG"                                      \
                    --cc  --vpi                                                                                  \
                    $(list_incdir) --top-module culsans_top                                                      \
                    --threads-dpi none                                                                           \
                    --Mdir $(VERILATOR_LIB) -O3                                                                    \
                    --exe ./tb/culsans_tb.cpp 

$(library)/.build-culsans-srcs: $(library) $(CULSANS_PKG) $(CULSANS_SRC) 
	$(VLOG) $(VLOG_FLAGS) -work $(library) $(CULSANS_PKG) $(list_incdir)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(library) -pedanticerrors $(CULSANS_SRC) $(list_incdir)
	@touch $(library)/.build-culsans-srcs

$(library)/.build-culsans-tb: $(library)/.build-culsans-srcs $(library) $(TB_SRC) $(CVA6_TEST)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(library) -pedanticerrors $(CVA6_TEST) $(list_incdir)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(library) -pedanticerrors $(TB_SRC) $(list_incdir)
	@touch $(library)/.build-culsans-tb

ifeq ($(VERILATE), 0)
rtl: $(library)/.build-srcs $(library)/.build-culsans-srcs $(library)/.build-culsans-tb
	$(VOPT) $(VLOG_FLAGS) -work $(library)  $(TOP_LEVEL) -o $(TOP_LEVEL)_optimized +acc -check_synthesis
else
VERILATOR_JOBS = 1
rtl:
	$(verilate_command)
	cd $(VERILATOR_LIB) && $(MAKE) -j${VERILATOR_JOBS} -f Vculsans_top.mk
endif


# Cleanup

clean_rtl:
	rm -rf $(library)
	rm -rf $(VERILATOR_LIB)

.PHONY: rtl clean_rtl
