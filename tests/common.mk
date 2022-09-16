RV_TOOL_PREFIX = riscv64-unknown-elf-
GCC := $(RV_TOOL_PREFIX)gcc
AR := $(RV_TOOL_PREFIX)ar
OBJDUMP := $(RV_TOOL_PREFIX)objdump

VSIM = vsim

# Check tools - inspired by https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile

EXECUTABLES = $(GCC) #$(VSIM) 

K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))
