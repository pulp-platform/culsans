# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

include common.mk

TEST ?= all

VERILATE ?= 0

ifeq ($(TEST), all)
	TEST_SELECT := all
else
	TEST_SELECT := all TEST=$(TEST)
endif

# Test execution

unit:
	$(MAKE) -C unit VERILATE=$(VERILATE) $(TEST_SELECT)

integr:
	$(MAKE) -C integration VERILATE=$(VERILATE) $(TEST_SELECT)

perf:
	$(MAKE) -C performance VERILATE=$(VERILATE) $(TEST_SELECT)

litmus:
	echo make -C litmus VERILATE=$(VERILATE) $(TEST_SELECT)

sanity:
	@make -C unit clean sanity
	@make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace_direct
	@make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace
	@make -C integration clean all TEST=read_cache_share NB_CORES=4
	@printf "\nsanity check \033[32mPASSED\033[0m\n\n"

regr:
	@make -C unit clean pass
	@make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace_direct
	@make -C ../modules/cva6/corev_apu/tb/tb_wb_dcache clean simc toplevel=tb_ace
	@make -C integration clean all NB_CORES=4
	@printf "\nregression test \033[32mPASSED\033[0m\n\n"

# it only makes sense to call the target "all" if TESTS is set to "all"
ifeq ($(TEST), all)
all: unit integr perf litmus
else
all:
	echo "TEST must be set to \"all\""
	false
endif

.PHONY : all unit integr perf litmus

# Test summary generation

summary:
	@echo "Generating test summary"

# Cleanup

clean_unit:
	make -C unit clean
clean_integr:
	make -C integration clean
clean_perf:
	make -C performance clean
clean_litmus:
	make -C litmus clean

clean: clean_unit clean_integr clean_perf clean_litmus

.PHONY: clean clean_unit clean_integr clean_perf clean_litmus
