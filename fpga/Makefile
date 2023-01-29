BOARD          ?= genesys2

# setting additional xilinx board parameters for the selected board
ifeq ($(BOARD), genesys2)
	XILINX_PART              := xc7k325tffg900-2
	XILINX_BOARD             := digilentinc.com:genesys2:part0:1.1
	CLK_PERIOD_NS            := 20
else ifeq ($(BOARD), kc705)
	XILINX_PART              := xc7k325tffg900-2
	XILINX_BOARD             := xilinx.com:kc705:part0:1.5
	CLK_PERIOD_NS            := 20
else ifeq ($(BOARD), vc707)
	XILINX_PART              := xc7vx485tffg1761-2
	XILINX_BOARD             := xilinx.com:vc707:part0:1.3
	CLK_PERIOD_NS            := 20
else
$(error Unknown board - please specify a supported FPGA board)
endif

VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source scripts/prologue.tcl

NB_CORES = 2

ifneq ($(NB_CORES), 2)
$(error "NB_CORES must be 2")
endif

# Compile the RTL

CVA6_DIR = ../modules/cva6
AXI_DIR = $(CVA6_DIR)/corev_apu/axi/

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
       xlnx_mig_7_ddr3.xci

ips := $(addprefix $(work-dir)/, $(ips))
ips-target := $(join $(addsuffix /ip/, $(addprefix $(ip-dir)/, $(basename $(ips)))), $(ips))

# Common cells

COMMON_PKG := $(CVA6_DIR)/common/submodules/common_cells/src/cf_math_pkg.sv
COMMON_SRC := $(CVA6_DIR)/common/submodules/common_cells/src/rstgen_bypass.sv                          \
	        $(CVA6_DIR)/common/submodules/common_cells/src/rstgen.sv                                 \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_mux.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_demux.sv                           \
	        $(CVA6_DIR)/common/submodules/common_cells/src/exp_backoff.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/addr_decode.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_register.sv                        \
	        $(CVA6_DIR)/common/submodules/common_cells/src/unread.sv                                 \
	        $(CVA6_DIR)/common/submodules/common_cells/src/sync.sv                                   \
	        $(CVA6_DIR)/common/submodules/common_cells/src/cdc_2phase.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/spill_register_flushable.sv               \
	        $(CVA6_DIR)/common/submodules/common_cells/src/spill_register.sv                         \
	        $(CVA6_DIR)/common/submodules/common_cells/src/sync_wedge.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/edge_detect.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_arbiter.sv                         \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_arbiter_flushable.sv               \
	        $(CVA6_DIR)/common/submodules/common_cells/src/deprecated/fifo_v1.sv                     \
	        $(CVA6_DIR)/common/submodules/common_cells/src/deprecated/fifo_v2.sv                     \
	        $(CVA6_DIR)/common/submodules/common_cells/src/fifo_v3.sv                                \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lzc.sv                                    \
	        $(CVA6_DIR)/common/submodules/common_cells/src/popcount.sv                               \
	        $(CVA6_DIR)/common/submodules/common_cells/src/rr_arb_tree.sv                            \
	        $(CVA6_DIR)/common/submodules/common_cells/src/deprecated/rrarbiter.sv                   \
	        $(CVA6_DIR)/common/submodules/common_cells/src/stream_delay.sv                           \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lfsr.sv                                   \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lfsr_8bit.sv                              \
	        $(CVA6_DIR)/common/submodules/common_cells/src/lfsr_16bit.sv                             \
	        $(CVA6_DIR)/common/submodules/common_cells/src/delta_counter.sv                          \
	        $(CVA6_DIR)/common/submodules/common_cells/src/counter.sv                                \
	        $(CVA6_DIR)/common/submodules/common_cells/src/shift_reg.sv

# AXI

# AXI packages
AXI_PKG := src/axi_pkg.sv \
						src/ace_pkg.sv \
						src/snoop_pkg.sv
AXI_PKG := $(addprefix $(AXI_DIR)/, $(AXI_PKG))

AXI_SRC := src/axi_cut.sv                                                 \
	          src/axi_join.sv                                                \
	          src/axi_delayer.sv                                             \
	          src/axi_to_axi_lite.sv                                         \
	          src/axi_id_prepend.sv                                          \
	          src/axi_atop_filter.sv                                         \
	          src/axi_err_slv.sv                                             \
	          src/axi_mux.sv                                                 \
	          src/axi_demux.sv                                               \
						src/axi_multicut.sv                                            \
	          src/axi_intf.sv \
	          src/ace_intf.sv \
	          src/snoop_intf.sv \
	          src/axi_xbar.sv \
	          src/ace_trs_dec.sv \
	          src/ccu_fsm.sv \
	          src/ace_ccu_top.sv
