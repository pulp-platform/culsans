RV_TOOL_PREFIX = riscv64-unknown-elf-
GCC := $(RV_TOOL_PREFIX)gcc
AR := $(RV_TOOL_PREFIX)ar
OBJDUMP := $(RV_TOOL_PREFIX)objdump

VSIM = vsim
VLOG = vlog
VOPT = vopt
VCOM = vcom
VLIB = vlib
VMAP = vmap

VERILATOR = verilator

VERILATE ?= 0

# Check tools - inspired by https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile

EXECUTABLES = $(GCC) 
#EXECUTABLES += $(VSIM) 
ifeq ($(VERILATE), 1)
        EXECUTABLES += VERILATOR
endif

K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

# Common variables

TEST_REPORT = result.rpt