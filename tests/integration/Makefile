include ../common.mk

TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

# Compile the SW

COMMON_TEST_SW = ./sw
COMMON_TEST_SW_SRC = $(COMMON_TEST_SW)/src
COMMON_TEST_SW_INC = $(COMMON_TEST_SW)/include

# more folders might be added in the future
VPATH = $(COMMON_TEST_SW_SRC)
# more folders might be added in the future
SW_INCLUDES = $(foreach d, $(COMMON_TEST_SW_INC), -I$d)
# more folders might be added in the future
SW_SRCS += $(shell find $(COMMON_TEST_SW_SRC) -name *.c -exec basename {} \;)

OBJDIR = ./objs
OBJS = $(SW_SRCS:%.c=$(OBJDIR)/%.o)

objs:
	mkdir -p $@

libs:
	mkdir -p $@

$(OBJDIR)/%.o: %.c objs
	$(RV_GCC) $(SW_INCLUDES) -Werror -falign-functions=32 -falign-jumps=32 -c $< -o $@

# 
libs/libintegr.a: $(OBJS) libs
	$(RV_AR) -rcs $@ $(OBJS)

sw : libs/libintegr.a
	for d in $(TESTLIST); do make -C $$d sw; done

# Compile the RTL

AXI_DIR = ../../modules/axi
CVA6_DIR = ../../modules/cva6

# Common cells

COMMON_PKG := $(CVA6_DIR)/common/submodules/common_cells/src/cf_math_pkg.sv
COMMON_SRC := $(CVA6_DIR)/common/submodules/common_cells/src/rstgen_bypass.sv                          \
	        $(CVA6_DIR)/common/submodules/common_cells/src/rstgen.sv                                 \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_mux.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_demux.sv                           \
	        $(CVA6_DIR)/common/submodules/common_cells/src/exp_backoff.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/addr_decode.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_register.sv                        \
	        $(CVA6_DIR)/common/submodules/common_cells/src/unread.sv                                 \
	        $(CVA6_DIR)/common/submodules/common_cells/src/sync.sv                                   \
	        $(CVA6_DIR)/common/submodules/common_cells/src/cdc_2phase.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/spill_register_flushable.sv               \
	        $(CVA6_DIR)/common/submodules/common_cells/src/spill_register.sv                         \
	        $(CVA6_DIR)/common/submodules/common_cells/src/sync_wedge.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/edge_detect.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_arbiter.sv                         \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_arbiter_flushable.sv               \
	        $(CVA6_DIR)/common/submodules/common_cells/src/deprecated/fifo_v1.sv                     \
	        $(CVA6_DIR)/common/submodules/common_cells/src/deprecated/fifo_v2.sv                     \
	        $(CVA6_DIR)/common/submodules/common_cells/src/fifo_v3.sv                                \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lzc.sv                                    \
	        $(CVA6_DIR)/common/submodules/common_cells/src/popcount.sv                               \
	        $(CVA6_DIR)/common/submodules/common_cells/src/rr_arb_tree.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/deprecated/rrarbiter.sv                   \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_delay.sv                           \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lfsr.sv                                   \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lfsr_8bit.sv                              \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lfsr_16bit.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/delta_counter.sv                          \
	        $(CVA6_DIR)/common/submodules/common_cells/src/counter.sv                                \
	        $(CVA6_DIR)/common/submodules/common_cells/src/shift_reg.sv

# AXI

# AXI packages
AXI_PKG := src/axi_pkg.sv \
						src/ace_pkg.sv \
						src/snoop_pkg.sv
AXI_PKG := $(addprefix $(AXI_DIR)/, $(AXI_PKG))

AXI_SRC := src/axi_cut.sv                                                 \
	          src/axi_join.sv                                                \
	          src/axi_delayer.sv                                             \
	          src/axi_to_axi_lite.sv                                         \
	          src/axi_id_prepend.sv                                          \
	          src/axi_atop_filter.sv                                         \
	          src/axi_err_slv.sv                                             \
	          src/axi_mux.sv                                                 \
	          src/axi_demux.sv                                               \
						src/axi_multicut.sv                                            \
	          src/axi_intf.sv \
	          src/ace_intf.sv \
	          src/snoop_intf.sv \
	          src/axi_xbar.sv \
	          src/ace_trs_dec.sv \
	          src/ace_ccu_top.sv
