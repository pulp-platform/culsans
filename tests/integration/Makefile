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
	$(GCC) $(SW_INCLUDES) -Werror -c $< -o $@

# 
libs/libintegr.a: $(OBJS) libs
	$(AR) -rcs $@ $(OBJS)

sw : libs/libintegr.a
	for d in $(TESTLIST); do make -C $$d sw; done

# Compile the RTL

# CVA6

CVA6_DIR = ../../modules/cva6

# CVA6 packages
CVA6_PKG := core/include/cv64a6_imafdc_sv39_config_pkg.sv
CVA6_PKG += core/include/riscv_pkg.sv                              \
              corev_apu/riscv-dbg/src/dm_pkg.sv                      \
              core/include/ariane_pkg.sv                             \
              core/include/ariane_rvfi_pkg.sv                        \
              core/include/wt_cache_pkg.sv                           \
              core/include/cvxif_pkg.sv                              \
              corev_apu/axi/src/axi_pkg.sv                           \
              corev_apu/register_interface/src/reg_intf.sv           \
              core/include/axi_intf.sv                               \
              corev_apu/tb/rvfi_pkg.sv                               \
              corev_apu/tb/ariane_soc_pkg.sv                         \
              corev_apu/tb/ariane_axi_soc_pkg.sv                     \
              core/include/ariane_axi_pkg.sv                         \
              core/include/std_cache_pkg.sv                          \
              core/fpu/src/fpnew_pkg.sv                              \
              common/submodules/common_cells/src/cf_math_pkg.sv      \
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
CVA6_SRC := $(filter-out core/ariane_regfile.sv, $(wildcard core/*.sv))                  \
	        $(filter-out core/fpu/src/fpnew_pkg.sv, $(wildcard core/fpu/src/*.sv))       \
	        $(filter-out core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv,         \
	        $(wildcard core/fpu/src/fpu_div_sqrt_mvp/hdl/*.sv))                          \
	        $(wildcard core/frontend/*.sv)                                               \
	        $(filter-out core/cache_subsystem/std_no_dcache.sv,                          \
	        $(wildcard core/cache_subsystem/*.sv))                                       \
	        $(wildcard corev_apu/bootrom/*.sv)                                           \
	        $(wildcard corev_apu/clint/*.sv)                                             \
	        $(wildcard corev_apu/fpga/src/axi2apb/src/*.sv)                              \
	        $(wildcard corev_apu/fpga/src/apb_timer/*.sv)                                \
	        $(wildcard corev_apu/fpga/src/axi_slice/src/*.sv)                            \
	        $(wildcard corev_apu/src/axi_riscv_atomics/src/*.sv)                         \
	        $(wildcard corev_apu/axi_mem_if/src/*.sv)                                    \
	        $(wildcard core/pmp/src/*.sv)                                                \
	        $(wildcard core/cvxif_example/*.sv)                                          \
			$(wildcard core/mmu_sv39/*.sv)												 \
	        corev_apu/rv_plic/rtl/rv_plic_target.sv                                      \
	        corev_apu/rv_plic/rtl/rv_plic_gateway.sv                                     \
	        corev_apu/rv_plic/rtl/plic_regmap.sv                                         \
	        corev_apu/rv_plic/rtl/plic_top.sv                                            \
	        corev_apu/riscv-dbg/src/dmi_cdc.sv                                           \
	        corev_apu/riscv-dbg/src/dmi_jtag.sv                                          \
	        corev_apu/riscv-dbg/src/dmi_jtag_tap.sv                                      \
	        corev_apu/riscv-dbg/src/dm_csrs.sv                                           \
	        corev_apu/riscv-dbg/src/dm_mem.sv                                            \
	        corev_apu/riscv-dbg/src/dm_sba.sv                                            \
	        corev_apu/riscv-dbg/src/dm_top.sv                                            \
	        corev_apu/riscv-dbg/debug_rom/debug_rom.sv                                   \
	        corev_apu/register_interface/src/apb_to_reg.sv                               \
	        corev_apu/axi/src/axi_multicut.sv                                            \
	        common/submodules/common_cells/src/rstgen_bypass.sv                          \
	        common/submodules/common_cells/src/rstgen.sv                                 \
	        common/submodules/common_cells/src/stream_mux.sv                             \
	        common/submodules/common_cells/src/stream_demux.sv                           \
	        common/submodules/common_cells/src/exp_backoff.sv                            \
	        common/submodules/common_cells/src/addr_decode.sv                            \
	        common/submodules/common_cells/src/stream_register.sv                        \
	        corev_apu/axi/src/axi_cut.sv                                                 \
	        corev_apu/axi/src/axi_join.sv                                                \
	        corev_apu/axi/src/axi_delayer.sv                                             \
	        corev_apu/axi/src/axi_to_axi_lite.sv                                         \
	        corev_apu/axi/src/axi_id_prepend.sv                                          \
	        corev_apu/axi/src/axi_atop_filter.sv                                         \
	        corev_apu/axi/src/axi_err_slv.sv                                             \
	        corev_apu/axi/src/axi_mux.sv                                                 \
	        corev_apu/axi/src/axi_demux.sv                                               \
	        corev_apu/axi/src/axi_xbar.sv                                                \
	        common/submodules/common_cells/src/unread.sv                                 \
	        common/submodules/common_cells/src/sync.sv                                   \
	        common/submodules/common_cells/src/cdc_2phase.sv                             \
	        common/submodules/common_cells/src/spill_register_flushable.sv               \
	        common/submodules/common_cells/src/spill_register.sv                         \
	        common/submodules/common_cells/src/sync_wedge.sv                             \
	        common/submodules/common_cells/src/edge_detect.sv                            \
	        common/submodules/common_cells/src/stream_arbiter.sv                         \
	        common/submodules/common_cells/src/stream_arbiter_flushable.sv               \
	        common/submodules/common_cells/src/deprecated/fifo_v1.sv                     \
	        common/submodules/common_cells/src/deprecated/fifo_v2.sv                     \
	        common/submodules/common_cells/src/fifo_v3.sv                                \
	        common/submodules/common_cells/src/lzc.sv                                    \
	        common/submodules/common_cells/src/popcount.sv                               \
	        common/submodules/common_cells/src/rr_arb_tree.sv                            \
	        common/submodules/common_cells/src/deprecated/rrarbiter.sv                   \
	        common/submodules/common_cells/src/stream_delay.sv                           \
	        common/submodules/common_cells/src/lfsr.sv                                   \
	        common/submodules/common_cells/src/lfsr_8bit.sv                              \
	        common/submodules/common_cells/src/lfsr_16bit.sv                             \
	        common/submodules/common_cells/src/delta_counter.sv                          \
	        common/submodules/common_cells/src/counter.sv                                \
	        common/submodules/common_cells/src/shift_reg.sv                              \
	        corev_apu/src/tech_cells_generic/src/deprecated/cluster_clk_cells.sv         \
	        corev_apu/src/tech_cells_generic/src/deprecated/pulp_clk_cells.sv            \
	        common/local/util/tc_sram_wrapper.sv                                         \
	        corev_apu/src/tech_cells_generic/src/rtl/tc_sram.sv                          \
	        corev_apu/src/tech_cells_generic/src/rtl/tc_clk.sv                           \
	        corev_apu/tb/ariane_testharness.sv                                           \
	        corev_apu/tb/ariane_peripherals.sv                                           \
	        corev_apu/tb/rvfi_tracer.sv                                                  \
	        corev_apu/tb/common/uart.sv                                                  \
	        corev_apu/tb/common/SimDTM.sv                                                \
	        corev_apu/tb/common/SimJTAG.sv
CVA6_SRC := $(addprefix $(CVA6_DIR)/, $(CVA6_SRC))

CVA6_INCDIR := common/submodules/common_cells/include/ corev_apu/axi/include/ corev_apu/register_interface/include/
CVA6_INCDIR := $(addprefix $(CVA6_DIR)/, $(CVA6_INCDIR))
CVA6_INCDIR := $(foreach dir, ${CVA6_INCDIR}, +incdir+$(dir))

# Culsans components
CULSANS_DIR := ../../rtl
CULSANS_PKG := $(wildcard $(CULSANS_DIR)/include/*_pkg.sv)
CULSANS_SRC := $(wildcard $(CULSANS_DIR)/src/*.sv)
CULSANS_INCDIR := $(CULSANS_DIR)/include
CULSANS_INCDIR := $(foreach dir, ${CULSANS_INCDIR}, +incdir+$(dir))

# Testbench
TB_DIR = ./tb
TB_SRC := $(wildcard $(TB_DIR)/*.sv)

TOP_LEVEL := culsans_tb

RTL_INCDIR += $(CVA6_INCDIR)
RTL_INCDIR += $(CULSANS_INCDIR)

VSIM_LIB = work

VLOG_FLAGS += +cover=bcfst+/dut -incr -64 -nologo -quiet -suppress 13262 -suppress 2583 -permissive +define+$(defines)

$(VSIM_LIB)/.build-cva6-srcs: $(UTIL) $(CVA6_PKG) $(CVA6_SRC)
	$(VLOG) $(VLOG_FLAGS) -work $(VSIM_LIB) $(filter %.sv,$(CVA6_PKG)) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) $(filter %.sv,$(UTIL)) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(filter %.sv,$(CVA6_SRC)) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-cva6-srcs

$(VSIM_LIB)/.build-culsans-srcs: $(CULSANS_PKG) $(CULSANS_SRC)
	$(VLOG) $(VLOG_FLAGS) -work $(VSIM_LIB) $(CULSANS_PKG) $(RTL_INCDIR)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(CULSANS_SRC) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-culsans-srcs

$(VSIM_LIB)/.build-tb: $(TB_SRC)
	$(VLOG) $(VLOG_FLAGS) -timescale "1ns / 1ns" -work $(VSIM_LIB) -pedanticerrors $(TB_SRC) $(RTL_INCDIR)
	touch $(VSIM_LIB)/.build-tb

rtl: $(VSIM_LIB)/.build-cva6-srcs $(VSIM_LIB)/.build-culsans-srcs $(VSIM_LIB)/.build-tb
	$(VOPT) $(VLOG_FLAGS) -work $(VSIM_LIB)  $(TOP_LEVEL) -o $(TOP_LEVEL)_optimized +acc -check_synthesis

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

clean_tests:
	for d in $(TESTLIST); do make -C $$d clean; done

clean: clean_sw clean_rtl clean_tests

.PHONY: all sw rtl rerun clean clean_sw clean_rtl
