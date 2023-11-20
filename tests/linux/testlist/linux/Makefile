ROOT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
include ../../../common.mk

# elf file processing

fw_payload.dis : fw_payload.elf
	$(RV_OBJDUMP) -d fw_payload.elf > fw_payload.dis

dis : fw_payload.dis

main.hex : fw_payload.elf
	$(RV_OBJCOPY) -O verilog fw_payload.elf main.vh
	../../test_automation/vh2hex.py -m main.vh -o main.hex -b 0x80000000 -d 0x80000000 -i 0x80100000
	rm main.vh

sw : main.hex

# Test execution
TESTNAME := $(notdir $(patsubst %/,%,$(ROOT_DIR)))

GUI ?= 0

VSIM_LIB = ../../work

TOP_LEVEL = culsans_tb
SIM_TCL = sim.tcl
SIM_RUNTIME ?= 100ms


#UVM_FLAGS = +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW
VSIM_FLAGS = -t 1ns -64 -classdebug
VSIM_FLAGS = -suppress 12110

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

$(TEST_REPORT): main.hex
	rm -rf $(TEST_REPORT)
	$(VSIM) $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(UVM_FLAGS) $(TOP_LEVEL)_optimized | tee sim.log
	@if [[ "$$PWD" =~ integration ]]; then \
		if [ -f test.yaml ]; then \
			python3.6 ../../test_automation/testParser.py; \
		fi \
	fi
	@if [ -f postproc.sh ]; then ./postproc.sh; fi
all: $(TEST_REPORT)
	@cat $(TEST_REPORT)
	@(! grep -q -n "FAIL" $(TEST_REPORT))

clean:
	rm -rf objs
	rm -rf *.dis
	rm -rf *.hex
	rm -rf *.log
	rm -rf *.vcd
	rm -rf *.dasm
	rm -rf $(TEST_REPORT)
	rm -rf transcript
	rm -rf ace_log/
	rm -rf axi_log/
	rm -rf ../../$(COVERAGE_DIR)/$(TESTNAME)*

.PHONY: all gui sw dis sw clean