AXI_SRC := $(addprefix $(AXI_DIR)/, $(AXI_SRC))

AXI_INCDIR := $(AXI_DIR)/include
AXI_INCDIR := $(foreach dir, ${AXI_INCDIR}, +incdir+$(dir))

# CVA6

# CVA6 packages
CVA6_PKG := core/include/cv64a6_imafdc_sv39_config_pkg.sv
CVA6_PKG += core/include/riscv_pkg.sv                              \
              corev_apu/riscv-dbg/src/dm_pkg.sv                      \
              core/include/ariane_pkg.sv                             \
              core/include/ariane_rvfi_pkg.sv                        \
              core/include/wt_cache_pkg.sv                           \
              core/include/cvxif_pkg.sv                              \
              corev_apu/register_interface/src/reg_intf.sv           \
							corev_apu/tb/rvfi_pkg.sv                               \
              core/include/ariane_axi_pkg.sv                         \
              core/include/ariane_ace_pkg.sv                         \
              core/include/std_cache_pkg.sv                          \
              core/fpu/src/fpnew_pkg.sv                              \
              core/cvxif_example/include/cvxif_instr_pkg.sv          \
              core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv
CVA6_PKG := $(addprefix $(CVA6_DIR)/, $(CVA6_PKG))

# utility modules
UTIL := core/include/instr_tracer_pkg.sv                              \
        common/local/util/instr_tracer_if.sv                          \
        common/local/util/instr_tracer.sv                             \
        corev_apu/tb/common/mock_uart.sv                              \
        common/local/util/sram.sv
UTIL := $(addprefix $(CVA6_DIR)/, $(UTIL))

