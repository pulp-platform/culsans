include ../../../common.mk

SYS_DIR = ../../sw/sys
LIB_DIR = ../../libs
INC_DIR = ../../sw/include
INCLUDES = $(foreach d, $(INC_DIR), -I$d)
INCLUDES += $(foreach d, $(SYS_DIR), -I$d)

TEST_SRCS += $(shell find . -name "*.c" -exec basename {} \;)

main.riscv : $(TEST_SRCS) $(LIB_DIR)/libintegr.a $(SYS_DIR)/crt.S $(SYS_DIR)/syscalls.c $(SYS_DIR)/linker.ld
	$(GCC) -Werror $(INCLUDES) -L$(LIB_DIR) -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O0 -ffast-math -fno-common -fno-builtin-printf $(SYS_DIR)/syscalls.c -static -nostdlib $(SYS_DIR)/crt.S  -nostartfiles -lm -lgcc -T $(SYS_DIR)/linker.ld $(INCLUDES) -o main.riscv $(TEST_SRCS) -lintegr

main.dis : main.riscv
	$(OBJDUMP) -d main.riscv > main.dis

dis : main.dis

main.hex : main.riscv
	riscv64-unknown-elf-objcopy -O verilog main.riscv main.vh
	../../test_automation/vh2hex.py -i main.vh -o main.hex -p 0x02000000 -d 0x01000000
	rm main.vh

sw : main.hex

result.rpt: main.hex
	rm -rf result.rpt
	$(VSIM) -do test.tcl > test.log
	if [ -f postproc.sh ]; then ./postproc.sh; fi
#	cat result.rpt

all: result.rpt

gui:
	$(VSIM) -gui -do test.tcl

gui:

clean:
	rm -rf objs
	rm -rf main.riscv
	rm -rf main.dis
	rm -rf main.hex
	rm -rf result.rpt

.PHONY: all gui sw dis sw clean