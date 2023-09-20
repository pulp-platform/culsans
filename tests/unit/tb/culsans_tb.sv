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
        .exit_o ( /* NC */ )
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

        assign gnt_if[core_idx].snoop_wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[1] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[1];

        assign gnt_if[core_idx].bypass_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[0];
        assign gnt_if[core_idx].bypass_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[1];
        assign gnt_if[core_idx].bypass_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[2];

        assign gnt_if[core_idx].miss_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[0];
        assign gnt_if[core_idx].miss_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[1];
        assign gnt_if[core_idx].miss_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[2];

        assign gnt_if[core_idx].wr_gnt[0] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_req[0];

        assign gnt_if[core_idx].wr_gnt[1] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_req[1] &&
                                            !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_req[0];

        assign gnt_if[core_idx].wr_gnt[2] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_req[2] &&
                                            !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_req[1] &&
                                            !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_req[0];


        // assign management IF
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_en_csr_nbdcache  = mgmt_if[core_idx].dcache_enable;
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ctrl_cache = mgmt_if[core_idx].dcache_flush;
        assign mgmt_if[core_idx].dcache_flushing  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.flushing;
        assign mgmt_if[core_idx].dcache_flush_ack = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ack_cache_ctrl;
        assign mgmt_if[core_idx].dcache_miss      = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_miss_cache_perf;
        assign mgmt_if[core_idx].wbuffer_empty    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_commit_wbuffer_empty;

        initial begin : DCACHE_MGMT_DRV
            dcache_mgmt_drv[core_idx] = new(mgmt_if[core_idx], $sformatf("%s[%0d]","dcache_mgmt_driver",core_idx));
        end
        initial begin : DCACHE_MGMT_MON
            mgmt_mbox[core_idx] = new();
            dcache_mgmt_mon[core_idx] = new(mgmt_if[core_idx], $sformatf("%s[%0d]","dcache_mgmt_monitor",core_idx));
            dcache_mgmt_mon[core_idx].mbox = mgmt_mbox[core_idx];
            dcache_mgmt_mon[core_idx].monitor();
        end

        for (genvar port=0; port<=2; port++) begin : PORT
            // assign dcache request/response to dcache_if
            assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port] = dcache_if[core_idx][port].req;
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

            initial begin : DCACHE_DRV
                dcache_drv[core_idx][port] = new(dcache_if[core_idx][port], ArianeCfg, $sformatf("%s[%0d][%0d]","dcache_driver",core_idx, port));
            end

            //------------------------------------------------------------------
            // check that the read responds match the read requests
            //------------------------------------------------------------------