# CVA6 standalone components
CVA6_SRC := $(filter-out $(CVA6_DIR)/core/ariane_regfile.sv, $(wildcard $(CVA6_DIR)/core/*.sv))                  \
	        $(filter-out $(CVA6_DIR)/core/fpu/src/fpnew_pkg.sv, $(wildcard $(CVA6_DIR)/core/fpu/src/*.sv))       \
	        $(filter-out $(CVA6_DIR)/core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv,         \
	        $(wildcard $(CVA6_DIR)/core/fpu/src/fpu_div_sqrt_mvp/hdl/*.sv))                          \
	        $(wildcard $(CVA6_DIR)/core/frontend/*.sv)                                               \
	        $(filter-out $(CVA6_DIR)/core/cache_subsystem/std_no_dcache.sv,                          \
	        $(wildcard $(CVA6_DIR)/core/cache_subsystem/*.sv))                                       \
	        $(wildcard $(CVA6_DIR)/corev_apu/bootrom/*.sv)                                           \
	        $(wildcard $(CVA6_DIR)/corev_apu/clint/*.sv)                                             \
	        $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/axi2apb/src/*.sv)                              \
	        $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/apb_timer/*.sv)                                \
	        $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/axi_slice/src/*.sv)                            \
	        $(wildcard $(CVA6_DIR)/corev_apu/src/axi_riscv_atomics/src/*.sv)                         \
	        $(wildcard $(CVA6_DIR)/corev_apu/axi_mem_if/src/*.sv)                                    \
	        $(wildcard $(CVA6_DIR)/core/pmp/src/*.sv)                                                \
	        $(wildcard $(CVA6_DIR)/core/cvxif_example/*.sv)                                          \
					$(wildcard $(CVA6_DIR)/core/mmu_sv39/*.sv)												 \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/rv_plic_target.sv                                      \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/rv_plic_gateway.sv                                     \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_regmap.sv                                         \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_top.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dmi_cdc.sv                                           \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dmi_jtag.sv                                          \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dmi_jtag_tap.sv                                      \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_csrs.sv                                           \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_mem.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_sba.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_top.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/debug_rom/debug_rom.sv                                   \
	        $(CVA6_DIR)/corev_apu/register_interface/src/apb_to_reg.sv                               \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/deprecated/cluster_clk_cells.sv         \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/deprecated/pulp_clk_cells.sv            \
	        $(CVA6_DIR)/common/local/util/tc_sram_wrapper.sv                                         \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/rtl/tc_sram.sv                          \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/rtl/tc_clk.sv                           \
	        $(CVA6_DIR)/corev_apu/tb/rvfi_tracer.sv                                                  \
	        $(CVA6_DIR)/corev_apu/tb/common/uart.sv

#	        $(CVA6_DIR)/corev_apu/tb/common/SimDTM.sv                                                \
#	        $(CVA6_DIR)/corev_apu/tb/common/SimJTAG.sv
#CVA6_SRC := $(addprefix $(CVA6_DIR)/, $(CVA6_SRC))

COPRO_SRC := $(CVA6_DIR)/core/cvxif_example/include/cvxif_instr_pkg.sv \
             $(wildcard $(CVA6_DIR)/core/cvxif_example/*.sv)

CVA6_INCDIR := common/submodules/common_cells/include/ corev_apu/axi/include/ corev_apu/register_interface/include/
CVA6_INCDIR := $(addprefix $(CVA6_DIR)/, $(CVA6_INCDIR))
CVA6_INCDIR := $(foreach dir, ${CVA6_INCDIR}, +incdir+$(dir))

CULSANS_DIR := ../../rtl
CULSANS_PKG := $(wildcard $(CULSANS_DIR)/include/*_pkg.sv)
CULSANS_SRC := $(wildcard $(CULSANS_DIR)/src/*.sv)
CULSANS_INCDIR := $(CULSANS_DIR)/include
CULSANS_INCDIR := $(foreach dir, ${CULSANS_INCDIR}, +incdir+$(dir))

TB_DIR = ./tb
TB_SRC := $(wildcard $(TB_DIR)/*.sv)

TOP_LEVEL := culsans_tb

RTL_INCDIR += $(AXI_INCDIR)
RTL_INCDIR += $(CVA6_INCDIR)
RTL_INCDIR += $(CULSANS_INCDIR)

VSIM_LIB = work
VERILATOR_LIB = work_verilate

#VLOG_FLAGS += +cover=bcfst+/dut -incr -64 -nologo -quiet -suppress 13262 -suppress 2583 -permissive +define+$(defines)
#VLOG_FLAGS += -incr -64 -nologo -quiet -suppress 13262 -suppress 2583 -permissive +define+$(defines)
VLOG_FLAGS += -incr -64 -nologo -quiet -suppress 13262 -suppress 2583 -O0

VERILATOR_CMD := $(VERILATOR)                                                                                 \
                    $(COMMON_PKG) $(AXI_PKG) $(COMMON_SRC) $(AXI_SRC) $(CVA6_PKG) $(CVA6_SRC) $(CULSANS_PKG) $(CULSANS_SRC) \
                    $(COPRO_SRC)                                                                                 \
                    $(CVA6_DIR)/common/local/util/sram.sv                                                        \
                    $(CVA6_DIR)/corev_apu/tb/common/mock_uart.sv                                                 \
                    +incdir+$(CVA6_DIR)/corev_apu/axi_node                                                       \
                    --unroll-count 256                                                                           \
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
                    --trace                                                                     \
                    -LDFLAGS "-L$(RISCV)/lib -L$(SPIKE_ROOT)/lib -Wl,-rpath,$(RISCV)/lib -Wl,-rpath,$(SPIKE_ROOT)/lib -lfesvr -lpthread" \
                    -CFLAGS "-I$(RISCV)/include -I$(SPIKE_ROOT) -I$(SPIKE_ROOT)/include -std=c++11 -I$(SPIKE_ROOT)/include -I$(CVA6_DIR)/corev_apu/tb/dpi -O3 -DVL_DEBUG"       \
                    -Wall --cc  --vpi                                                                            \
                    $(RTL_INCDIR) --top-module culsans_top                                         \
					--threads-dpi none 																			 \
                    --Mdir $(VERILATOR_LIB) -O3                                                                    \
                    --exe ./tb/culsans_tb.cpp 
#                    $(CVA6_DIR)/corev_apu/tb/dpi/SimDTM.cc $(CVA6_DIR)/corev_apu/tb/dpi/SimJTAG.cc \
#                    $(CVA6_DIR)/corev_apu/tb/dpi/remote_bitbang.cc $(CVA6_DIR)/corev_apu/tb/dpi/msim_helper.cc 

$(library):
	$(VLIB) $(library)

$(VSIM_LIB)/.build-common-srcs: $(library) $(COMMON_PKG) $(COMMON_SRC)
	$(VLOG) $(VLOG_FLAGS) -work $(VSIM_LIB) $(COMMON_PKG) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(COMMON_SRC) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-common-srcs

$(VSIM_LIB)/.build-axi-srcs: $(library) $(AXI_PKG) $(AXI_SRC)
	$(VLOG) $(VLOG_FLAGS) -work $(VSIM_LIB) $(AXI_PKG) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(AXI_SRC) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-axi-srcs

$(VSIM_LIB)/.build-cva6-srcs: $(UTIL) $(CVA6_PKG) $(CVA6_SRC)
	$(VLOG) $(VLOG_FLAGS) -work $(VSIM_LIB) $(filter %.sv,$(CVA6_PKG)) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) $(filter %.sv,$(UTIL)) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(filter %.sv,$(CVA6_SRC)) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-cva6-srcs

$(VSIM_LIB)/.build-culsans-srcs: $(library) $(CULSANS_PKG) $(CULSANS_SRC)
	$(VLOG) $(VLOG_FLAGS) -work $(VSIM_LIB) $(CULSANS_PKG) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(CULSANS_SRC) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-culsans-srcs

$(VSIM_LIB)/.build-tb: $(library) $(TB_SRC)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(TB_SRC) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-tb

ifeq ($(VERILATE), 0)
rtl: $(library) $(VSIM_LIB)/.build-common-srcs $(VSIM_LIB)/.build-axi-srcs $(VSIM_LIB)/.build-cva6-srcs $(VSIM_LIB)/.build-culsans-srcs $(VSIM_LIB)/.build-tb
#	$(VOPT) $(VLOG_FLAGS) -work $(VSIM_LIB)  $(TOP_LEVEL) -o $(TOP_LEVEL)_optimized +acc -check_synthesis
else
VERILATOR_JOBS = 1
rtl:
	$(VERILATOR_CMD)
	cd $(VERILATOR_LIB) && $(MAKE) -j${VERILATOR_JOBS} -f Vculsans_top.mk
endif

# Run the test(s)

TEST ?= all

# run all the tests
ifeq ($(TEST), all)
all: sw rtl
	for d in $(TESTLIST); do make -C $$d all; done
# run a single test
else
all: sw rtl
	if [ -d $(TESTS_DIR)/$(TEST) ]; then echo "$(TEST) doesn't exist"; false; fi
	make -C $(TESTS_DIR)/$(TEST) all
endif

# run failed or not-executed tests
rerun: sw rtl
	for d in $(TESTLIST); do if [ -e $$d/$(TEST_REPORT) ]; then if grep -q FAIL $$d/$(TEST_REPORT) ; then make -C $$d all; fi; else make -C $$d all; fi; done

# Cleanup

clean_sw:
	rm -rf objs
	rm -rf libs

clean_rtl:
	rm -rf $(VSIM_LIB)
	rm -rf $(VERILATOR_LIB)

clean_tests:
	for d in $(TESTLIST); do make -C $$d clean; done

clean: clean_sw clean_rtl clean_tests

.PHONY: all sw rtl rerun clean clean_sw clean_rtl
