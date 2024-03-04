ROOT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
include ../../../common.mk
include ../../../rtl.mk

SYS_DIR = ../../sw/sys
LIB_DIR = ../../libs
INC_DIR = ../../sw/include
INCLUDES = $(foreach d, $(INC_DIR), -I$d)
INCLUDES += $(foreach d, $(SYS_DIR), -I$d)

TEST_SRCS += $(shell find . -name "*.c" -exec basename {} \;)

# elf file generation

main.riscv : $(TEST_SRCS) $(LIB_DIR)/libintegr.a $(SYS_DIR)/crt.S $(SYS_DIR)/syscalls.c $(SYS_DIR)/linker.ld
	$(RV_GCC) -Werror -g 		-falign-functions=32 -falign-jumps=32 $(INCLUDES) -L$(LIB_DIR) -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O3 -g -ffast-math -fno-common -fno-builtin-printf $(SYS_DIR)/syscalls.c -static -nostdlib $(SYS_DIR)/crt.S  -nostartfiles -lm -lgcc -T $(SYS_DIR)/linker.ld $(INCLUDES) -o main.riscv $(TEST_SRCS) -lintegr -Xlinker -Map=main.map

main.dis : main.riscv
	$(RV_OBJDUMP) -d main.riscv > main.dis

dis : main.dis

main.hex : main.riscv
	$(RV_OBJCOPY) -O verilog main.riscv main.vh
	../../test_automation/vh2hex.py -m main.vh -o main.hex -b 0x80000000 -d 0x80000000 -i 0x80100000
	rm main.vh

sw : main.hex

# Test execution
TESTNAME := $(notdir $(patsubst %/,%,$(ROOT_DIR)))

GUI ?= 0

# the CCU monitor can be disabled by setting ENABLE_CCU_MON=0
# Note: the CCU monitor currently doesn't work when CCU.LatencyMode != NO_LATENCY
ENABLE_CCU_MON ?= 0

# enable check of cache contents vs main memory (disable if LLC is present)
ENABLE_MEM_CHECK ?= 0

VSIM_LIB = ../../work
VERILATOR_LIB = ../../work_verilate

TOP_LEVEL = culsans_tb
SIM_TCL = sim.tcl
SIM_RUNTIME ?= 100ms


#UVM_FLAGS = +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW
VSIM_FLAGS += -t 1ns -64 -classdebug
VSIM_FLAGS += -suppress 12110
VSIM_FLAGS += +TESTNAME=$(TESTNAME)
VSIM_FLAGS += +ENABLE_CCU_MON=$(ENABLE_CCU_MON)
VSIM_FLAGS += +ENABLE_MEM_CHECK=$(ENABLE_MEM_CHECK)

ifneq ($(COVER), 0)
    VSIM_FLAGS += -coverage
    VSIM_FLAGS += -coverstore ../../$(COVERAGE_DIR) -testname $(TESTNAME)
endif

ifeq ($(GUI), 0)
	VSIM_FLAGS += -c
	VSIM_CMD = -do "run $(SIM_RUNTIME);"
else
	ifneq ($(GUI), 1)
		$(error GUI must be 0 or 1)
	else
		GTKWAVE_CMD = gtkwave waveform.vcd
	endif
	VSIM_CMD = -do "source $(SIM_TCL); run $(SIM_RUNTIME);"
endif

ifeq ($(VERILATE), 0)
$(TEST_REPORT): main.hex
	@rm -rf $(TEST_REPORT)
	@$(VSIM) $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(UVM_FLAGS) $(TOP_LEVEL)_optimized | tee sim.log > /dev/null
	@if [[ "$$PWD" =~ integration ]]; then \
		if [ -f test.yaml ]; then \
			python3.6 ../../test_automation/testParser.py; \
		fi \
	fi
	@if [ -f postproc.sh ]; then ./postproc.sh; fi
	@grep "\*\* Error" sim.log  | tee -a  $(TEST_REPORT) > /dev/null
	@grep "\*\* Fatal" sim.log  | tee -a  $(TEST_REPORT) > /dev/null
else
$(TEST_REPORT): main.riscv
	-$(VERILATOR_LIB)/Vculsans_top main.riscv
	$(GTKWAVE_CMD)
endif

all: $(TEST_REPORT)
	@cat $(TEST_REPORT)
	@(! grep -s -n -m 1 "Error:" $(TEST_REPORT))
	@(! grep -s -n -m 1 "Fatal:" $(TEST_REPORT))
	@(! grep -s -n -m 1 "FAIL" $(TEST_REPORT))


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
	rm -rf ../../$(COVERAGE_DIR)/$(TESTNAME)*

.PHONY: all gui sw dis sw clean_test
