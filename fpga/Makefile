BOARD          ?= genesys2

VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source scripts/prologue.tcl

NB_CORES = 2

ifneq ($(NB_CORES), 2)
$(error "NB_CORES must be 2")
endif

include ../modules/cva6/Makefile

CVA6_DIR = $(root-dir)

# Compile the RTL

work-dir := work-fpga
bit := $(work-dir)/culsans_xilinx.bit
ip-dir := $(CVA6_DIR)/corev_apu/fpga/xilinx
ips := xlnx_axi_clock_converter.xci  \
       xlnx_axi_dwidth_converter.xci \
       xlnx_axi_dwidth_converter_dm_master.xci \
       xlnx_axi_dwidth_converter_dm_slave.xci \
       xlnx_axi_quad_spi.xci         \
       xlnx_axi_gpio.xci             \
       xlnx_clk_gen.xci              \
       xlnx_ila.xci              \
       xlnx_mig_7_ddr3.xci

ips := $(addprefix $(work-dir)/, $(ips))
ips-target := $(join $(addsuffix /ip/, $(addprefix $(ip-dir)/, $(basename $(ips)))), $(ips))

CULSANS_DIR := ../rtl
CULSANS_PKG := $(wildcard $(CULSANS_DIR)/include/*_pkg.sv)

CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ace_intf.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/snoop_intf.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ccu_fsm.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ace_trs_dec.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ace_ccu_top.sv
CULSANS_SRC += $(CULSANS_DIR)/src/culsans_peripherals.sv
CULSANS_SRC += $(CULSANS_DIR)/src/culsans_xilinx.sv

CULSANS_INCDIR := $(CULSANS_DIR)/include
CULSANS_INCDIR := $(foreach dir, ${CULSANS_INCDIR}, +incdir+$(dir))

TOP_LEVEL := culsans_xilinx

fpga_filter += $(addprefix $(CVA6_DIR), corev_apu/fpga/src/ariane_xilinx.sv)
fpga_filter += $(wildcard $(addprefix $(CVA6_DIR), corev_apu/tb/*.sv))
fpga_filter += $(wildcard $(addprefix $(CVA6_DIR), corev_apu/tb/*/*.sv))

all: $(bit)

$(bit): $(ips) scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	@mkdir -p $(work-dir)
	@cp -r $(ip-dir) .
	export BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS=$(CLK_PERIOD_NS); \
	$(VIVADO) $(VIVADOFLAGS) -source scripts/run.tcl
	#cp ariane.runs/impl_1/culsans_xilinx* ./$(work-dir)

$(ips): %.xci :
	mkdir -p $(work-dir)
	@echo Generating $(@F)
	@cd $(ip-dir)/$(basename $(@F)) && make clean && make BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS=$(CLK_PERIOD_NS)
	@cp $(ip-dir)/$(basename $(@F))/$(basename $(@F)).srcs/sources_1/ip/$(basename $(@F))/$(@F) $@

# Check that RTL and SW are aligned with the NB_CORES setting
RTL_NBCORES_DEF = "localparam NB_CORES = $(NB_CORES);"
.PHONY: $(CULSANS_DIR)/include/culsans_pkg.sv
$(CULSANS_DIR)/include/culsans_pkg.sv:
	@if ! grep -q $(RTL_NBCORES_DEF) $@; then \
		sed -i 's/localparam NB_CORES = [0-9]\+;/localparam NB_CORES = $(NB_CORES);/' $(CULSANS_DIR)/include/culsans_pkg.sv; \
	fi

.PHONY: $(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_regmap.sv
$(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_regmap.sv:
	cd $$(dirname $@); \
	python3 gen_plic_addrmap.py -t $$(($(NB_CORES)*2)) > plic_regmap.sv

scripts/add_sources.tcl: $(ariane_pkg) $(src) $(fpga_src) $(uart_src) $(src_flist) $(CULSANS_PKG) $(CULSANS_SRC)
	make CORES=2 PYTHON=python3 -C $(CVA6_DIR)/corev_apu/bootrom clean all
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(uart_src)}                                          > scripts/add_sources.tcl
	@echo read_verilog -sv {$(ariane_pkg)}                                       >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src_flist))}		>> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src))} 	              >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(CULSANS_PKG)}                                      >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(CULSANS_SRC))} 	>> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(fpga_src))}           >> scripts/add_sources.tcl

.PHONY: clean

clean:
	rm -rf *.log *.jou *.str *.mif *.xpr $(work-dir) *.cache *.hw *.ip_user_files *.runs *.sim scripts/vivado* scripts/add_sources.tcl
