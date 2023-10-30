# Copyright 2018 ETH Zurich and University of Bologna.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

# hard-coded to Genesys 2 for the moment

if {$::env(BOARD) eq "genesys2"} {
    add_files -fileset constrs_1 -norecurse constraints/genesys-2.xdc
} elseif {$::env(BOARD) eq "kc705"} {
      add_files -fileset constrs_1 -norecurse constraints/kc705.xdc
} elseif {$::env(BOARD) eq "vc707"} {
      add_files -fileset constrs_1 -norecurse constraints/vc707.xdc
} else {
      exit 1
}

read_ip { \
      "xilinx/xlnx_mig_7_ddr3/xlnx_mig_7_ddr3.srcs/sources_1/ip/xlnx_mig_7_ddr3/xlnx_mig_7_ddr3.xci" \
      "xilinx/xlnx_axi_clock_converter/xlnx_axi_clock_converter.srcs/sources_1/ip/xlnx_axi_clock_converter/xlnx_axi_clock_converter.xci" \
      "xilinx/xlnx_axi_dwidth_converter/xlnx_axi_dwidth_converter.srcs/sources_1/ip/xlnx_axi_dwidth_converter/xlnx_axi_dwidth_converter.xci" \
      "xilinx/xlnx_axi_dwidth_converter_dm_slave/xlnx_axi_dwidth_converter_dm_slave.srcs/sources_1/ip/xlnx_axi_dwidth_converter_dm_slave/xlnx_axi_dwidth_converter_dm_slave.xci" \
      "xilinx/xlnx_axi_dwidth_converter_dm_master/xlnx_axi_dwidth_converter_dm_master.srcs/sources_1/ip/xlnx_axi_dwidth_converter_dm_master/xlnx_axi_dwidth_converter_dm_master.xci" \
      "xilinx/xlnx_axi_gpio/xlnx_axi_gpio.srcs/sources_1/ip/xlnx_axi_gpio/xlnx_axi_gpio.xci" \
      "xilinx/xlnx_axi_quad_spi/xlnx_axi_quad_spi.srcs/sources_1/ip/xlnx_axi_quad_spi/xlnx_axi_quad_spi.xci" \
      "xilinx/xlnx_clk_gen/xlnx_clk_gen.srcs/sources_1/ip/xlnx_clk_gen/xlnx_clk_gen.xci" \
      "xilinx/xlnx_ila/xlnx_ila.srcs/sources_1/ip/xlnx_ila/xlnx_ila.xci" \
}

set_property include_dirs { \
      "src/axi_sd_bridge/include" \
      "../modules/cva6/vendor/pulp-platform/common_cells/include" \
      "../modules/cva6/vendor/pulp-platform/axi/include" \
      "../modules/cva6/vendor/planv/ace/include" \
      "../modules/axi_llc/include"
      "../modules/cva6/corev_apu/register_interface/include" \
} [current_fileset]

source scripts/add_sources.tcl

set_property top ${project}_xilinx [current_fileset]

if {$::env(BOARD) eq "genesys2"} {
    read_verilog -sv {src/genesysii.svh ../modules/cva6/vendor/pulp-platform/common_cells/include/common_cells/registers.svh}
    set file "src/genesysii.svh"
    set registers "../modules/cva6/vendor/pulp-platform/common_cells/include/common_cells/registers.svh"
} elseif {$::env(BOARD) eq "kc705"} {
      read_verilog -sv {src/kc705.svh ../modules/cva6/vendor/pulp-platform/common_cells/include/common_cells/registers.svh}
      set file "src/kc705.svh"
      set registers "../modules/cva6/vendor/pulp-platform/common_cells/include/common_cells/registers.svh"
} elseif {$::env(BOARD) eq "vc707"} {
      read_verilog -sv {src/vc707.svh ../modules/cva6/vendor/pulp-platform/common_cells/include/common_cells/registers.svh}
      set file "src/vc707.svh"
      set registers "../modules/cva6/vendor/pulp-platform/common_cells/include/common_cells/registers.svh"
} else {
    exit 1
}

set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file" "$registers"]]
set_property -dict { file_type {Verilog Header} is_global_include 1} -objects $file_obj

update_compile_order -fileset sources_1

add_files -fileset constrs_1 -norecurse constraints/ariane.xdc

