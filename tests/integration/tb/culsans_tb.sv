// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

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
    icache_intf             icache_if        [NB_CORES]               (clk);
    dcache_sram_if          dc_sram_if       [NB_CORES]               (clk);
    dcache_gnt_if           gnt_if           [NB_CORES]               (clk);
    dcache_mgmt_intf        mgmt_if          [NB_CORES]               (clk);

    // verification conponents
    dcache_monitor          dcache_mon       [NB_CORES][DCACHE_PORTS];
    dcache_mgmt_monitor     dcache_mgmt_mon  [NB_CORES];
    amo_monitor             amo_mon          [NB_CORES];

    mailbox #(dcache_req)   dcache_req_mbox      [NB_CORES][DCACHE_PORTS];
    mailbox #(dcache_resp)  dcache_resp_mbox     [NB_CORES][DCACHE_PORTS];
    mailbox #(dcache_req)   dcache_req_mbox_fwd  [NB_CORES];
    mailbox #(dcache_resp)  dcache_resp_mbox_fwd [NB_CORES];

    mailbox #(amo_req)      amo_req_mbox      [NB_CORES];
    mailbox #(amo_resp)     amo_resp_mbox     [NB_CORES];
    mailbox #(amo_req)      amo_req_mbox_fwd  [NB_CORES];
    mailbox #(amo_resp)     amo_resp_mbox_fwd [NB_CORES];

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
        .HasLLC           (HAS_LLC),
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

    // CCU monitor
    bit enable_ccu_mon=1;
    bit ccu_mon_end_check=0;
    initial begin : CCU_MON
        ccu_mon = new(ace_bus_dv, axi_bus_dv, snoop_bus_dv);
        void'($value$plusargs("ENABLE_CCU_MON=%b", enable_ccu_mon));
    end
    final begin : CCU_CHECK
        if (ccu_mon_end_check) begin
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
        end

        initial begin : SNOOP_MON
            ac_mbx [core_idx] = new();
            cd_mbx [core_idx] = new();
            cr_mbx [core_idx] = new();

            snoop_mon[core_idx] = new(snoop_bus_dv[core_idx]);

            snoop_mon[core_idx].ac_mbx = ac_mbx[core_idx];
            snoop_mon[core_idx].cd_mbx = cd_mbx[core_idx];
            snoop_mon[core_idx].cr_mbx = cr_mbx[core_idx];
        end

        // assign SRAM IF
        assign dc_sram_if[core_idx].vld_sram  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.i_tc_sram.sram;
        assign dc_sram_if[core_idx].vld_req   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.req_i;
        assign dc_sram_if[core_idx].vld_we    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.we_i;
        assign dc_sram_if[core_idx].vld_index = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.addr_i;
        for (genvar i = 0; i<DCACHE_SET_ASSOC; i++) begin : sram_block
            assign dc_sram_if[core_idx].tag_sram[i]  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].tag_sram.i_tc_sram.sram;
            assign dc_sram_if[core_idx].data_sram[i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.i_tc_sram.sram;
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

        assign gnt_if[core_idx].rd_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt;

        assign gnt_if[core_idx].snoop_wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[1] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[1];

        assign gnt_if[core_idx].bypass_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[0];
        assign gnt_if[core_idx].bypass_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[1];
        assign gnt_if[core_idx].bypass_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[2];

        assign gnt_if[core_idx].miss_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[0];
        assign gnt_if[core_idx].miss_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[1];
        assign gnt_if[core_idx].miss_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[2];

        // priority encoding of wr_gnt.
        assign gnt_if[core_idx].wr_gnt[0] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].wr_gnt[1] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].wr_gnt[2] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[3].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[3].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].mshr_match[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_addr_matches[0];
        assign gnt_if[core_idx].mshr_match[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_addr_matches[1];
        assign gnt_if[core_idx].mshr_match[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_index_matches[2];

        // assign management IF
        assign mgmt_if[core_idx].dcache_enable    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_en_csr_nbdcache;
        assign mgmt_if[core_idx].dcache_flush     = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ctrl_cache;
        assign mgmt_if[core_idx].dcache_flushing  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.flushing;
        assign mgmt_if[core_idx].dcache_flush_ack = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ack_cache_ctrl;
        assign mgmt_if[core_idx].dcache_miss      = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_miss_cache_perf;
        assign mgmt_if[core_idx].wbuffer_empty    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_commit_wbuffer_empty;

        initial begin : DCACHE_MGMT_MON
            mgmt_mbox[core_idx] = new();
            dcache_mgmt_mon[core_idx] = new(mgmt_if[core_idx], $sformatf("%s[%0d]","dcache_mgmt_monitor",core_idx));
            dcache_mgmt_mon[core_idx].mbox = mgmt_mbox[core_idx];
        end

        for (genvar port=0; port<=2; port++) begin : PORT
            // assign dcache request/response to dcache_if

            assign dcache_if[core_idx][port].req    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port];
            assign dcache_if[core_idx][port].resp   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_cache_ex[port];
            assign dcache_if[core_idx][port].wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[port+2] &&
                                                      (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[port+1].i_cache_ctrl.state_q == 0); // IDLE

            initial begin : DCACHE_MON
                dcache_req_mbox  [core_idx][port] = new();
                dcache_resp_mbox [core_idx][port] = new();

                dcache_mon[core_idx][port] = new(dcache_if[core_idx][port], port, $sformatf("%s[%0d][%0d]","dcache_monitor",core_idx, port));

                dcache_mon[core_idx][port].req_mbox  = dcache_req_mbox[core_idx][port];
                dcache_mon[core_idx][port].resp_mbox = dcache_resp_mbox[core_idx][port];
            end

            //------------------------------------------------------------------
            // check that the read responds match the read requests
            //------------------------------------------------------------------
            /* This currentl doesn't work, see JIRA issue PROJ-281
            int cnt = 0;
            logic check_neg = 1;
            logic check_pos = 1;
            always @ (posedge clk) begin
                if (dcache_if[core_idx][port].req.data_req && !dcache_if[core_idx][port].req.data_we && dcache_if[core_idx][port].resp.data_gnt) begin
                    cnt++;
                end
                if (dcache_if[core_idx][port].resp.data_rvalid) begin
                    cnt--;
                end

                a_rd_resp_neg : assert (!check_neg || cnt >= 0) else begin
                   $error("too many read responds in core %0d, dcache port %0d", core_idx, port);
                    check_neg = 0;
                end

                a_rd_resp_pos : assert (!check_pos || cnt <= 2) else begin
                   $error("too many outstanding read requests in core %0d, dcache port %0d", core_idx, port);
                    check_pos = 0;
                end
            end
            final a_req_resp_match : assert (cnt == 0) else $error("read requests and responds dont match in core %0d, dcache port %0d", core_idx, port);
            */

        end

        // assign AMO IF
        assign amo_if[core_idx].req  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req;
        assign amo_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_resp;
        assign amo_if[core_idx].gnt  = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                       (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.busy_i  == 0);
        initial begin : AMO_MON
            amo_req_mbox  [core_idx] = new();
            amo_resp_mbox [core_idx] = new();

            amo_mon[core_idx] = new(amo_if[core_idx], $sformatf("%s[%0d]","amo_monitor",core_idx));

            amo_mon[core_idx].req_mbox  = amo_req_mbox[core_idx];
            amo_mon[core_idx].resp_mbox = amo_resp_mbox[core_idx];
        end

        initial begin : CACHE_SCBD
            cache_scbd[core_idx] = new(dc_sram_if[core_idx], gnt_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","dcache_scoreboard",core_idx));
            amo_req_mbox_fwd      [core_idx] = new();
            amo_resp_mbox_fwd     [core_idx] = new();
            dcache_req_mbox_fwd   [core_idx] = new();
            dcache_resp_mbox_fwd  [core_idx] = new();

            for (int port=0; port<=2; port++) begin : PORT
                cache_scbd[core_idx].dcache_req_mbox[port]  = dcache_req_mbox  [core_idx][port];
                cache_scbd[core_idx].dcache_resp_mbox[port] = dcache_resp_mbox [core_idx][port];
            end
            cache_scbd[core_idx].dcache_req_mbox_fwd  = dcache_req_mbox_fwd   [core_idx];
            cache_scbd[core_idx].dcache_resp_mbox_fwd = dcache_resp_mbox_fwd  [core_idx];

            cache_scbd[core_idx].amo_req_mbox      = amo_req_mbox      [core_idx];
            cache_scbd[core_idx].amo_resp_mbox     = amo_resp_mbox     [core_idx];
            cache_scbd[core_idx].amo_req_mbox_fwd  = amo_req_mbox_fwd  [core_idx];
            cache_scbd[core_idx].amo_resp_mbox_fwd = amo_resp_mbox_fwd [core_idx];

            cache_scbd[core_idx].aw_mbx_pre_filt   = aw_mbx            [core_idx];
            cache_scbd[core_idx].w_mbx_pre_filt    = w_mbx             [core_idx];
            cache_scbd[core_idx].b_mbx_pre_filt    = b_mbx             [core_idx];
            cache_scbd[core_idx].ar_mbx_pre_filt   = ar_mbx            [core_idx];
            cache_scbd[core_idx].r_mbx_pre_filt    = r_mbx             [core_idx];

            cache_scbd[core_idx].ac_mbx            = ac_mbx            [core_idx];
            cache_scbd[core_idx].cd_mbx            = cd_mbx            [core_idx];
            cache_scbd[core_idx].cr_mbx            = cr_mbx            [core_idx];

            cache_scbd[core_idx].mgmt_mbox         = mgmt_mbox         [core_idx];
        end

        // assign SRAM IF
        for (genvar w=0; w<DCACHE_SET_ASSOC; w++) begin
            assign sram_if[core_idx].data[w][0] = i_culsans.i_sram.i_tc_sram.sram[sram_if[core_idx].addr[w]];
            assign sram_if[core_idx].data[w][1] = i_culsans.i_sram.i_tc_sram.sram[sram_if[core_idx].addr[w]+1];
        end

    end


    bit enable_mem_check=1;
    initial begin
        dcache_chk = new(sram_if, dc_sram_if, ArianeCfg, "dcache_checker");
        void'($value$plusargs("ENABLE_MEM_CHECK=%b", enable_mem_check));
        dcache_chk.enable_mem_check = enable_mem_check;

        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
            dcache_chk.amo_req_mbox[core_idx]  = amo_req_mbox_fwd  [core_idx];
            dcache_chk.amo_resp_mbox[core_idx] = amo_resp_mbox_fwd [core_idx];

            dcache_chk.dcache_req_mbox[core_idx]  = dcache_req_mbox_fwd  [core_idx];
            dcache_chk.dcache_resp_mbox[core_idx] = dcache_resp_mbox_fwd [core_idx];
        end
    end

    // start custom AMO lock checker
    task automatic start_amo_check;
        fork
            dcache_chk.check_amo_lock();
        join_none
    endtask

    // start all monitors
    task automatic start_monitors;
        fork
            for (int c=0; c<NB_CORES; c++) begin : CORE
                fork
                    automatic int core_idx = c;
                    begin
                        for (int p=0; p<=2; p++) begin : PORT
                            fork
                                automatic int port = p;
                                begin
                                    dcache_mon[core_idx][port].monitor();
                                end
                            join_none
                        end
                    end
                    ace_mon[core_idx].monitor();
                    snoop_mon[core_idx].monitor();
                    amo_mon[core_idx].monitor();
                    dcache_mgmt_mon[core_idx].monitor();
                    cache_scbd[core_idx].run();
                join_none
            end
            if (enable_ccu_mon) begin
                ccu_mon_end_check = 1;
                ccu_mon.run();
            end
            dcache_chk.monitor();
        join_none
    endtask


    //--------------------------------------------------------------------------
    // Tests
    //--------------------------------------------------------------------------

    task test_header (string testname, string description="");
        $display("--------------------------------------------------------------------------");
        $display("Running test %s", testname);
        $display("%s", description);
        $display("--------------------------------------------------------------------------");
    endtask

    initial begin : TESTS
        integer file;
        integer error;
        static    string mem_init_file = "main.hex";
        automatic string testname      = "";

        if (!$value$plusargs("TESTNAME=%s", testname)) begin
            $error("No TESTNAME plusarg given");
        end

        test_header(testname, "");

        @(posedge rst_n);
        #2
        $readmemh(mem_init_file, i_culsans.i_sram.i_tc_sram.sram);

        case (testname)
            "amo_mutex", "raw_spin_lock" : begin
                // These tests rely on the AMO lock checker
                start_monitors();
                start_amo_check();
            end
        endcase

        wait (exit_val[0]);

        file = $fopen("result.rpt", "w");
        if ((exit_val >> 1)) begin
            $error("*** FAILED *** (tohost = %0d)", (exit_val >> 1));
            $display("return code: 0x%x", (exit_val >> 1));
            $fdisplay(file, "FAIL");
            $fdisplay(file, "return code: 0x%x", (exit_val >> 1));
        end else begin
            $info("*** SUCCESS *** (tohost = %0d)", (exit_val >> 1));
            $fdisplay(file, "PASS");
        end
        $fclose(file);

        //--------------------------------------------------------------
        // end of tests
        //--------------------------------------------------------------
        `WAIT_CYC(clk, 100)
        $display("Test done");
        $finish();
    end

endmodule
