# include an additional script, which implements testcase-specific functions
set sim_extensions "sim_ext.tcl"
if { [file exists $sim_extensions] == 1} {
    source $sim_extensions
}

# add checks and breakpoints
# ...

add wave /culsans_tb/i_culsans/*

add wave /culsans_tb/i_culsans/genblk2[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/*
add wave /culsans_tb/i_culsans/genblk2[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/*

add wave -position insertpoint {sim:/culsans_tb/i_culsans/genblk2[0]/i_ariane/i_cva6/commit_stage_i/commit_ack_o}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/genblk2[0]/i_ariane/i_cva6/commit_stage_i/commit_instr_i}

add wave /culsans_tb/i_culsans/genblk2[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/*
add wave /culsans_tb/i_culsans/genblk2[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/*
add wave -position insertpoint sim:/culsans_tb/i_culsans/i_axi2mem/*

add wave -position insertpoint {sim:/culsans_tb/i_culsans/genblk2[1]/i_ariane/i_cva6/commit_stage_i/commit_ack_o}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/genblk2[1]/i_ariane/i_cva6/commit_stage_i/commit_instr_i}

# set a timeout
run 50ms

quit
