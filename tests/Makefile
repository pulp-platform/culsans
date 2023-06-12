include common.mk

TEST ?= all

VERILATE ?= 0

ifeq ($(TEST), all)
	TEST_SELECT := all
else
	TEST_SELECT := run TEST=$(TEST)
endif

# Test execution

unit:
	echo make -C unit VERILATE=$(VERILATE) $(TEST_SELECT)

integr:
	echo make -C integration VERILATE=$(VERILATE) $(TEST_SELECT)

perf:
	echo make -C perf VERILATE=$(VERILATE) $(TEST_SELECT)

fpga:
	echo make -C fpga $(TEST_SELECT)

sanity:
	make -C unit clean sanity
	@# these requires additional license, wait for it
	@# make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace_direct
	@# make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace
	@make -C integration clean all TEST=read_cache_share NB_CORES=4
	@make -C ../modules/cva6/corev_apu/axi/ clean sim-ace_ccu_top_sanity.log
	@printf "\nsanity check \033[32mPASSED\033[0m\n\n"

regr:
	make -C unit clean pass
	@# these requires additional license, wait for it
	@# make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace_direct
	@# make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace
	@make -C integration clean all NB_CORES=4
	@make -C ../modules/cva6/corev_apu/axi/ clean sim-ace_ccu_top.log
	@printf "\nregression test \033[32mPASSED\033[0m\n\n"

# it only makes sense to call the target "all" if TESTS is set to "all"
ifeq ($(TEST), all)
all: unit integr perf fpga
else
all:
	echo "TEST must be set to \"all\""
	false
endif

.PHONY : all unit integr perf fpga

# Test summary generation

summary:
	@echo "Generating test summary"

# Cleanup

clean_unit:
	echo make -C unit clean
clean_integr:
	echo make -C integration clean
clean_perf:
	echo make -C perf clean
clean_fpga:
	echo make -C fpga clean

clean: clean_unit clean_integr clean_perf clean_fpga

.PHONY: clean clean_unit clean_integr clean_perf clean_fpga