/* Don't commit these just yet
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
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req = amo_if[core_idx].req;
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

        initial begin : AMO_DRV
            amo_drv[core_idx] = new(amo_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","amo_driver",core_idx));
        end


        initial begin : CACHE_SCBD
            cache_scbd[core_idx] = new(dc_sram_if[core_idx], gnt_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","dcache_scoreboard",core_idx));

            cache_scbd[core_idx].dcache_req_mbox  = dcache_req_mbox  [core_idx];
            cache_scbd[core_idx].dcache_resp_mbox = dcache_resp_mbox [core_idx];

            cache_scbd[core_idx].amo_req_mbox     = amo_req_mbox     [core_idx];
            cache_scbd[core_idx].amo_resp_mbox    = amo_resp_mbox    [core_idx];

            cache_scbd[core_idx].aw_mbx           = aw_mbx           [core_idx];
            cache_scbd[core_idx].w_mbx            = w_mbx            [core_idx];
            cache_scbd[core_idx].b_mbx            = b_mbx            [core_idx];
            cache_scbd[core_idx].ar_mbx           = ar_mbx           [core_idx];
            cache_scbd[core_idx].r_mbx            = r_mbx            [core_idx];

            cache_scbd[core_idx].ac_mbx           = ac_mbx           [core_idx];
            cache_scbd[core_idx].cd_mbx           = cd_mbx           [core_idx];
            cache_scbd[core_idx].cr_mbx           = cr_mbx           [core_idx];

            cache_scbd[core_idx].mgmt_mbox        = mgmt_mbox        [core_idx];

            cache_scbd[core_idx].run();
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
        dcache_chk.monitor();
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
                    "read_miss" : begin
                        test_header(testname, "8 consecutive read misses in the same cache set");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // write to address 0-7 and then some more
                        for (int i=0; i<16; i++) begin
                            dcache_drv[cid][2].wr(.addr(addr + (i << DCACHE_INDEX_WIDTH)), .data(i));
                        end

                        // read miss x 8 - fill cache 0
                        for (int i=0; i<8; i++) begin
                            dcache_drv[cid][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)));
                        end

                        `WAIT_CYC(clk, 100)
                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "write_collision" : begin
                        test_header(testname, "Part 1 : Write conflicts to single address");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make sure data 0 is in cache
                        for (int c=0; c < NB_CORES; c++) begin
                            dcache_drv[c][0].rd(.addr(addr));
                            `WAIT_CYC(clk, 100)
                        end

                        // simultaneous writes to same address
                        for (int i=0; i<100; i++) begin
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        if (cc == cid) begin
                                            dcache_drv[cc][2].wr(.addr(addr), .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));
                                            `WAIT_CYC(clk, 10)
                                            dcache_drv[cc][2].wr(.addr(addr), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));
                                        end else begin
                                            dcache_drv[cc][2].wr(.addr(addr), .data(64'hBAADF00D0000 + i), .rand_size_be(1));
                                            `WAIT_CYC(clk, ((i+cc)%19))
                                            dcache_drv[cc][2].wr(.addr(addr), .data(64'hDEADABBA0000 + i), .rand_size_be(1));
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end

                        `WAIT_CYC(clk, 100)

                        test_header(testname, "Part 2 : Write conflicts to addresses in the same cache set");

                        // simultaneous writes to same set
                        for (int i=0; i<100; i++) begin
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        if (cc == cid) begin
                                            dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));
                                            `WAIT_CYC(clk, 10)
                                            dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));
                                            `WAIT_CYC(clk, 10)
                                        end else begin
                                            dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBAADF00D0000 + i), .rand_size_be(1));
                                            `WAIT_CYC(clk, (i+cc)%19)
                                            dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hDEADABBA0000 + i), .rand_size_be(1));
                                            `WAIT_CYC(clk, 10)
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_write_collision" : begin
                        test_header(testname, "Part 1 : Write + read conflicts to single address");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make sure data 0 is in cache
                        for (int c=0; c < NB_CORES; c++) begin
                            dcache_drv[c][0].rd(.addr(addr));
                            `WAIT_CYC(clk, 100)
                        end

                        // simultaneous writes and read to same address
                        for (int i=0; i<100; i++) begin
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        `WAIT_CYC(clk, $urandom_range(5))
                                        if ((cc % 2) == 0 ) begin
                                            dcache_drv[cc][0].rd(.addr(addr), .rand_size_be(1));
                                        end else begin
                                            dcache_drv[cc][2].wr(.addr(addr), .data(64'hBAADF00D0000 + i), .rand_size_be(1));
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end

                        `WAIT_CYC(clk, 100)

                        test_header(testname, "Part 2 : Write + read conflicts to addresses in the same cache set");

                        // read x 8 - fill cache set 0 in CPU 0
                        for (int c=0; c < NB_CORES; c++) begin
                            for (int i=0; i<8; i++) begin
                                dcache_drv[c][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)), .rand_size_be(1));
                            end
                        end

                        // simultaneous writes and reads to same set
                        for (int i=0; i<500; i++) begin
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        if ((cc % 2) == 0 ) begin
                                            dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH)),     .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));
                                            `WAIT_CYC(clk, 10)
                                            dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));
                                        end else begin
                                            dcache_drv[cc][0].rd(.addr(addr+ ((i%8) << DCACHE_INDEX_WIDTH)), .rand_size_be(1));
                                            `WAIT_CYC(clk, $urandom_range(20))
                                            dcache_drv[cc][0].rd(.addr(addr+ ((i%8) << DCACHE_INDEX_WIDTH) + 8), .rand_size_be(1));
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end

                        `WAIT_CYC(clk, 100)
                    end


                    //******************************************************************************
                    //*** NOTE: this test currently fails at it hits bug described in PROJ-269
                    //******************************************************************************
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "cacheline_rw_collision" : begin
                        test_header(testname, "Read cacheline while it is being updated");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        repeat (100) begin
                            addr = addr + 32;
                            // write data in one core
                            dcache_drv[cid][2].wr(.addr(addr),    .data(64'hBEEFCAFE0000));
                            dcache_drv[cid][2].wr(.addr(addr+8),  .data(64'hBEEFCAFE8888));
                            dcache_drv[cid][2].wr(.addr(addr+16), .data(64'hDEADABBA0000));
                            `WAIT_CYC(clk, 100)
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        if (cc != cid) begin
                                            // read data in other cores
                                            dcache_drv[cc][1].rd_wait(.addr(addr));
                                            dcache_drv[cc][1].rd_wait(.addr(addr+8));
                                            dcache_drv[cc][1].rd_wait(.addr(addr+16));
                                            // data is now shared in this core
                                            `WAIT_CYC(clk, $urandom_range(10))
                                            fork
                                                begin
                                                    // write to one part of cacheline (causing cache update)
                                                    `WAIT_CYC(clk, $urandom_range(5))
                                                    dcache_drv[cc][2].wr(.addr(addr+8), .rand_data(1));
                                                end
                                                begin
                                                    // at the same time, read other cache line
                                                    `WAIT_CYC(clk, $urandom_range(10))
                                                    dcache_drv[cc][1].rd(.addr(addr));
                                                    `WAIT_CYC(clk, $urandom_range(10))
                                                    dcache_drv[cc][1].rd_wait(.addr(addr+16), .check_result(1), .exp_result(64'hDEADABBA0000));
                                                end
                                            join
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                            `WAIT_CYC(clk, 100)
                        end
                    end




                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "flush_collision" : begin
                        test_header(testname, "Flush the cache while other core is accessing its contents");

                        // core 1 will have to wait for flush, increase timeout
                        cache_scbd[1].set_cache_msg_timeout(50000);

                        // core 0 mgmt will have to wait for flush, increase timeout
                        cache_scbd[0].set_mgmt_trans_timeout (50000);

                        timeout = 200000; // long tests


                        // other snooped cores will have to wait for flush, increase timeout
                        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                            if (core_idx != 1) begin
                                cache_scbd[core_idx].set_snoop_msg_timeout(10000);
                            end
                        end

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // fill up cache
                        for (int i=0; i<2048; i++) begin
                            dcache_drv[0][2].wr(.addr(addr + i*8),  .data(64'hBEEFCAFE0000 + i));
                        end

                        fork
                            begin
                                // flush
                                dcache_mgmt_drv[0].flush();
                            end
                            begin
                                for (int i=2047;  i>=0; i--) begin
                                    dcache_drv[1][1].rd_wait(.addr(addr + i*8), .check_result(1), .exp_result(64'hBEEFCAFE0000 + i));
                                end
                            end
                        join

                        `WAIT_CYC(clk, 50000) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "evict_collision" : begin
                        test_header(testname, "Collision between eviction in one core and access in others");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 200;
                        timeout   = 400000; // long test

                        for (int r=0; r<rep_cnt; r++) begin

                            // fill up cache set
                            for (int i=0; i<8; i++) begin
                                automatic logic [63:0] laddr = base_addr + (i << DCACHE_INDEX_WIDTH);
                                dcache_drv[cid][2].wr(.addr(laddr), .data(i + cid*1024));
                            end

                            `WAIT_CYC(clk, 100)

                            // cause collision
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    automatic int port;
                                    automatic logic [63:0] laddr;
                                    begin
                                        if (cc == cid) begin
                                            // cause evictions in one core
                                            for (int i=8; i<16; i++) begin
                                                laddr = base_addr + (i << DCACHE_INDEX_WIDTH);
                                                port = $urandom_range(2);
                                                // add none or a few cycles between requests
                                                `WAIT_CYC(clk, $urandom_range(4,0));
                                                // evictions are caused by read or write
                                                case (port)
                                                    0, 1 : dcache_drv[cc][port].rd_wait(.addr(laddr), .rand_size_be(1));
                                                    2    : dcache_drv[cc][port].wr(.addr(laddr), .data(i + cc*1024), .rand_size_be(1));
                                                endcase
                                            end
                                        end else begin
                                            // access the evicted addresses in other cores
                                            for (int i=0; i<8; i++) begin
                                                automatic int offset;
                                                offset  = (i + cc) % 8;
                                                laddr = base_addr + (offset << DCACHE_INDEX_WIDTH);
                                                port  = $urandom_range(3);
                                                // add none or a few cycles between requests
                                                `WAIT_CYC(clk, $urandom_range(4,0));
                                                // create conflict with read, write, or AMO
                                                case (port)
                                                    0, 1 : dcache_drv[cc][port].rd_wait(.addr(laddr), .rand_size_be(1));
                                                    2    : dcache_drv[cc][port].wr(.addr(laddr), .data(i + cc*1024), .rand_size_be(1));
                                                    3    : amo_drv[cc].req(.addr(laddr), .rand_op(1), .data(i + cc*1024));
                                                endcase
                                            end
                                        end
                                    end
                                join_none
                            end
                            wait fork;

                            `WAIT_CYC(clk, 100)
                        end

                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_write" : begin
                        test_header(testname, "AMO reads and writes to single address");
                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        for (int c=0; c < NB_CORES; c++) begin
                            cache_scbd[c].set_amo_msg_timeout(10000);
                        end


                        // simultaneous writes to same address
                        for (int i=0; i<10; i++) begin
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        if (cc == cid) begin
                                            amo_drv[cc].req(.addr(addr), .op(AMO_LR), .rand_data(1));
                                            `WAIT_CYC(clk, 5)
                                            amo_drv[cc].req(.addr(addr), .op(AMO_SC), .rand_data(1));
                                        end else begin
                                            amo_drv[cc].req(.addr(addr), .op(AMO_LR), .rand_data(1));
                                            `WAIT_CYC(clk, (i+cc))
                                            amo_drv[cc].req(.addr(addr), .op(AMO_SC), .rand_data(1));
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end

                        `WAIT_CYC(clk, 10000) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_lr_sc" : begin
                        test_header(testname, "AMO Load-Reserved / Store-Conditional test");
                        addr = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(1024) * 8; // AMO address must be aligned with memory

                        for (int c=0; c < NB_CORES; c++) begin
                            cache_scbd[c].set_amo_msg_timeout(10000);
                        end

                        ////////////////////////////////////////////////////////
                        // Single core
                        ////////////////////////////////////////////////////////
                        test_id=0;

                        // write known data to target address
                        data = 64'h0000CAFEBABE0000;
                        dcache_drv[cid][2].wr(.addr(addr),  .data(data));
                        `WAIT_CYC(clk, 100)

                        // Reserve the target, expect data
                        amo_drv[cid].req(.addr(addr), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                        `WAIT_CYC(clk, 100)

                        // store-conditional to the target, expect success
                        amo_drv[cid].req(.addr(addr), .op(AMO_SC), .data(data+1), .check_result(1),. exp_result(0));
                        `WAIT_CYC(clk, 100)

                        // store-conditional again to the target, expect failure
                        amo_drv[cid].req(.addr(addr), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(1));
                        `WAIT_CYC(clk, 100)

                        // read the value in target, expect value from first store
                        dcache_drv[cid][0].rd_wait(.addr(addr),  .check_result(1), .exp_result(data+1));
                        `WAIT_CYC(clk, 100)

                        ////////////////////////////////////////////////////////
                        // Two cores, reservation fails due to write form other core
                        ////////////////////////////////////////////////////////
                        test_id=1;

                        // core 0 writes known data to target address
                        data = 64'h0001CAFEBABE0000;
                        dcache_drv[0][2].wr(.addr(addr), .data(data));
                        `WAIT_CYC(clk, 100)

                        // Core 1 reserves the target, expect data
                        amo_drv[1].req(.addr(addr), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                        `WAIT_CYC(clk, 100)

                        // core 0 writes new data to target address
                        dcache_drv[0][2].wr(.addr(addr), .data(data+1));
                        `WAIT_CYC(clk, 100)

                        // core 1 store-conditional to the target, expect failure
                        amo_drv[1].req(.addr(addr), .op(AMO_SC), .data(data+3), .check_result(1),. exp_result(1));
                        `WAIT_CYC(clk, 100)

                        // read the value in target, expect value from regular write
                        dcache_drv[1][0].rd_wait(.addr(addr),  .check_result(1), .exp_result(data+1));
                        `WAIT_CYC(clk, 100)

                        ////////////////////////////////////////////////////////
                        // Two cores, reservation succeeds
                        ////////////////////////////////////////////////////////

                        test_id=2;

                        // core 0 writes known data to target address
                        data = 64'h0002CAFEBABE0000;
                        dcache_drv[0][2].wr(.addr(addr), .data(data));
                        `WAIT_CYC(clk, 100)

                        // Core 1 reserves the target, expect data
                        amo_drv[1].req(.addr(addr), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                        `WAIT_CYC(clk, 100)
/*
                        // core 1 writes new data to target address
                        // results in clearing the reservation => a subsequent store conditional would not succeed
                        dcache_drv[1][2].wr(.addr(addr), .data(data+1));
                        `WAIT_CYC(clk, 100)

                        // core 0 reads the value in target, expect value from regular write
                        dcache_drv[0][0].rd_wait(.addr(addr),  .check_result(1), .exp_result(data+1));
                        `WAIT_CYC(clk, 100)
*/
                        // core 1 store-conditional to the target, expect success
                        amo_drv[1].req(.addr(addr), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(0));
                        `WAIT_CYC(clk, 100)

                        // core 0 read the value in target, expect value from conditional store
                        dcache_drv[0][0].rd_wait(.addr(addr),  .check_result(1), .exp_result(data+2));
                        `WAIT_CYC(clk, 100)

                        // core 1 store-conditional to the target, expect failure
                        amo_drv[1].req(.addr(addr), .op(AMO_SC), .data(data+3), .check_result(1),. exp_result(1));
                        `WAIT_CYC(clk, 100)

                        // core 0 read the value in target, expect value from successful conditional store
                        dcache_drv[0][0].rd_wait(.addr(addr),  .check_result(1), .exp_result(data+2));
                        `WAIT_CYC(clk, 100)

                        `WAIT_CYC(clk, 10000) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end



                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_write_collision" : begin
                        test_header(testname, "AMO write and read while other cores are active");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;

                        for (int c=0; c < NB_CORES; c++) begin
                            // other cores may have to wait for AMO
                            if (c != cid) begin
                                cache_scbd[c].set_cache_msg_timeout(10000);
                            end
                        end

                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                automatic int port;
                                automatic int offset;
                                begin
                                    if (cc == cid) begin
                                        `WAIT_CYC(clk, rep_cnt*10)
                                        amo_drv[cc].req(.addr(base_addr), .op(AMO_SC));
                                        `WAIT_CYC(clk, 5)
                                        amo_drv[cc].req(.addr(base_addr), .op(AMO_LR));
                                    end else begin
                                        for (int i=0; i<rep_cnt; i++) begin
                                            port   = $urandom_range(2);
                                            offset = $urandom_range(1024);
                                            if (port == 2) begin
                                                dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                            end else begin
                                                dcache_drv[cc][port].rd_wait(.addr(base_addr + offset), .rand_size_be(1));
                                            end
                                        end
                                    end
                                end
                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 10000) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_cached" : begin
                        // This test is targeted towards triggering bug PROJ-153: "AMO read of cached data returns wrong data"
                        test_header(testname, "AMO requests data cached in other core");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];

                        // write data to cache in core 1
                        dcache_drv[1][2].wr(.addr(base_addr),     .data(64'hCAFEBABE_00000000));
                        dcache_drv[1][2].wr(.addr(base_addr + 8), .data(64'hBAADF00D_11111111));

                        // amo read
                        amo_drv[0].req(.addr(base_addr),     .op(AMO_LR), .check_result(1), .exp_result(64'hCAFEBABE_00000000));
                        amo_drv[0].req(.addr(base_addr + 8), .op(AMO_LR), .check_result(1), .exp_result(64'hBAADF00D_11111111));

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_snoop_single_collision" : begin
                        // This test is targeted towards triggering bug PROJ-150: "AMO request skips cache flush if snoop_cache_ctrl is busy"
                        test_header(testname, "Single AMO request while receiving snoop");

                        addr = ArianeCfg.CachedRegionAddrBase[0];
                        fork
                            begin
                                // make sure there is something dirty in the cache of core 0
                                dcache_drv[0][2].wr(.addr(addr));
                                // allow snoop from core 1 to propagate
                                `WAIT_CYC(clk, 15)
                                // AMO request, should cause flush and writeback of data in cache
                                amo_drv[0].req(.addr(addr), .rand_op(1));
                                // another request outside cacheable regions will trigger the AW beat and detect the mismatch
                                dcache_drv[0][2].wr(.addr(ArianeCfg.SharedRegionAddrBase[0]));
                            end
                            begin
                                // read cache in core 1 to trigger a snoop transaction towards other cores
                                dcache_drv[1][0].rd(.addr(addr+1));
                            end
                        join

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_upper_cache_line" : begin
                        logic [63:0] data8, data16;
                        // This test is targeted towards triggering a bug in PROJ-151 that caused writeback of "next" cache line
                        test_header(testname, "Single AMO request towards upper part of cache line");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // write known value to address 16 in core 0
                        data16 = 64'h00000000_CAFEBABE;
                        dcache_drv[0][2].wr(.addr(addr + 16), .data(data16));

                        `WAIT_CYC(clk, 100)

                        // write something to address 8 in core 1
                        data8 = 64'h1111BAAD_F00D0000;
                        dcache_drv[1][2].wr(.addr(addr + 8), .data(data8));

                        `WAIT_CYC(clk, 100)

                        // AMO request to increment data8, should cause flush and writeback of data16 in cache
                        amo_drv[0].req(.addr(addr + 8), .op(AMO_ADD), .data(17), .check_result(1), .exp_result(data8));
                        data8 = data8 + 17;

                        `WAIT_CYC(clk, 100)

                        // check expected values
                        dcache_drv[0][1].rd_wait(.addr(addr + 16), .check_result(1), .exp_result(data16));

                        `WAIT_CYC(clk, 100)

                        dcache_drv[0][1].rd_wait(.addr(addr + 8),  .check_result(1), .exp_result(data8));

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_snoop_collision" : begin
                        test_header(testname, "AMO request flushing the cache while other core is accessing its contents");

                        // core 1 will have to wait for flush, increase timeout
                        cache_scbd[1].set_cache_msg_timeout(50000);

                        // core 0 will have to wait for flush, increase timeout
                        cache_scbd[0].set_amo_msg_timeout(50000);

                        timeout = 200000; // long tests

                        // other snooped cores will have to wait for flush, increase timeout
                        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                            if (core_idx != 1) begin
                                cache_scbd[core_idx].set_snoop_msg_timeout(10000);
                            end
                        end

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // fill up cache
                        for (int i=0; i<2048; i++) begin
                            dcache_drv[0][2].wr(.addr(addr + i*8),  .data(64'hBEEFCAFE0000 + i));
                        end

                        fork
                            begin
                                // AMO request, should cause flush and writeback of data in cache
                                amo_drv[0].req(.addr(addr), .rand_op(1));
                            end
                            begin
                                for (int i=2047;  i>=1; i--) begin // don't verify address (addr + 0), it may have been modified by AMO
                                    dcache_drv[1][1].rd_wait(.addr(addr + i*8), .check_result(1), .exp_result(64'hBEEFCAFE0000 + i));
                                end
                            end
                        join

                        `WAIT_CYC(clk, 50000) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached", "random_shared", "random_non-shared" : begin

                        case (testname)
                            "random_cached" : begin
                                test_header(testname, "Writes and reads to random cacheable, shareable addresses, excluding AMO requests");
                                base_addr = ArianeCfg.CachedRegionAddrBase[0];
                            end
                            "random_shared" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, shareable addresses, excluding AMO requests");
                                base_addr = ArianeCfg.SharedRegionAddrBase[0];
                            end
                            "random_non-shared" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, non-shareable addresses, excluding AMO requests");
                                base_addr = culsans_pkg::DRAMBase;
                            end
                        endcase

                        // LLC and random AXI delay cause longer tests
                        wait_time = 10000;
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   = 300000;
                            wait_time = 20000;
                            for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                                cache_scbd[core_idx].set_cache_msg_timeout(20000);
                            end
                        end

                        rep_cnt   = 1000;
                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        automatic int offset [3];
                                        for (int p=0; p<3; p++) begin
                                            automatic bit hit;
                                            // Randomize address, make sure write address is different from read addresses.
                                            // This emulates to some extent how the core schedules requests.
                                            // Only use 8-byte aligned addresses to make final comparison less complex
                                            do begin
                                                hit = $urandom_range(1);
                                                case (testname)
                                                    "random_cached"     : offset[p] = hit ? $urandom_range(64) : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                                    "random_shared"     : offset[p] = hit ? $urandom_range(64) : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - base_addr); // don't enter the cached region
                                                    "random_non-shared" : offset[p] = hit ? $urandom_range(64) : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                                endcase

                                                offset[p] = (offset[p] / 8) * 8;

                                            end while ((p == 2) && ((offset[2] == offset[1]) ||
                                                                    (offset[2] == offset[0])));
                                        end

                                        for (int p=0; p<3; p++) begin
                                            fork
                                                automatic int port = p;
                                                begin
                                                    // add none or a few cycles between requests
                                                    `WAIT_CYC(clk, $urandom_range(4,0));
                                                    // submit a request on each port with a probability
                                                    if ($urandom_range(100) > 50) begin
                                                        if (port == 2) begin
                                                            dcache_drv[cc][2].wr(.addr(base_addr + offset[port]), .data(64'hBEEFCAFE00000000 + offset[port]), .rand_size_be(1));
                                                        end else begin
                                                            dcache_drv[cc][port].rd_wait(.addr(base_addr + offset[port]), .rand_size_be(1));
                                                        end
                                                    end
                                                end
                                            join_none
                                        end
                                        wait fork;
                                    end
                                end
                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, wait_time) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_amo", "random_shared_amo", "random_non-shared_amo" : begin
                        case (testname)
                            "random_cached_amo" : begin
                                test_header(testname, "Writes and reads to random cacheable, shareable addresses, including AMO requests");
                                base_addr = ArianeCfg.CachedRegionAddrBase[0];
                            end
                            "random_shared_amo" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, shareable addresses, including AMO requests");
                                base_addr = ArianeCfg.SharedRegionAddrBase[0];
                            end
                            "random_non-shared_amo" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, non-shareable addresses, including AMO requests");
                                base_addr = culsans_pkg::DRAMBase;
                            end
                        endcase

                        rep_cnt   = 1000;
                        timeout   = 150000; // long test
                        wait_time = 10000;

                        // LLC and random AXI delay cause longer tests
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   = 300000;
                            wait_time = 20000;
                            for (int c=0; c < NB_CORES; c++) begin
                                cache_scbd[c].set_amo_msg_timeout(wait_time);
                            end
                        end

                        for (int c=0; c < NB_CORES; c++) begin
                            // any core may have to wait for AMO/flush, increase timeouts
                            cache_scbd[c].set_cache_msg_timeout(wait_time);
                            cache_scbd[c].set_snoop_msg_timeout(wait_time);
                        end

                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        automatic int offset [3];
                                        for (int p=0; p<3; p++) begin
                                            automatic bit hit;
                                            // Randomize address, make sure write address is different from read addresses.
                                            // This emulates to some extent how the core schedules requests.
                                            // Only use 8-byte aligned addresses to make final comparison less complex
                                            do begin
                                                hit = $urandom_range(1);
                                                case (testname)
                                                    "random_cached_amo"     : offset[p] = hit ? $urandom_range(64) : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                                    "random_shared_amo"     : offset[p] = hit ? $urandom_range(64) : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - base_addr); // don't enter the cached region
                                                    "random_non-shared_amo" : offset[p] = hit ? $urandom_range(64) : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                                endcase

                                                offset[p] = (offset[p] / 8) * 8;

                                            end while ((p == 2) && ((offset[2] == offset[1]) ||
                                                                    (offset[2] == offset[0])));
                                        end

                                        // submit requests, or possibly an AMO
                                        if ($urandom_range(100) > 99) begin
                                            amo_drv[cc].req(.addr(base_addr+offset[0]), .rand_op(1),. rand_data(1));
                                        end else begin
                                            for (int p=0; p<3; p++) begin
                                                fork
                                                    automatic int port = p;
                                                    begin
                                                        // add none or a few cycles between requests
                                                        `WAIT_CYC(clk, $urandom_range(4,0));
                                                        // submit a request on each port with a probability
                                                        if ($urandom_range(100) > 50) begin
                                                            if (port == 2) begin
                                                                dcache_drv[cc][2].wr(.addr(base_addr + offset[port]), .data(64'hBEEFCAFE00000000 + offset[port]), .rand_size_be(1));
                                                            end else begin
                                                                dcache_drv[cc][port].rd_wait(.addr(base_addr + offset[port]), .rand_size_be(1));
                                                            end

                                                        end
                                                    end
                                                join_none
                                            end
                                            wait fork;
                                        end
                                    end
                                end
                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, wait_time) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_flush" : begin
                        test_header(testname, "Writes and reads to random cacheable addresses mixed with occasional flush");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];

                        rep_cnt   = 1000;
                        timeout   = 100000; // long test

                        for (int c=0; c < NB_CORES; c++) begin
                            // any core may have to wait for flush, increase timeouts
                            cache_scbd[c].set_cache_msg_timeout(10000);
                            cache_scbd[c].set_snoop_msg_timeout(10000);
                        end

                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                automatic int port;
                                automatic int offset;
                                automatic bit hit;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        if ($urandom_range(99) < 99) begin
                                            port   = $urandom_range(2);
                                            hit    = $urandom_range(1);
                                            offset = hit ? $urandom_range(8) : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region

                                            if (port == 2) begin
                                                dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                            end else begin
                                                dcache_drv[cc][port].rd_wait(.addr(base_addr + offset), .rand_size_be(1));
                                            end
                                        end else begin
                                            dcache_mgmt_drv[cc].flush();
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 10000) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_shared" : begin
                        test_header(testname, "Writes and reads to random addresses:\n  cacheable\n  shareable, non-cacheable");

                        rep_cnt   = 1000;
                        wait_time = 1000;

                        // LLC and random AXI delay cause longer tests
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   = 300000;
                            wait_time = 10000;
                            for (int c=0; c < NB_CORES; c++) begin
                                cache_scbd[c].set_cache_msg_timeout(wait_time);
                            end
                        end

                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;
                                automatic bit hit;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        addr_region = $urandom_range(1);
                                        hit         = $urandom_range(1);

                                        case (addr_region)
                                            0 : begin
                                                base_addr = ArianeCfg.CachedRegionAddrBase[0];
                                                offset    = hit ? $urandom_range(8) : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                            end
                                            default : begin
                                                base_addr = ArianeCfg.SharedRegionAddrBase[0];
                                                offset    = hit ? $urandom_range(8) : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - base_addr); // don't enter the cached region
                                            end
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                        end else begin
                                            dcache_drv[cc][port].rd_wait(.addr(base_addr + offset), .rand_size_be(1));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, wait_time) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_non-shared" : begin
                        test_header(testname, "Writes and reads to random addresses:\n  cacheable\n  non-shareable, non-cacheable");

                        rep_cnt   = 1000;
                        wait_time = 1000;

                        // LLC and random AXI delay cause longer tests
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   = 300000;
                            wait_time = 10000;
                            for (int c=0; c < NB_CORES; c++) begin
                                cache_scbd[c].set_cache_msg_timeout(wait_time);
                            end
                        end



                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;
                                automatic bit hit;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        addr_region = $urandom_range(1);
                                        hit         = $urandom_range(1);

                                        case (addr_region)
                                            0 : begin
                                                base_addr = ArianeCfg.CachedRegionAddrBase[0];
                                                offset    = hit ? $urandom_range(8) : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                            end
                                            default : begin
                                                base_addr = culsans_pkg::DRAMBase;
                                                offset    = hit ? $urandom_range(8) : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                            end
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                        end else begin
                                            dcache_drv[cc][port].rd_wait(.addr(base_addr + offset), .rand_size_be(1));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, wait_time) // make sure we see timeouts

                        `WAIT_CYC(clk, 1000)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_shared_non-shared" : begin
                        test_header(testname, "Writes and reads to random addresses:\n  shareable, non-cacheable\n  non-shareable, non-cacheable");

                        rep_cnt   = 1000;
                        wait_time = 1000;

                        // LLC and random AXI delay cause longer tests
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   = 300000;
                            wait_time = 10000;
                            for (int c=0; c < NB_CORES; c++) begin
                                cache_scbd[c].set_cache_msg_timeout(wait_time);
                            end
                        end


                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;
                                automatic bit hit;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        addr_region = $urandom_range(1);
                                        hit         = $urandom_range(1);

                                        case (addr_region)
                                            0 : begin
                                                base_addr = ArianeCfg.SharedRegionAddrBase[0];
                                                offset    = hit ? $urandom_range(8) : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                            end
                                            default : begin
                                                base_addr = culsans_pkg::DRAMBase;
                                                offset    = hit ? $urandom_range(8) : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                            end
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                        end else begin
                                            dcache_drv[cc][port].rd_wait(.addr(base_addr + offset), .rand_size_be(1));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, wait_time) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_all" : begin
                        test_header(testname, "Writes and reads to random addresses in all address areas");

                        rep_cnt   = 1000;


                        // LLC and random AXI delay cause longer tests
                        wait_time = 10000;
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   = 300000;
                            wait_time = 20000;
                            for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                                cache_scbd[core_idx].set_cache_msg_timeout(20000);
                            end
                        end

                        for (int c=0; c < NB_CORES; c++) begin
                            fork
                                automatic int cc = c;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;
                                automatic bit hit;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        addr_region = $urandom_range(2);
                                        hit         = $urandom_range(1);

                                        case (addr_region)
                                            0 : begin
                                                base_addr = ArianeCfg.CachedRegionAddrBase[0];
                                                offset    = hit ? $urandom_range(8) : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                            end
                                            1 : begin
                                                base_addr = ArianeCfg.SharedRegionAddrBase[0];
                                                offset    = hit ? $urandom_range(8) : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - base_addr); // don't enter the cached region
                                            end
                                            default : begin
                                                base_addr = culsans_pkg::DRAMBase;
                                                offset    = hit ? $urandom_range(8) : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                            end
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                        end else begin
                                            dcache_drv[cc][port].rd_wait(.addr(base_addr + offset), .rand_size_be(1));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, wait_time) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "snoop_non-cached_collision" : begin
                        test_header(testname, "CLEAN_INVALID from core 1 colliding with bypass read in core 0.\nTrigger issue described in JIRA issue PROJ-149");
                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make cache entry is dirty in cache 0
                        dcache_drv[0][2].wr(.addr(addr));
                        // make cache entry shared in cache 1
                        dcache_drv[1][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)

                        fork
                            begin
                                // core 0 : read from shared region
                                `WAIT_CYC(clk, 3)
                                dcache_drv[0][0].rd(.addr(ArianeCfg.SharedRegionAddrBase[0]));
                            end
                            begin
                                // core 1 : write to dirty cache entry, causing CLEAN_INVALID
                                dcache_drv[1][2].wr(.addr(addr));
                            end
                        join

                        `WAIT_CYC(clk, 10000) // make sure timeout gets triggered
                    end


                    //******************************************************************************
                    //*** NOTE: this test currently fails at it hits bug described in PROJ-147
                    //******************************************************************************
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_two_writes_back_to_back" : begin
                        test_header(testname, "Single read followed by two writes back to back\nTrigger issue described in JIRA issue PROJ-147");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make sure data[0] is in cache
                        dcache_drv[0][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)

                        // read followed by 2 writes (here with 1 cc inbetween, could be back-to-back too)
                        dcache_drv[0][0].rd(.addr(addr));
                        dcache_drv[0][0].wr(.addr(addr), .data(32'hBBBBBBBB));
                        `WAIT_CYC(clk, 1)
                        dcache_drv[0][0].wr(.addr(addr), .data(32'hCCCCCCCC));
                        `WAIT_CYC(clk, 1)
                        // read 0 again to visualize in waveforms that the value 0xCCCCCCCC is not stored
                        dcache_drv[0][0].rd(.addr(addr));

                        `WAIT_CYC(clk, 100)
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