synth_design -rtl -name rtl_1

set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1

exec mkdir -p reports/
exec rm -rf reports/*

check_timing -verbose                                                   -file reports/$project.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack -file reports/$project.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                  -file reports/$project.timing.rpt
report_utilization -hierarchical                                        -file reports/$project.utilization.rpt
report_cdc                                                              -file reports/$project.cdc.rpt
report_clock_interaction                                                -file reports/$project.clock_interaction.rpt

# set for RuntimeOptimized implementation
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE RuntimeOptimized    [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE RuntimeOptimized    [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE RuntimeOptimized      [get_runs impl_1]

# disable power optimization
set_property STEPS.POST_PLACE_POWER_OPT_DESIGN.IS_ENABLED false    [get_runs impl_1]
set_property STEPS.POWER_OPT_DESIGN.IS_ENABLED false               [get_runs impl_1]

# CRITICAL WARNING: [DRC LUTLP-1] Combinatorial Loop Alert: 13 LUT cells form a combinatorial loop.
# This can create a race condition. Timing analysis may not be accurate. The preferred resolution is
# to modify the design to remove combinatorial logic loops. If the loop is known and understood, this
# DRC can be bypassed by acknowledging the condition and setting the following XDC constraint on any
# one of the nets in the loop: 'set_property ALLOW_COMBINATORIAL_LOOPS TRUE
# [get_nets <myHier/myNet>]'. One net in the loop is
# i_axi_llc/i_axi_llc_top_raw/i_axi_bypass_demux/gen_demux.gen_aw_id_counter.i_aw_id_counter/gen_counters[4].i_in_flight_cnt/gen_demux.lock_aw_valid_q_reg.
# Please evaluate your design. The cells in the loop are:
# i_axi_riscv_atomics/i_atomics/i_lrsc/art_check_gnt_inferred_i_1,
# i_axi_riscv_atomics/i_atomics/i_lrsc/i_art/art_check_res_inferred_i_1,
# i_axi_llc/i_axi_llc_top_raw/i_axi_bypass_demux/gen_demux.gen_aw_id_counter.i_aw_id_counter/gen_counters[4].i_in_flight_cnt/counter_q[3]_i_3,
# i_axi_llc/i_axi_llc_top_raw/i_axi_bypass_demux/gen_demux.gen_aw_id_counter.i_aw_id_counter/gen_counters[4].i_in_flight_cnt/counter_q[3]_i_5,
# i_axi_riscv_atomics/i_atomics/i_lrsc/i_non_excl_acc_arb/i_arb/gen_rr_arb.i_arbiter/gen_arbiter.gen_int_rr.gen_lock.lock_q_i_2,
# i_axi_riscv_atomics/i_atomics/i_lrsc/i_non_excl_acc_arb/i_arb/gen_rr_arb.i_arbiter/gen_arbiter.gen_int_rr.gen_lock.req_q[0]_i_1,
# i_axi_llc/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/gen_demux.lock_aw_valid_q_i_3,
# i_axi_llc/i_axi_llc_top_raw/i_axi_bypass_demux/gen_demux.i_counter_open_w/i_counter/i_axi_riscv_atomics_i_2,
# i_axi_riscv_atomics/i_atomics/i_amos/mst\\.aw_valid_INST_0,
# i_axi_llc/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_w_q[4]_i_3,
# i_axi_llc/i_axi_llc_top_raw/i_axi_bypass_demux/gen_demux.i_counter_open_w/i_counter/pending_w_q[4]_i_4,
# i_axi_llc/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_w_q[4]_i_5, and
# i_axi_llc/i_axi_llc_top_raw/i_axi_bypass_demux/gen_demux.i_counter_open_w/i_counter/pending_w_q[4]_i_11.


launch_runs impl_1
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1

# output Verilog netlist + SDC for timing simulation
write_verilog -force -mode funcsim work-fpga/${project}_funcsim.v
write_verilog -force -mode timesim work-fpga/${project}_timesim.v
write_sdf     -force work-fpga/${project}_timesim.sdf

# reports
exec mkdir -p reports/
exec rm -rf reports/*
check_timing                                                              -file reports/${project}.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack   -file reports/${project}.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                    -file reports/${project}.timing.rpt
report_utilization -hierarchical                                          -file reports/${project}.utilization.rpt
