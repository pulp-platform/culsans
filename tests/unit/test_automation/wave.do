onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /culsans_tb/clk
add wave -noupdate -divider Core0
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_i[2]}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_o[2]}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/req_o}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/addr_o}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/gnt_i}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/data_o}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/be_o}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/tag_o}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/data_i}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/we_o}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/hit_way_i}
add wave -noupdate -group {Cache Ctrl[0][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/shared_way_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_i[1]}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_o[1]}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/req_o}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/addr_o}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/gnt_i}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/data_o}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/be_o}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/tag_o}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/data_i}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/we_o}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/hit_way_i}
add wave -noupdate -group {Cache Ctrl [0][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/shared_way_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_i[0]}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_o[0]}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/req_o}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/addr_o}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/gnt_i}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/data_o}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/be_o}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/tag_o}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} -expand -subitemconfig {{/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/data_i[0]} -expand} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/data_i}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/we_o}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/hit_way_i}
add wave -noupdate -group {Cache Ctrl [0][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/shared_way_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/snoop_port_o}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/snoop_port_i}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/req_o}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/addr_o}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/gnt_i}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/data_o}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/be_o}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/tag_o}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/data_i}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/we_o}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/hit_way_i}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/dirty_way_i}
add wave -noupdate -group {Snoop Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/shared_way_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/amo_req_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/amo_resp_o}
add wave -noupdate -group {Miss Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/req_o}
add wave -noupdate -group {Miss Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/addr_o}
add wave -noupdate -group {Miss Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/data_o}
add wave -noupdate -group {Miss Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/be_o}
add wave -noupdate -group {Miss Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/data_i}
add wave -noupdate -group {Miss Handler [0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/we_o}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/axi_req_o}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[0]/i_ariane/i_cva6/i_cache_subsystem/axi_resp_i}
add wave -noupdate -divider {Core 1}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_i[2]}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_o[2]}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/req_o}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/addr_o}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/gnt_i}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/data_o}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/be_o}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/tag_o}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} -expand -subitemconfig {{/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/data_i[0]} -expand} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/data_i}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/we_o}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/hit_way_i}
add wave -noupdate -group {Cache Ctrl [1][2] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[3]/i_cache_ctrl/shared_way_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_i[1]}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_o[1]}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/req_o}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/addr_o}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/gnt_i}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/data_o}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/be_o}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/tag_o}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} -expand -subitemconfig {{/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/data_i[1]} -expand} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/data_i}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/we_o}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/hit_way_i}
add wave -noupdate -group {Cache Ctrl [1][1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[2]/i_cache_ctrl/shared_way_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_i[0]}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/dcache_req_ports_o[0]}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/req_o}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/addr_o}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/gnt_i}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/data_o}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/be_o}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/tag_o}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/data_i}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/we_o}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/hit_way_i}
add wave -noupdate -group {Cache Ctrl [1][0] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/master_ports[1]/i_cache_ctrl/shared_way_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/snoop_port_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/snoop_port_o}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/req_o}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/addr_o}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/gnt_i}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/data_o}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/be_o}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/tag_o}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/data_i}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/we_o}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/hit_way_i}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/dirty_way_i}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_snoop_cache_ctrl/shared_way_i}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/snoop_port_i}
add wave -noupdate -group {Snoop Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/snoop_port_o}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/amo_req_i}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/amo_resp_o}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/req_o}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/addr_o}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/data_o}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/be_o}
add wave -noupdate -group {Miss Handler [1] SRAM IF} -expand -subitemconfig {{/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/data_i[1]} -expand} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/data_i}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/we_o}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/i_miss_axi_adapter/trans_type_i}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/i_miss_axi_adapter/critical_word_o}
add wave -noupdate -group {Miss Handler [1] SRAM IF} {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/i_nbdcache/i_miss_handler/i_miss_axi_adapter/critical_word_valid_o}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/axi_req_o}
add wave -noupdate {/culsans_tb/i_culsans/gen_ariane[1]/i_ariane/i_cva6/i_cache_subsystem/axi_resp_i}
add wave -noupdate -divider CCU
add wave -noupdate /culsans_tb/i_culsans/i_ccu/clk_i
add wave -noupdate /culsans_tb/i_culsans/i_ccu/slv_ace_reqs
add wave -noupdate -subitemconfig {{/culsans_tb/i_culsans/i_ccu/slv_ace_resps[1]} -expand} /culsans_tb/i_culsans/i_ccu/slv_ace_resps
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9185 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 841
configure wave -valuecolwidth 310
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {8871 ns} {9455 ns}