AXI_SRC := $(addprefix $(AXI_DIR)/, $(AXI_SRC))

#AXI_INCDIR := $(AXI_DIR)/include
#AXI_INCDIR := $(foreach dir, ${AXI_INCDIR}, +incdir+$(dir))

# CVA6

# CVA6 packages
CVA6_PKG := core/include/cv64a6_imafdc_sv39_config_pkg.sv
CVA6_PKG += core/include/riscv_pkg.sv                              \
              corev_apu/riscv-dbg/src/dm_pkg.sv                      \
              core/include/ariane_pkg.sv                             \
              core/include/ariane_rvfi_pkg.sv                        \
              core/include/wt_cache_pkg.sv                           \
              core/include/cvxif_pkg.sv                              \
              corev_apu/register_interface/src/reg_intf.sv           \
							corev_apu/tb/rvfi_pkg.sv                               \
              core/include/ariane_axi_pkg.sv                         \
              core/include/ariane_ace_pkg.sv                         \
              core/include/std_cache_pkg.sv                          \
              core/fpu/src/fpnew_pkg.sv                              \
              core/cvxif_example/include/cvxif_instr_pkg.sv          \
              core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv \
							corev_apu/tb/ariane_soc_pkg.sv
CVA6_PKG := $(addprefix $(CVA6_DIR)/, $(CVA6_PKG))

# utility modules
UTIL := core/include/instr_tracer_pkg.sv                              \
        common/local/util/instr_tracer_if.sv                          \
        common/local/util/instr_tracer.sv                             \
        corev_apu/tb/common/mock_uart.sv                              \
        common/local/util/sram.sv
UTIL := $(addprefix $(CVA6_DIR)/, $(UTIL))

