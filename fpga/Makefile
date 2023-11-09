BOARD          ?= genesys2

VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source scripts/prologue.tcl

NB_CORES = 2

ifneq ($(NB_CORES), 2)
$(error "NB_CORES must be 2")
endif

target = cv64a6_imafdc_sv39_wb
include ../modules/cva6/Makefile
CLK_PERIOD_NS  := 25

CVA6_DIR = $(root-dir)
LLC_DIR = ../modules/axi_llc


# Compile the RTL

work-dir := work-fpga
bit := $(work-dir)/culsans_xilinx.bit
ip-dir := xilinx
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

LLC_PKG := src/axi_llc_pkg.sv \
           src/axi_llc_reg_pkg.sv
LLC_PKG := $(addprefix $(LLC_DIR)/, $(LLC_PKG))

LLC_SRC := src/axi_llc_burst_cutter.sv \
            src/axi_llc_data_way.sv \
            src/axi_llc_merge_unit.sv \
            src/axi_llc_read_unit.sv \
            src/axi_llc_reg_top.sv \
            src/axi_llc_write_unit.sv \
            src/eviction_refill/axi_llc_ax_master.sv \
            src/eviction_refill/axi_llc_r_master.sv \
            src/eviction_refill/axi_llc_w_master.sv \
            src/hit_miss_detect/axi_llc_evict_box.sv \
            src/hit_miss_detect/axi_llc_lock_box_bloom.sv \
            src/hit_miss_detect/axi_llc_miss_counters.sv \
            src/hit_miss_detect/axi_llc_tag_pattern_gen.sv \
            src/axi_llc_chan_splitter.sv \
            src/axi_llc_evict_unit.sv \
            src/axi_llc_refill_unit.sv \
            src/axi_llc_ways.sv \
            src/hit_miss_detect/axi_llc_tag_store.sv \
            src/axi_llc_config.sv \
            src/axi_llc_hit_miss.sv \
            src/axi_llc_top.sv \
            src/axi_llc_reg_wrap.sv
LLC_SRC := $(addprefix $(LLC_DIR)/, $(LLC_SRC))

CULSANS_DIR := ../rtl
CULSANS_PKG := $(wildcard $(CULSANS_DIR)/include/*_pkg.sv)

CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ace_intf.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/snoop_intf.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ccu_fsm.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ace_trs_dec.sv
CULSANS_SRC += $(CVA6_DIR)/vendor/planv/ace/src/ace_ccu_top.sv
CULSANS_SRC += $(CULSANS_DIR)/src/culsans_xilinx.sv

TOP_LEVEL := culsans_xilinx

fpga_filter += $(addprefix $(CVA6_DIR), corev_apu/fpga/src/ariane_xilinx.sv)
fpga_filter += $(wildcard $(addprefix $(CVA6_DIR), corev_apu/tb/ariene_*.sv))

all: $(bit)

$(bit): $(ips) scripts/add_sources.tcl $(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_regmap.sv
	@echo "[FPGA] Generate Bitstream"
	@mkdir -p $(work-dir)
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

scripts/add_sources.tcl: $(ariane_pkg) $(src) $(fpga_src) $(uart_src) $(src_flist) $(LLC_PKG) $(CULSANS_PKG) $(LLC_SRC)  $(CULSANS_SRC)
	make CORES=2 PYTHON=python3 -C $(CVA6_DIR)/corev_apu/bootrom clean all
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(uart_src)}                                          > scripts/add_sources.tcl
	@echo read_verilog -sv {$(LLC_PKG)}                                          >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(ariane_pkg)}                                       >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src_flist))}		>> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src))} 	              >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(CULSANS_PKG)}                                      >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(fpga_src))}           >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(LLC_SRC))}            >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(CULSANS_SRC))} 	>> scripts/add_sources.tcl

.PHONY: clean

clean:
	rm -rf *.log *.jou *.str *.mif *.xpr $(work-dir) *.cache *.hw *.ip_user_files *.runs *.sim scripts/vivado* scripts/add_sources.tcl
