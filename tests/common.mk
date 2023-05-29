# Common variables
SPIKE_ROOT ?= /opt/riscv-isa-sim
RISCV ?= /opt/riscv
TEST_REPORT = result.rpt

RV_TOOL_PREFIX = riscv64-unknown-elf-
RV_GCC := $(RV_TOOL_PREFIX)gcc
RV_AR := $(RV_TOOL_PREFIX)ar
RV_OBJDUMP := $(RV_TOOL_PREFIX)objdump
RV_OBJCOPY := $(RV_TOOL_PREFIX)objcopy

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
#        EXECUTABLES += VERILATOR
endif

K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

GCC_VERSION := $(shell gcc -dumpversion)
ifneq ($(GCC_VERSION), 8)
$(error "Wrong gcc version - try "scl enable devtoolset-8 bash")
endif

# Check number of cores

NB_CORES ?= 2

ifneq ($(NB_CORES), 2)
ifneq ($(NB_CORES), 4)
$(error "NB_CORES must be 2 or 4")
endif
endif

