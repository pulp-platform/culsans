# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

include ../common.mk
include ../rtl.mk
# add dummy version of cva6 for injecting cache requests from test bench drivers
CVA6_TEST += $(CVA6_DIR)/corev_apu/tb/tb_std_cache_subsystem/hdl/cva6_cache_dummy.sv

# create list of available tests
TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

# avoid triggering known bugs
AVOID_BUG_147  = 0    # Jira ticket https://planv.atlassian.net/browse/PROJ-147
AVOID_BUG_274  = 0    # Jira ticket https://planv.atlassian.net/browse/PROJ-274

AVOID_BUG_ALL ?= 1
ifeq ($(AVOID_BUG_ALL), 1)
    AVOID_BUG_147 = 1
    AVOID_BUG_274 = 1
endif

FAIL_LIST =
ifeq ($(AVOID_BUG_147), 1)
	FAIL_LIST += $(TESTS_DIR)/read_two_writes_back_to_back/
endif

ifeq ($(AVOID_BUG_274), 1)
	FAIL_LIST += $(TESTS_DIR)/amo_lr_sc_single/
endif

PASS_LIST = $(filter-out $(FAIL_LIST), $(TESTLIST))

# other sets
AMO_LIST := $(dir $(wildcard $(TESTS_DIR)/*amo*/.))

help:
	@echo ""
	@echo "Make targets:"
	@echo ""
	@echo "    make all                        run all tests"
	@echo "    make sanity                     run a quick sanity test"
	@echo "    make pass                       run all tests that are expected to pass"
	@echo "    make fail                       run all tests that are expected to fail"
	@echo "    make all TEST=<testname>        run test $(TESTS_DIR)/<testname>"
	@echo "    make rerun                      run all tests that failed or that has not been run"
	@echo "    make rerun_pass                 run all tests expected to pass that failed or that has not been run"
	@echo "    make status                     list result from latest run of each test"
	@echo "    make list_tests                 list all available tests"
	@echo "    make report_coverage            generate coverage report (must run tests with COVER=1 first)"
	@echo "    make clean                      clean all test results"
	@echo "    make help                       print this message"	
	@echo ""
	@echo " Make variables:"
	@echo ""
	@echo "    ENABLE_CCU_MON                  Enable CCU monitor (default : 0)"
	@echo "    ENABLE_MEM_CHECK                Enable check of cache vs memory (default: 0)"
	@echo "    ENABLE_ICACHE_RANDOM_GEN        Enable random ICache transactions during tests (default: 1)"
	@echo "    ENABLE_AXI_ID_PER_PORT          Enable forcing of separate AXI IDs per DCache port (default: 1)"
	@echo "    HAS_LLC                         Use LLC in design (default: 1)"
	@echo "    COVER                           Record coverage data during simulation (default: 0)"
	@echo "    USE_XILINX_SRAM                 Use Xilinx primitives for SRAM (default: 0)"
	@echo "    DEFINES                         Add RTL defines. Available defines:"
	@echo "        TB_AXI_FIXED_DELAY=[0..15]    Add fixed delay to AXI transactions (default: 0)"
	@echo "        TB_AXI_RAND_DELAY=<0,1>       Add random delay to AXI transactions (default: 1)"
	@echo ""

# Run the test(s)

TEST ?= all

# select a test for sanity
sanity : TEST := read_miss
sanity : rtl
	@echo "Test testlist/${TEST}"
	@$(MAKE) --no-print-directory -C testlist/${TEST} all

# run all the tests
ifeq ($(TEST), all)
all: rtl tb
	@-for d in $(TESTLIST); do \
		echo "Test $$d"; \
		$(MAKE) --no-print-directory -C $$d all; \
	done
	@$(MAKE) --no-print-directory status

