`include "ace/assign.svh"
module culsans_tb
    import ariane_pkg::*;
    import snoop_test::*;
    import ace_test::*;
    import tb_ace_ccu_pkg::*;
    import tb_std_cache_subsystem_pkg::*;
#()();

    `define WAIT_CYC(CLK, N) \
        repeat(N) @(posedge(CLK));


    `define WAIT_SIG(CLK,SIG)    \
        do begin                 \
            @(posedge(CLK));     \
        end while(SIG == 1'b0);

    parameter  int unsigned AxiIdWidth       = culsans_pkg::IdWidth;
    parameter  int unsigned AxiAddrWidth     = culsans_pkg::AddrWidth;
    parameter  int unsigned AxiDataWidth     = culsans_pkg::DataWidth;
    localparam int unsigned AxiUserWidth     = culsans_pkg::UserWidth;
    localparam ariane_cfg_t ArianeCfg        = culsans_pkg::ArianeSocCfg;

    localparam time         CLK_PERIOD         = 10ns;
    localparam int unsigned RTC_CLOCK_PERIOD   = 30.517us;
    localparam int unsigned DCACHE_PORTS       = 3;
    localparam int unsigned NB_CORES           = culsans_pkg::NB_CORES;
    localparam int unsigned NUM_WORDS          = 4**10;
    localparam bit          STALL_RANDOM_DELAY = 1'b1;
    localparam bit          HAS_LLC            = 1'b1;

    // The length of cached, shared region is derived from other constants
    localparam int CachedSharedRegionLength =  ArianeCfg.SharedRegionAddrBase[0] + ArianeCfg.SharedRegionLength[0] - ArianeCfg.CachedRegionAddrBase[0];
    initial assert (CachedSharedRegionLength > 0) else $error ("Got negative CachedSharedRegionLength");

    // TB signals
    dcache_req_i_t [NB_CORES][DCACHE_PORTS] dcache_req_ports_i;
    dcache_req_o_t [NB_CORES][DCACHE_PORTS] dcache_req_ports_o;
    logic                                   clk;
    logic                                   rst_n;
    logic                                   rtc;
    logic [31:0]                            exit_val;

    // TB interfaces
    amo_intf                amo_if           [NB_CORES]               (clk);
    dcache_intf             dcache_if        [NB_CORES][DCACHE_PORTS] (clk);
    dcache_sram_if          dc_sram_if       [NB_CORES]               (clk);
    dcache_gnt_if           gnt_if           [NB_CORES]               (clk);
    dcache_mgmt_intf        mgmt_if          [NB_CORES]               (clk);

    // verification conponents
    dcache_driver           dcache_drv       [NB_CORES][DCACHE_PORTS];
    dcache_monitor          dcache_mon       [NB_CORES][DCACHE_PORTS];
    dcache_mgmt_driver      dcache_mgmt_drv  [NB_CORES];
    dcache_mgmt_monitor     dcache_mgmt_mon  [NB_CORES];

    amo_driver              amo_drv          [NB_CORES];
    amo_monitor             amo_mon          [NB_CORES];

    mailbox #(dcache_req)   dcache_req_mbox  [NB_CORES][DCACHE_PORTS];
    mailbox #(dcache_resp)  dcache_resp_mbox [NB_CORES][DCACHE_PORTS];

    mailbox #(amo_req)      amo_req_mbox     [NB_CORES];
    mailbox #(amo_resp)     amo_resp_mbox    [NB_CORES];

    mailbox #(dcache_mgmt_trans) mgmt_mbox   [NB_CORES];

    sram_intf #(
        .NUM_WORDS        (NUM_WORDS),
        .DATA_WIDTH       (AxiDataWidth),
        .DCACHE_SET_ASSOC (DCACHE_SET_ASSOC)
    ) sram_if [NB_CORES] ();

    std_cache_scoreboard #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) cache_scbd [NB_CORES];

    std_dcache_checker #(
        .NB_CORES        ( NB_CORES     ),
        .SRAM_DATA_WIDTH ( AxiDataWidth ),
        .SRAM_NUM_WORDS  ( NUM_WORDS    )
    ) dcache_chk;

    // ACE mailboxes
    mailbox aw_mbx [NB_CORES];
    mailbox w_mbx  [NB_CORES];
    mailbox b_mbx  [NB_CORES];
    mailbox ar_mbx [NB_CORES];
    mailbox r_mbx  [NB_CORES];

    // Snoop mailboxes
    mailbox ac_mbx [NB_CORES];
    mailbox cd_mbx [NB_CORES];
    mailbox cr_mbx [NB_CORES];

    //--------------------------------------------------------------------------
    // Clock & reset generation
    //--------------------------------------------------------------------------

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;

        repeat(8)
            #(CLK_PERIOD/2) clk = ~clk;

        rst_n = 1'b1;

        forever begin
            #(CLK_PERIOD/2) clk = ~clk;
        end

    end


    initial begin
        forever begin
            rtc = 1'b0;
            forever begin
                #(RTC_CLOCK_PERIOD/2) rtc = ~rtc;
            end
        end
    end

    //--------------------------------------------------------------------------
    // DUT
    //--------------------------------------------------------------------------
    culsans_top #(
        .InclSimDTM       (1'b0),
        .NUM_WORDS        (NUM_WORDS), // 4Kwords
        .StallRandomInput (STALL_RANDOM_DELAY),
        .StallRandomOutput(STALL_RANDOM_DELAY),
//        .HasLLC           (HAS_LLC),
        .FixedDelayInput  (0),
        .FixedDelayOutput (0),
        .BootAddress      (culsans_pkg::DRAMBase + 64'h10_0000)
    ) i_culsans (
        .clk_i  ( clk      ),
        .rtc_i  ( rtc      ),
        .rst_ni ( rst_n    ),
        .exit_o ( exit_val )
    );

    //--------------------------------------------------------------------------
    // AXI/ACE bus interfaces
    //--------------------------------------------------------------------------

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth               ),
        .AXI_DATA_WIDTH ( AxiDataWidth               ),
        .AXI_ID_WIDTH   ( culsans_pkg::IdWidthToXbar ),
        .AXI_USER_WIDTH ( AxiUserWidth               )
    ) axi_bus [0:0] ();

    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth               ),
        .AXI_DATA_WIDTH ( AxiDataWidth               ),
        .AXI_ID_WIDTH   ( culsans_pkg::IdWidthToXbar ),
        .AXI_USER_WIDTH ( AxiUserWidth               )
    ) axi_bus_dv [0:0] (clk);


    ACE_BUS #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) ace_bus [NB_CORES-1:0] ();

    ACE_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) ace_bus_dv [NB_CORES-1:0] (clk);


    SNOOP_BUS #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus [NB_CORES-1:0] ();

    SNOOP_BUS_DV #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus_dv [NB_CORES-1:0] (clk);


    // connect internal signals to interfaces, connect interfaces to dv interfaces
    `AXI_ASSIGN_MONITOR (axi_bus[0], i_culsans.to_xbar[0])
    `AXI_ASSIGN_MONITOR (axi_bus_dv[0], axi_bus[0])

    for (genvar core_idx=0; core_idx<NB_CORES; core_idx++) begin
        `ACE_ASSIGN_FROM_REQ    (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `ACE_ASSIGN_FROM_RESP   (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `ACE_ASSIGN_MONITOR   (ace_bus_dv   [core_idx], ace_bus   [core_idx])

        `SNOOP_ASSIGN_FROM_REQ  (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `SNOOP_ASSIGN_FROM_RESP (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `SNOOP_ASSIGN_MONITOR (snoop_bus_dv [core_idx], snoop_bus [core_idx])
    end

    // AXI/ACE monitors
    ace_monitor #(
        .IW ( AxiIdWidth   ),
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth ),
        .UW ( AxiUserWidth )
    ) ace_mon [NB_CORES-1:0];

    snoop_monitor #(
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth )
    ) snoop_mon [NB_CORES-1:0];

    // CCU monitor & scoreboard
    ace_ccu_monitor #(
        .AxiAddrWidth      ( AxiAddrWidth               ),
        .AxiDataWidth      ( AxiDataWidth               ),
        .AxiIdWidthMasters ( AxiIdWidth                 ),
        .AxiIdWidthSlaves  ( culsans_pkg::IdWidthToXbar ),
        .AxiUserWidth      ( AxiUserWidth               ),
        .NoMasters         ( NB_CORES      ),
        .NoSlaves          ( 1                          ),
        .TimeTest          ( 0                          )
    ) ccu_mon;


    //--------------------------------------------------------------------------
    // Create environment
    //--------------------------------------------------------------------------

    bit enable_ccu_mon=1;

    initial begin : CCU_MON
        ccu_mon = new(ace_bus_dv, axi_bus_dv, snoop_bus_dv);
        void'($value$plusargs("ENABLE_CCU_MON=%b", enable_ccu_mon));
        if (enable_ccu_mon) begin
            ccu_mon.run();
        end
    end

    final begin : CCU_CHECK
        if (enable_ccu_mon) begin
            $display("--------------------------------------------------------------------------");
            $display("CCU scoreboard results");
            $display("--------------------------------------------------------------------------");
            ccu_mon.print_result();
            $display("--------------------------------------------------------------------------");
        end
    end

    for (genvar core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE

        initial begin : ACE_MON
            aw_mbx [core_idx] = new();
            w_mbx  [core_idx] = new();
            b_mbx  [core_idx] = new();
            ar_mbx [core_idx] = new();
            r_mbx  [core_idx] = new();

            ace_mon[core_idx] = new(ace_bus_dv[core_idx]);

            ace_mon[core_idx].aw_mbx = aw_mbx [core_idx];
            ace_mon[core_idx].w_mbx  = w_mbx  [core_idx];
            ace_mon[core_idx].b_mbx  = b_mbx  [core_idx];
            ace_mon[core_idx].ar_mbx = ar_mbx [core_idx];
            ace_mon[core_idx].r_mbx  = r_mbx  [core_idx];

            ace_mon[core_idx].monitor();
        end

        initial begin : SNOOP_MON
            ac_mbx [core_idx] = new();
            cd_mbx [core_idx] = new();
            cr_mbx [core_idx] = new();

            snoop_mon[core_idx] = new(snoop_bus_dv[core_idx]);

            snoop_mon[core_idx].ac_mbx = ac_mbx[core_idx];
            snoop_mon[core_idx].cd_mbx = cd_mbx[core_idx];
            snoop_mon[core_idx].cr_mbx = cr_mbx[core_idx];

            snoop_mon[core_idx].monitor();
        end

        // assign SRAM IF
        assign dc_sram_if[core_idx].vld_sram  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.sram;
        assign dc_sram_if[core_idx].vld_req   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.req_i;
        assign dc_sram_if[core_idx].vld_we    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.we_i;
        assign dc_sram_if[core_idx].vld_index = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.addr_i;
        for (genvar i = 0; i<DCACHE_SET_ASSOC; i++) begin : sram_block
            assign dc_sram_if[core_idx].tag_sram[i]  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].tag_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.sram;
            assign dc_sram_if[core_idx].data_sram[0][i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.sram;
            assign dc_sram_if[core_idx].data_sram[1][i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.gen_cut[1].i_tc_sram_wrapper.i_tc_sram.sram;
        end

        // assign Grant IF
        assign gnt_if[core_idx].gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[0] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[0];

        assign gnt_if[core_idx].gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[1] &&
            !(|i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.updating_cache);

        assign gnt_if[core_idx].gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[2] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[2];

        assign gnt_if[core_idx].gnt[3] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[3] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[3];

        assign gnt_if[core_idx].gnt[4] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[4] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[4];

        assign gnt_if[core_idx].bypass_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[0];
        assign gnt_if[core_idx].bypass_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[1];
        assign gnt_if[core_idx].bypass_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[2];

        assign gnt_if[core_idx].miss_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[0];
        assign gnt_if[core_idx].miss_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[1];
        assign gnt_if[core_idx].miss_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[2];


        // assign management IF
//        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_en_csr_nbdcache  = mgmt_if[core_idx].dcache_enable;
//        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ctrl_cache = mgmt_if[core_idx].dcache_flush;
        assign mgmt_if[core_idx].dcache_enable    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_en_csr_nbdcache;
        assign mgmt_if[core_idx].dcache_flush     = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ctrl_cache;

        assign mgmt_if[core_idx].dcache_flushing  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.flushing;
        assign mgmt_if[core_idx].dcache_flush_ack = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ack_cache_ctrl;
        assign mgmt_if[core_idx].dcache_miss      = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_miss_cache_perf;
        assign mgmt_if[core_idx].wbuffer_empty    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_commit_wbuffer_empty;

/*
        initial begin : DCACHE_MGMT_DRV
            dcache_mgmt_drv[core_idx] = new(mgmt_if[core_idx], $sformatf("%s[%0d]","dcache_mgmt_driver",core_idx));
        end
*/
        initial begin : DCACHE_MGMT_MON
            mgmt_mbox[core_idx] = new();
            dcache_mgmt_mon[core_idx] = new(mgmt_if[core_idx], $sformatf("%s[%0d]","dcache_mgmt_monitor",core_idx));
            dcache_mgmt_mon[core_idx].mbox = mgmt_mbox[core_idx];
            dcache_mgmt_mon[core_idx].monitor();
        end


        for (genvar port=0; port<=2; port++) begin : PORT
            // assign dcache request/response to dcache_if
//            assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port] = dcache_if[core_idx][port].req;
            assign dcache_if[core_idx][port].req    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port];

            assign dcache_if[core_idx][port].resp   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_cache_ex[port];
            assign dcache_if[core_idx][port].wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[port+2] &&
                                                      (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[port+1].i_cache_ctrl.state_q == 0); // IDLE

            initial begin : DCACHE_MON
                dcache_req_mbox  [core_idx][port] = new();
                dcache_resp_mbox [core_idx][port] = new();

                dcache_mon[core_idx][port] = new(dcache_if[core_idx][port], port, $sformatf("%s[%0d][%0d]","dcache_monitor",core_idx, port));

                dcache_mon[core_idx][port].req_mbox  = dcache_req_mbox[ core_idx][port];
                dcache_mon[core_idx][port].resp_mbox = dcache_resp_mbox[core_idx][port];

                dcache_mon[core_idx][port].monitor();
            end

/*
            initial begin : DCACHE_DRV
                dcache_drv[core_idx][port] = new(dcache_if[core_idx][port], ArianeCfg, $sformatf("%s[%0d][%0d]","dcache_driver",core_idx, port));
            end
*/

        end

        // assign AMO IF
//        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req = amo_if[core_idx].req;
        assign amo_if[core_idx].req = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req;

        assign amo_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_resp;
        assign amo_if[core_idx].gnt  = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                       (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.busy_i  == 0);
        initial begin : AMO_MON
            amo_req_mbox  [core_idx] = new();
            amo_resp_mbox [core_idx] = new();

            amo_mon[core_idx] = new(amo_if[core_idx], $sformatf("%s[%0d]","amo_monitor",core_idx));

            amo_mon[core_idx].req_mbox  = amo_req_mbox[core_idx];
            amo_mon[core_idx].resp_mbox = amo_resp_mbox[core_idx];

            amo_mon[core_idx].monitor();
        end

/*
        initial begin : AMO_DRV
            amo_drv[core_idx] = new(amo_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","amo_driver",core_idx));
        end
*/

        initial begin : CACHE_SCBD
            cache_scbd[core_idx] = new(dc_sram_if[core_idx], gnt_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","dcache_scoreboard",core_idx));

//            cache_scbd[core_idx].dcache_req_mbox  = dcache_req_mbox  [core_idx];
//            cache_scbd[core_idx].dcache_resp_mbox = dcache_resp_mbox [core_idx];

//            cache_scbd[core_idx].amo_req_mbox     = amo_req_mbox     [core_idx];
//            cache_scbd[core_idx].amo_resp_mbox    = amo_resp_mbox    [core_idx];

            cache_scbd[core_idx].aw_mbx_pre_filt           = aw_mbx           [core_idx];
            cache_scbd[core_idx].w_mbx_pre_filt            = w_mbx            [core_idx];
            cache_scbd[core_idx].b_mbx_pre_filt            = b_mbx            [core_idx];
            cache_scbd[core_idx].ar_mbx_pre_filt           = ar_mbx           [core_idx];
            cache_scbd[core_idx].r_mbx_pre_filt            = r_mbx            [core_idx];

            cache_scbd[core_idx].ac_mbx           = ac_mbx           [core_idx];
            cache_scbd[core_idx].cd_mbx           = cd_mbx           [core_idx];
            cache_scbd[core_idx].cr_mbx           = cr_mbx           [core_idx];

            cache_scbd[core_idx].mgmt_mbox        = mgmt_mbox        [core_idx];

//            cache_scbd[core_idx].run();
        end

        // assign SRAM IF
        for (genvar w=0; w<DCACHE_SET_ASSOC; w++) begin
            assign sram_if[core_idx].data[w][0] = i_culsans.i_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.sram[sram_if[core_idx].addr[w]];
            assign sram_if[core_idx].data[w][1] = i_culsans.i_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.sram[sram_if[core_idx].addr[w]+1];
        end

    end


    bit enable_mem_check=1;
    initial begin
        dcache_chk = new(sram_if, dc_sram_if, ArianeCfg, "dcache_checker");
        void'($value$plusargs("ENABLE_MEM_CHECK=%b", enable_mem_check));
        dcache_chk.enable_mem_check = enable_mem_check;

        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
            dcache_chk.amo_req_mbox[core_idx]  = amo_req_mbox  [core_idx];
            dcache_chk.amo_resp_mbox[core_idx] = amo_resp_mbox [core_idx];

            dcache_chk.dcache_req_mbox[core_idx]  = dcache_req_mbox  [core_idx][2];
            dcache_chk.dcache_resp_mbox[core_idx] = dcache_resp_mbox [core_idx][2];

        end


//        dcache_chk.monitor();
        dcache_chk.check_amo_lock();


    end

    //--------------------------------------------------------------------------
    // Tests
    //--------------------------------------------------------------------------

    task test_header (string testname, string description="");
        $display("--------------------------------------------------------------------------");
        $display("Running test %s", testname);
        $display("%s", description);
        $display("--------------------------------------------------------------------------");
    endtask

    int timeout = 100000; // default
    int wait_time = 0;
    int test_id = -1;
    int rep_cnt;
    // select one core randomly for tests that need one core that behaves differently
    int cid = $urandom_range(NB_CORES-1);

    initial begin : TESTS
        logic [63:0] addr, base_addr;
        logic [63:0] data, base_data;

        automatic string testname="";
        if (!$value$plusargs("TESTNAME=%s", testname)) begin
            $error("No TESTNAME plusarg given");
        end

        // The tests assume that the address regions are arranged in increaisng address order:
        // - non-cached, non-shared
        // - shared, non-cached
        // - cached, shared
        // - cached, non-shared
        a_shared_gt_nonshared: assert (ArianeCfg.SharedRegionAddrBase[0] > culsans_pkg::DRAMBase) else
            $error("Non-cached, shared region must be after non-cached, non-shared region");
        a_cached_gt_shared: assert (ArianeCfg.CachedRegionAddrBase[0] > ArianeCfg.SharedRegionAddrBase[0]) else
            $error("Cached, shared region must be after non-cached, shared region");

        fork

            begin

                `WAIT_SIG(clk, rst_n)
                `WAIT_CYC(clk, 300)
                `WAIT_CYC(clk, 1500) // wait some more for LLC initialization

                case (testname)

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_mutex", "raw_spin_lock" : begin
                        integer file;
                        integer error;
                        static string  mem_init_file = "main.hex";

                        test_header(testname, "");

                        timeout = 1000000; // long test 

                        @(posedge clk);
                        #2

                        $readmemh(mem_init_file, i_culsans.i_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.sram);

                        wait (exit_val[0]);
                        if ((exit_val >> 1)) begin
                            $error("*** FAILED *** (tohost = %0d)", (exit_val >> 1));
                            $display("return code: 0x%x", (exit_val >> 1));
                        end else begin
                            $info("*** SUCCESS *** (tohost = %0d)", (exit_val >> 1));
                        end

                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    default : $error("Unknown test name %s",testname);

                endcase


                //--------------------------------------------------------------
                // end of tests
                //--------------------------------------------------------------
                `WAIT_CYC(clk, 100)
                $display("Test done");
                $finish();

            end

            //------------------------------------------------------------------
            // Timeout
            //------------------------------------------------------------------
            begin
                while (timeout > 0) begin
                    timeout--;
                    `WAIT_CYC(clk, 1)
                end
                $error("Timeout");
                $finish();
            end

        join_any
        disable fork;

    end

endmodule
