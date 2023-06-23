# include an additional script, which implements testcase-specific functions
set sim_extensions "sim_ext.tcl"
if { [file exists $sim_extensions] == 1} {
    source $sim_extensions
}

# add checks and breakpoints
# ...

add wave /culsans_tb/i_culsans/*
# add wave /culsans_tb/i_culsans/i_sram/gen_cut[0]/gen_mem/i_tc_sram_wrapper/i_tc_sram/sram
add wave /culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/commit_stage_i/*
add wave /culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/*
add wave /culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/*
add wave /culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/*
add wave /culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/*
add wave /culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_miss_handler/*
add wave /culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/issue_stage_i/i_issue_read_operands/gen_asic_regfile/i_ariane_regfile/mem
add wave -position insertpoint sim:/culsans_tb/i_culsans/i_ccu/i_ccu_top/fsm/*
add wave /culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/*
add wave /culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_miss_handler/*
#add wave /culsans_tb/i_culsans/gen_ariane[2]/i_ariane/*
#add wave /culsans_tb/i_culsans/gen_ariane[3]/i_ariane/*
# set a timeout
run 100ms

quit
