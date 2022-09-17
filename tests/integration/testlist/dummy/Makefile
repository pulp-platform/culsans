include ../../../common.mk

SYS_DIR = ../../sw/sys
LIB_DIR = ../../libs
INC_DIR = ../../sw/include
INCLUDES = $(foreach d, $(INC_DIR), -I$d)
INCLUDES += $(foreach d, $(SYS_DIR), -I$d)

TEST_SRCS += $(shell find . -name "*.c" -exec basename {} \;)

# elf file generation

main.riscv : $(TEST_SRCS) $(LIB_DIR)/libintegr.a $(SYS_DIR)/crt.S $(SYS_DIR)/syscalls.c $(SYS_DIR)/linker.ld
	$(GCC) -Werror $(INCLUDES) -L$(LIB_DIR) -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O0 -ffast-math -fno-common -fno-builtin-printf $(SYS_DIR)/syscalls.c -static -nostdlib $(SYS_DIR)/crt.S  -nostartfiles -lm -lgcc -T $(SYS_DIR)/linker.ld $(INCLUDES) -o main.riscv $(TEST_SRCS) -lintegr

main.dis : main.riscv
	$(OBJDUMP) -d main.riscv > main.dis

dis : main.dis

main.hex : main.riscv
	riscv64-unknown-elf-objcopy -O verilog main.riscv main.vh
	../../test_automation/vh2hex.py -i main.vh -o main.hex -b 0x080000000
	rm main.vh

sw : main.hex

# Test execution

GUI ?= 0

VSIM_LIB = ../../work
TOP_LEVEL = culsans_tb
SIM_TCL = sim.tcl

UVM_FLAGS = +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW
VSIM_FLAGS = -t 1ns -64 -coverage -classdebug
ifeq ($(GUI), 0)
	VSIM_FLAGS += -c
else
	ifneq ($(GUI), 1)
		$(error GUI must be 0 or 1)
	endif
endif
VSIM_CMD = -do $(SIM_TCL)

$(TEST_REPORT): main.hex
	rm -rf $(TEST_REPORT)
	$(VSIM) +permissive $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(UVM_FLAGS) $(TOP_LEVEL) +permissive-off | tee sim.log
	if [ -f postproc.sh ]; then ./postproc.sh; fi
	cat $(TEST_REPORT)

all: $(TEST_REPORT)

clean:
	rm -rf objs
	rm -rf main.riscv
	rm -rf main.dis
	rm -rf main.hex
	rm -rf $(TEST_REPORT)

.PHONY: all gui sw dis sw clean
