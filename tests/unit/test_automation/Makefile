# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

ROOT_DIR = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
include $(ROOT_DIR)/../../common.mk

SYS_DIR = $(ROOT_DIR)/../sw/sys
LIB_DIR = $(ROOT_DIR)/../libs
INC_DIR = $(ROOT_DIR)/../sw/include
INCLUDES = $(foreach d, $(INC_DIR), -I$d)
INCLUDES += $(foreach d, $(SYS_DIR), -I$d)

TEST_SRCS += $(shell find . -name "*.c" -exec basename {} \;)

# elf file generation

#main.riscv : $(TEST_SRCS) $(LIB_DIR)/libintegr.a $(SYS_DIR)/crt.S $(SYS_DIR)/syscalls.c $(SYS_DIR)/linker.ld
#	$(RV_GCC) -Werror -falign-functions=32 -falign-jumps=32 $(INCLUDES) -L$(LIB_DIR) -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O0 -ffast-math -fno-common -fno-builtin-printf $(SYS_DIR)/syscalls.c -static -nostdlib $(SYS_DIR)/crt.S  -nostartfiles -lm -lgcc -T $(SYS_DIR)/linker.ld $(INCLUDES) -o main.riscv $(TEST_SRCS) -lintegr -Xlinker -Map=main.map

#main.dis : main.riscv
#	$(RV_OBJDUMP) -d main.riscv > main.dis

#dis : main.dis
#
#main.hex : main.riscv
#	$(RV_OBJCOPY) -O verilog main.riscv main.vh
#	../../test_automation/vh2hex.py -m main.vh -o main.hex -b 0x80000000 -d 0x80000000 -i 0x80100000
#	rm main.vh

#sw : main.hex

# Test execution

GUI ?= 0

# the CCU monitor can be disabled by setting ENABLE_CCU_MON=0
# Note: the CCU monitor currently doesn't work when CCU.LatencyMode != NO_LATENCY
ENABLE_CCU_MON ?= 0

# enable check of cache contents vs main memory
ENABLE_MEM_CHECK ?= 0

# Force use of ID per port for AXI data port
ENABLE_AXI_ID_PER_PORT ?= 1

# enable random icache transactions
ENABLE_ICACHE_RANDOM_GEN ?= 1

VSIM_LIB      = ../../work
VERILATOR_LIB = $(ROOT_DIR)/../work_verilate

TOP_LEVEL = culsans_tb
SIM_TCL = sim.tcl

SIM_RUNTIME ?= 30ms
SEED ?= 0

VSIM_FLAGS += -t 1ns -64 -suppress 12110
VSIM_FLAGS += -classdebug
VSIM_FLAGS += -noassertdebug
VSIM_FLAGS += +TESTNAME=$(TESTNAME)
VSIM_FLAGS += +ENABLE_CCU_MON=$(ENABLE_CCU_MON)
VSIM_FLAGS += +ENABLE_MEM_CHECK=$(ENABLE_MEM_CHECK)
VSIM_FLAGS += +ENABLE_ICACHE_RANDOM_GEN=$(ENABLE_ICACHE_RANDOM_GEN)
VSIM_FLAGS += +ENABLE_AXI_ID_PER_PORT=$(ENABLE_AXI_ID_PER_PORT)
VSIM_FLAGS += -sv_seed $(SEED)
# allow adding log in QIS mode
#VSIM_FLAGS += -suppress 12130
# allow calling tasks in final procedure
VSIM_FLAGS += -suppress 2879
# allow declaring a virtual interface without a matching instance of the real interface
VSIM_FLAGS += -permit_unmatched_virtual_intf

ifneq ($(COVER), 0)
    VSIM_FLAGS += -coverage
    VSIM_FLAGS += -coverstore ../../$(COVERAGE_DIR) -testname $(TESTNAME)
endif

#UVM_FLAGS = +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW

ifeq ($(GUI), 0)
	VSIM_FLAGS += -c
	VSIM_CMD = -do "run $(SIM_RUNTIME);"
else
	ifneq ($(GUI), 1)
		$(error GUI must be 0 or 1)
	else
		GTKWAVE_CMD = gtkwave waveform.vcd
	endif
    ifeq ($(USE_VISUALIZER), 1)
		VSIM_FLAGS += -qwavedb=+signal+memory+assertion+cell+class
		VSIM_FLAGS += -visualizer=$(VSIM_LIB)/design.bin
	endif
	VSIM_CMD = -do "source $(SIM_TCL); run $(SIM_RUNTIME);"
endif

ifeq ($(VERILATE), 0)
$(TEST_REPORT):
	@rm -rf $(TEST_REPORT)
	@echo "Running test ..."
	@$(VSIM) $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(UVM_FLAGS) $(TOP_LEVEL)_optimized | tee $(TEST_LOG) > /dev/null
	@if [ -f verify_truth.txt ]; then ../../test_automation/verify_transactions.py; fi
	@if [ -f postproc.sh ]; then ./postproc.sh; fi
ifeq ($(GUI), 0)
	@grep "\*\* Error" $(TEST_LOG) | tee     $(TEST_REPORT) > /dev/null
	@grep "\*\* Fatal" $(TEST_LOG) | tee -a  $(TEST_REPORT) > /dev/null
endif

else
$(TEST_REPORT): main.riscv
	-$(VERILATOR_LIB)/Vculsans_top main.riscv
	$(GTKWAVE_CMD)
endif

all: $(TEST_REPORT)
	@(! grep -s -n -m 1 "Error:" $(TEST_REPORT))
	@(! grep -s -n -m 1 "Fatal:" $(TEST_REPORT))

clean_test:
	rm -rf objs
	rm -rf main.riscv
	rm -rf main.dis
	rm -rf main.hex
	rm -rf *.log
	rm -rf *.vcd
	rm -rf *.dasm
	rm -rf $(TEST_REPORT)
	rm -rf transcript
	rm -rf main.map
	rm -rf ace_log/
	rm -rf axi_log/
	rm -rf vsim.wlf
	rm -rf ../../$(COVERAGE_DIR)/$(TESTNAME)*
	rm -rf .visualizer
	rm -rf qwave.db

.PHONY: all gui sw dis sw clean_test $(TEST_REPORT)