# CVA6 standalone components
CVA6_SRC := $(filter-out $(CVA6_DIR)/core/ariane_regfile.sv, $(wildcard $(CVA6_DIR)/core/*.sv))                  \
	        $(filter-out $(CVA6_DIR)/core/fpu/src/fpnew_pkg.sv, $(wildcard $(CVA6_DIR)/core/fpu/src/*.sv))       \
	        $(filter-out $(CVA6_DIR)/core/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv,         \
	        $(wildcard $(CVA6_DIR)/core/fpu/src/fpu_div_sqrt_mvp/hdl/*.sv))                          \
	        $(wildcard $(CVA6_DIR)/core/frontend/*.sv)                                               \
	        $(filter-out $(CVA6_DIR)/core/cache_subsystem/std_no_dcache.sv,                          \
	        $(wildcard $(CVA6_DIR)/core/cache_subsystem/*.sv))                                       \
	        $(wildcard $(CVA6_DIR)/corev_apu/bootrom/*.sv)                                           \
	        $(wildcard $(CVA6_DIR)/corev_apu/clint/*.sv)                                             \
	        $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/axi2apb/src/*.sv)                              \
	        $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/apb_timer/*.sv)                                \
	        $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/axi_slice/src/*.sv)                            \
	        $(wildcard $(CVA6_DIR)/corev_apu/src/axi_riscv_atomics/src/*.sv)                         \
	        $(wildcard $(CVA6_DIR)/corev_apu/axi_mem_if/src/*.sv)                                    \
	        $(wildcard $(CVA6_DIR)/core/pmp/src/*.sv)                                                \
	        $(wildcard $(CVA6_DIR)/core/cvxif_example/*.sv)                                          \
					$(wildcard $(CVA6_DIR)/core/mmu_sv39/*.sv)												 \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/rv_plic_target.sv                                      \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/rv_plic_gateway.sv                                     \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_regmap.sv                                         \
	        $(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_top.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dmi_cdc.sv                                           \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dmi_jtag.sv                                          \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dmi_jtag_tap.sv                                      \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_csrs.sv                                           \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_mem.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_sba.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/src/dm_top.sv                                            \
	        $(CVA6_DIR)/corev_apu/riscv-dbg/debug_rom/debug_rom.sv                                   \
	        $(CVA6_DIR)/corev_apu/register_interface/src/apb_to_reg.sv                               \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/deprecated/cluster_clk_cells.sv         \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/deprecated/pulp_clk_cells.sv            \
	        $(CVA6_DIR)/common/local/util/tc_sram_wrapper.sv                                         \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/rtl/tc_sram.sv                          \
	        $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/rtl/tc_clk.sv                           \
	        $(CVA6_DIR)/corev_apu/tb/rvfi_tracer.sv                                                  \
	        $(CVA6_DIR)/corev_apu/tb/common/uart.sv

#	        $(CVA6_DIR)/corev_apu/tb/common/SimDTM.sv                                                \
#	        $(CVA6_DIR)/corev_apu/tb/common/SimJTAG.sv
#CVA6_SRC := $(addprefix $(CVA6_DIR)/, $(CVA6_SRC))

COPRO_SRC := $(CVA6_DIR)/core/cvxif_example/include/cvxif_instr_pkg.sv \
             $(wildcard $(CVA6_DIR)/core/cvxif_example/*.sv)

UART_SRC := $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/apb_uart/src/*.vhd)

#CVA6_INCDIR := common/submodules/common_cells/include/ corev_apu/axi/include/ corev_apu/register_interface/include/
#CVA6_INCDIR := $(addprefix $(CVA6_DIR)/, $(CVA6_INCDIR))
#CVA6_INCDIR := $(foreach dir, ${CVA6_INCDIR}, +incdir+$(dir))

FPGA_SRC :=  $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/*.sv) $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/bootrom/*.sv) $(wildcard $(CVA6_DIR)/corev_apu/fpga/src/ariane-ethernet/*.sv) $(CVA6_DIR)/corev_apu/src/tech_cells_generic/src/fpga/tc_sram_xilinx.sv $(CVA6_DIR)/common/local/util/tc_sram_xilinx_wrapper.sv

CULSANS_DIR := ../rtl
CULSANS_PKG := $(wildcard $(CULSANS_DIR)/include/*_pkg.sv)
CULSANS_SRC := $(wildcard $(CULSANS_DIR)/src/*.sv)
#CULSANS_INCDIR := $(CULSANS_DIR)/include
#CULSANS_INCDIR := $(foreach dir, ${CULSANS_INCDIR}, +incdir+$(dir))

FPGA_FILTER := $(addprefix $(CVA6_DIR), corev_apu/bootrom/bootrom.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), core/include/instr_tracer_pkg.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), src/util/ex_trace_item.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), src/util/instr_trace_item.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), common/local/util/instr_tracer_if.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), common/local/util/instr_tracer.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), corev_apu/src/tech_cells_generic/src/rtl/tc_sram.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), common/local/util/tc_sram_wrapper.sv)
FPGA_FILTER += $(addprefix $(CVA6_DIR), corev_apu/fpga/src/ariane_xilinx.sv)

TOP_LEVEL := culsans_xilinx

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
		sed -i 's/localparam NB_CORES = [0-9]\+;/localparam NB_CORES = $(NB_CORES);/' ../../rtl/include/culsans_pkg.sv; \
	fi

.PHONY: $(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_regmap.sv
$(CVA6_DIR)/corev_apu/rv_plic/rtl/plic_regmap.sv:
	cd $$(dirname $@); \
	python3 gen_plic_addrmap.py -t $$(($(NB_CORES)*2)) > plic_regmap.sv

scripts/add_sources.tcl: $(COMMON_PKG) $(CVA6_PKG) $(AXI_PKG) $(CULSANS_PKG) $(COMMON_SRC) $(UART_SRC) $(UTIL) $(AXI_SRC) $(CVA6_SRC) $(CULSANS_SRC) $(COPRO_SRC)
	make CORES=2 -C $(CVA6_DIR)/corev_apu/bootrom clean all
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(UART_SRC)}    > scripts/add_sources.tcl
	@echo read_verilog -sv {$(COMMON_PKG)} >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(CVA6_PKG)} >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(AXI_PKG)} >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(CULSANS_PKG)} >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(FPGA_FILTER), $(COMMON_SRC))} 	   >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(FPGA_FILTER), $(UTIL))}     >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(FPGA_FILTER), $(COPRO_SRC))} >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(FPGA_FILTER), $(CVA6_SRC))} 	   >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(FPGA_FILTER), $(AXI_SRC))} 	   >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(FPGA_FILTER), $(CULSANS_SRC))} 	   >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(FPGA_SRC)}   >> scripts/add_sources.tcl


.PHONY:	clean
clean:
	rm -rf *.log *.jou *.str *.mif *.xpr $(work-dir) *.cache *.hw *.ip_user_files *.runs *.sim scripts/vivado*
