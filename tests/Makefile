include common.mk

TEST ?= all

ifeq ($(TEST), all)
	TEST_SELECT := all
else
	TEST_SELECT := TEST=$(TEST)
endif

# Test execution

unit:
	echo make -C unit $(TEST_SELECT)

integr:
	echo make -C integration $(TEST_SELECT)

perf:
	echo make -C perf $(TEST_SELECT)

fpga:
	echo make -C fpga $(TEST_SELECT)

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