include ../../../common.mk

SYS_DIR = ../../sw/sys
LIB_DIR = ../../libs
INC_DIR = ../../sw/include
INCLUDES = $(foreach d, $(INC_DIR), -I$d)
INCLUDES += $(foreach d, $(SYS_DIR), -I$d)

TEST_SRCS += $(shell find . -name "*.c" -exec basename {} \;)

# elf file generation

main.riscv : $(TEST_SRCS) $(LIB_DIR)/libintegr.a $(SYS_DIR)/crt.S $(SYS_DIR)/syscalls.c $(SYS_DIR)/linker.ld
	$(RV_GCC) -Werror -g 		-falign-functions=32 -falign-jumps=32 $(INCLUDES) -L$(LIB_DIR) -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O0 -g -ffast-math -fno-common -fno-builtin-printf $(SYS_DIR)/syscalls.c -static -nostdlib $(SYS_DIR)/crt.S  -nostartfiles -lm -lgcc -T $(SYS_DIR)/linker.ld $(INCLUDES) -o main.riscv $(TEST_SRCS) -lintegr -Xlinker -Map=main.map

main.dis : main.riscv
	$(RV_OBJDUMP) -d main.riscv > main.dis

dis : main.dis

main.hex : main.riscv
	$(RV_OBJCOPY) -O verilog main.riscv main.vh
	../../test_automation/vh2hex.py -m main.vh -o main.hex -b 0x80000000 -d 0x80000000 -i 0x80100000
	rm main.vh

sw : main.hex

# Test execution

GUI ?= 0

VSIM_LIB = ../../work
VERILATOR_LIB = ../../work_verilate

TOP_LEVEL = culsans_tb
SIM_TCL = sim.tcl

#UVM_FLAGS = +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW
VSIM_FLAGS = -t 1ns -64 -coverage -classdebug
VSIM_FLAGS = -voptargs=+acc -t 1ns -64 -suppress 12110

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
$(TEST_REPORT): main.hex
	rm -rf $(TEST_REPORT)
	$(VSIM) $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(UVM_FLAGS) $(TOP_LEVEL) | tee sim.log
	python3.6 ../../test_automation/testParser.py
	if [ -f postproc.sh ]; then ./postproc.sh; fi
else
$(TEST_REPORT): main.riscv
	-$(VERILATOR_LIB)/Vculsans_top main.riscv
	$(GTKWAVE_CMD)
endif

all: $(TEST_REPORT)
	@cat $(TEST_REPORT)

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

.PHONY: all gui sw dis sw clean
