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
ENABLE_CCU_MON ?= 1

VSIM_LIB      = ../../work
VERILATOR_LIB = $(ROOT_DIR)/../work_verilate

TOP_LEVEL = culsans_tb
SIM_TCL = sim.tcl

VSIM_FLAGS += -voptargs=+acc -t 1ns -64 -suppress 12110
VSIM_FLAGS += -suppress 2879       # allow calling tasks in final procedure
VSIM_FLAGS += -classdebug
VSIM_FLAGS += -permit_unmatched_virtual_intf # allow declaring a virtual interface without a matching instance of the real interface
VSIM_FLAGS += +TESTNAME=$(TESTNAME)
VSIM_FLAGS += +ENABLE_CCU_MON=$(ENABLE_CCU_MON)
#VSIM_FLAGS += -coverage

#UVM_FLAGS = +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW

ifeq ($(GUI), 0)
	VSIM_FLAGS += -c
else
	ifneq ($(GUI), 1)
		$(error GUI must be 0 or 1)
	else
		GTKWAVE_CMD = gtkwave waveform.vcd
	endif
endif
VSIM_CMD = -do $(SIM_TCL)

ifeq ($(VERILATE), 0)
$(TEST_REPORT):
	rm -rf $(TEST_REPORT)
	$(VSIM) $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(UVM_FLAGS) $(TOP_LEVEL) | tee sim.log
	@if [ -f verify_truth.txt ]; then ../../test_automation/verify_transactions.py; fi
	@if [ -f postproc.sh ]; then ./postproc.sh; fi
	@grep "\*\* Error" sim.log  | tee     $(TEST_REPORT) > /dev/null
	@grep "\*\* Fatal" sim.log  | tee -a  $(TEST_REPORT) > /dev/null

else
$(TEST_REPORT): main.riscv
	-$(VERILATOR_LIB)/Vculsans_top main.riscv
	$(GTKWAVE_CMD)
endif

all: $(TEST_REPORT)
	(! grep -n "Error:" $(TEST_REPORT))
	(! grep -n "Fatal:" $(TEST_REPORT))

clean:
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

.PHONY: all gui sw dis sw clean $(TEST_REPORT)