# run a single test
else
all: rtl
	@if [ -d $(TESTS_DIR)/$(TEST) ]; then \
		echo "Test $(TESTS_DIR)/$(TEST)"; \
		$(MAKE) --no-print-directory -C $(TESTS_DIR)/$(TEST) all; \
	else \
		echo "Test $(TEST) doesn't exist"; false; \
	fi
endif

# run all tests expected to pass
pass: rtl
	@-for d in $(PASS_LIST); do \
		echo "Test $$d"; \
		$(MAKE) --no-print-directory -C $$d all; \
	done
	@$(MAKE) --no-print-directory status

# run all tests expected to fail
fail: rtl
	@-for d in $(FAIL_LIST); do \
		echo "Test $$d"; \
		$(MAKE) --no-print-directory -C $$d all; \
	done
	@$(MAKE) --no-print-directory status

# clean all tests expected to fail
clean_fail:
	@-for d in $(FAIL_LIST); do \
		echo "Cleaning test $$d"; \
		$(MAKE) --no-print-directory -C $$d clean_test; \
	done

# run all tests expected to fail
amo: rtl
	@-for d in $(AMO_LIST); do \
		echo "Test $$d"; \
		$(MAKE) --no-print-directory -C $$d all; \
	done
	@$(MAKE) --no-print-directory status

# run failed or not-executed tests
rerun: rtl
	@-for d in $(TESTLIST); do \
		if [ -e $$d/$(TEST_REPORT) ]; then \
			if grep -q -E "Error|Fatal" $$d/$(TEST_REPORT) ; then \
				echo "Test $$d"; \
				$(MAKE) --no-print-directory -C $$d all; \
			fi; \
		else \
			echo "Test $$d"; \
			$(MAKE) --no-print-directory -C $$d all; \
		fi; \
	done
	@$(MAKE) --no-print-directory status

rerun_pass: rtl
	@-for d in $(PASS_LIST); do \
		if [ -e $$d/$(TEST_REPORT) ]; then \
			if grep -q -E "Error|Fatal" $$d/$(TEST_REPORT) ; then \
				echo "Test $$d"; \
				$(MAKE) --no-print-directory -C $$d all; \
			fi; \
		else \
			echo "Test $$d"; \
			$(MAKE) --no-print-directory -C $$d all; \
		fi; \
	done
	@$(MAKE) --no-print-directory status

# list status
status:
	@for d in $(TESTLIST); do \
		if [ -e $$d/$(TEST_REPORT) ]; then \
			if grep -q -E "Error|Fatal" $$d/$(TEST_REPORT); then \
				printf "%-40s\t : \033[31mFAILED\033[0m\t" $$d; \
				# print error message \
				grep -m 1 -E "Error|Fatal" $$d/$(TEST_REPORT) | cut -c 6-72 | tr -d '\012\015'; \
				# print time \
				grep -m 1 -A1 -E "\* Error|\* Fatal" $$d/$(TEST_LOG) | grep -v -E "\* Error|\* Fatal" | cut -d" " -f3-7; \
			else \
				printf "%-40s\t : \033[32mPASSED\033[0m\n" $$d; \
			fi; \
		else \
			printf "%-40s\t : \033[33mNOT RUN\033[0m\n" $$d; \
		fi; \
	done

list_tests:
	@for d in $(TESTLIST); do printf "$$d\n"; done

# coverage
$(MERGED_UCDB):
	$(VCOVER) merge -out $(MERGED_UCDB) $(COVERAGE_DIR)

report_coverage: $(MERGED_UCDB)
	$(VCOVER) report -details       -codeAll -output $(COVERAGE_REPORT)      $(MERGED_UCDB)
	$(VCOVER) report -details -html -codeAll -output $(COVERAGE_REPORT_HTML) $(MERGED_UCDB)


# Cleanup
clean_tests:
	for d in $(TESTLIST); do $(MAKE) --no-print-directory -C $$d clean_test; done

clean: clean_tests clean_rtl

.PHONY: all pass fail rerun status list_tests clean_tests clean report_coverage clean_fail
