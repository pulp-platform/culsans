add wave -position insertpoint  \
{sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/commit_stage_i/commit_ack_o} \
{sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/commit_stage_i/commit_instr_i}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_miss_handler/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/*}

add wave -position insertpoint  \
{sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/commit_stage_i/commit_ack_o} \
{sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/commit_stage_i/commit_instr_i}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/i_miss_handler/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/*}
add wave -position insertpoint {sim:/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/WB/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/*}

add wave -position insertpoint  \
sim:/culsans_tb/i_culsans/ace_ariane_req \
sim:/culsans_tb/i_culsans/ace_ariane_resp

add wave -position insertpoint sim:/culsans_tb/i_culsans/i_ccu/i_ccu_top/fsm/*

