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

    localparam              CLK_PERIOD       = 10ns;
    localparam int unsigned RTC_CLOCK_PERIOD = 30.517us;


    // TB signals
    dcache_req_i_t [culsans_pkg::NB_CORES-1:0][2:0] dcache_req_ports_i;
    dcache_req_o_t [culsans_pkg::NB_CORES-1:0][2:0] dcache_req_ports_o;
    logic                                           clk;
    logic                                           rst_n;
    logic                                           rtc;

    // TB interfaces
    amo_intf                amo_if           [culsans_pkg::NB_CORES-1:0]      (clk);
    dcache_intf             dcache_if        [culsans_pkg::NB_CORES-1:0][2:0] (clk);
    dcache_sram_if          sram_if          [culsans_pkg::NB_CORES-1:0]      (clk);
    dcache_gnt_if           gnt_if           [culsans_pkg::NB_CORES-1:0]      (clk);

    // verification conponents
    dcache_driver           dcache_drv       [culsans_pkg::NB_CORES-1:0][2:0];
    dcache_monitor          dcache_mon       [culsans_pkg::NB_CORES-1:0][2:0];

    amo_driver              amo_drv          [culsans_pkg::NB_CORES-1:0];
    amo_monitor             amo_mon          [culsans_pkg::NB_CORES-1:0];

    mailbox #(dcache_req)   dcache_req_mbox  [culsans_pkg::NB_CORES-1:0][2:0];
    mailbox #(dcache_resp)  dcache_resp_mbox [culsans_pkg::NB_CORES-1:0][2:0];

    mailbox #(amo_req)      amo_req_mbox     [culsans_pkg::NB_CORES-1:0];
    mailbox #(amo_resp)     amo_resp_mbox    [culsans_pkg::NB_CORES-1:0];

    std_cache_scoreboard #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) cache_scbd [culsans_pkg::NB_CORES-1:0];

    // ACE mailboxes
    mailbox aw_mbx [culsans_pkg::NB_CORES-1:0];
    mailbox w_mbx  [culsans_pkg::NB_CORES-1:0];
    mailbox b_mbx  [culsans_pkg::NB_CORES-1:0];
    mailbox ar_mbx [culsans_pkg::NB_CORES-1:0];
    mailbox r_mbx  [culsans_pkg::NB_CORES-1:0];

    // Snoop mailboxes
    mailbox ac_mbx [culsans_pkg::NB_CORES-1:0];
    mailbox cd_mbx [culsans_pkg::NB_CORES-1:0];
    mailbox cr_mbx [culsans_pkg::NB_CORES-1:0];

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
        .InclSimDTM (1'b0),
        .NUM_WORDS  (4**10), // 4Kwords
        .BootAddress (culsans_pkg::DRAMBase + 64'h10_0000)
    ) i_culsans (
        .clk_i  (clk),
        .rtc_i  (rtc),
        .rst_ni (rst_n),
        .exit_o (exit_val)
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
    ) ace_bus [culsans_pkg::NB_CORES-1:0] ();

    ACE_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) ace_bus_dv [culsans_pkg::NB_CORES-1:0] (clk);


    SNOOP_BUS #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus [culsans_pkg::NB_CORES-1:0] ();

    SNOOP_BUS_DV #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus_dv [culsans_pkg::NB_CORES-1:0] (clk);


    // connect internal signals to interfaces, connect interfaces to dv interfaces
    `AXI_ASSIGN_MONITOR (axi_bus[0], i_culsans.to_xbar[0])
    `AXI_ASSIGN_MONITOR (axi_bus_dv[0], axi_bus[0])

    for (genvar core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
        `ACE_ASSIGN_FROM_REQ    (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o)
        `ACE_ASSIGN_FROM_RESP   (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_resp_i)
        `ACE_ASSIGN_MONITOR   (ace_bus_dv   [core_idx], ace_bus   [core_idx])

        `SNOOP_ASSIGN_FROM_REQ  (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_resp_i)
        `SNOOP_ASSIGN_FROM_RESP (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o)
        `SNOOP_ASSIGN_MONITOR (snoop_bus_dv [core_idx], snoop_bus [core_idx])
    end

    // AXI/ACE monitors
    ace_monitor #(
        .IW ( AxiIdWidth   ),
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth ),
        .UW ( AxiUserWidth )
    ) ace_mon [culsans_pkg::NB_CORES-1:0];

    snoop_monitor #(
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth )
    ) snoop_mon [culsans_pkg::NB_CORES-1:0];

    // CCU monitor & scoreboard
    ace_ccu_monitor #(
        .AxiAddrWidth      ( AxiAddrWidth               ),
        .AxiDataWidth      ( AxiDataWidth               ),
        .AxiIdWidthMasters ( AxiIdWidth                 ),
        .AxiIdWidthSlaves  ( culsans_pkg::IdWidthToXbar ),
        .AxiUserWidth      ( AxiUserWidth               ),
        .NoMasters         ( culsans_pkg::NB_CORES      ),
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

    for (genvar core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin : CORE

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
        assign sram_if[core_idx].vld_sram = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.valid_dirty_sram.gen_cut[0].gen_mem.i_tc_sram_wrapper.i_tc_sram.sram;
        for (genvar i = 0; i<DCACHE_SET_ASSOC; i++) begin : sram_block
            assign sram_if[core_idx].tag_sram[i]  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.sram_block[i].tag_sram.gen_cut[0].gen_mem.i_tc_sram_wrapper.i_tc_sram.sram;
            assign sram_if[core_idx].data_sram[0][i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.gen_cut[0].gen_mem.i_tc_sram_wrapper.i_tc_sram.sram;
            assign sram_if[core_idx].data_sram[1][i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.gen_cut[1].gen_mem.i_tc_sram_wrapper.i_tc_sram.sram;
        end

        // assign Grant IF
        assign gnt_if[core_idx].gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.gnt[0] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.we[0];

        assign gnt_if[core_idx].gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.gnt[1] &&
            !(|i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.updating_cache);

        assign gnt_if[core_idx].gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.gnt[2] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.we[2];

        assign gnt_if[core_idx].gnt[3] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.gnt[3] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.we[3];

        assign gnt_if[core_idx].gnt[4] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.gnt[4] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.we[4];

        assign gnt_if[core_idx].bypass_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.bypass_gnt[0];
        assign gnt_if[core_idx].bypass_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.bypass_gnt[1];
        assign gnt_if[core_idx].bypass_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.bypass_gnt[2];
        assign gnt_if[core_idx].bypass_gnt[3] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.bypass_gnt[3];

        for (genvar port=0; port<=2; port++) begin : PORT
            // assign dcache request/response to dcache_if
            assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port] = dcache_if[core_idx][port].req;
            assign dcache_if[core_idx][port].resp   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_cache_ex[port];
            assign dcache_if[core_idx][port].wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.gnt[port+2] &&
                                                      (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.master_ports[port+1].i_cache_ctrl.state_q == 0); // IDLE
            initial begin : DCACHE_MON
                dcache_req_mbox  [core_idx][port] = new();
                dcache_resp_mbox [core_idx][port] = new();

                dcache_mon[core_idx][port] = new(dcache_if[core_idx][port], port, $sformatf("%s[%0d][%0d]","dcache_monitor",core_idx, port));

                dcache_mon[core_idx][port].req_mbox  = dcache_req_mbox[ core_idx][port];
                dcache_mon[core_idx][port].resp_mbox = dcache_resp_mbox[core_idx][port];

                dcache_mon[core_idx][port].monitor();
            end

            initial begin : DCACHE_DRV
                dcache_drv[core_idx][port] = new(dcache_if[core_idx][port], $sformatf("%s[%0d][%0d]","dcache_driver",core_idx, port));
            end

        end

        // assign AMO IF
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req = amo_if[core_idx].req;
        assign amo_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_resp;
        assign amo_if[core_idx].gnt  = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q        == 0) && // IDLE
                                       (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.i_nbdcache.i_miss_handler.miss_req_valid == 0);
        initial begin : AMO_MON
            amo_req_mbox  [core_idx] = new();
            amo_resp_mbox [core_idx] = new();

            amo_mon[core_idx] = new(amo_if[core_idx], $sformatf("%s[%0d]","amo_monitor",core_idx));

            amo_mon[core_idx].req_mbox  = amo_req_mbox[core_idx];
            amo_mon[core_idx].resp_mbox = amo_resp_mbox[core_idx];

            amo_mon[core_idx].monitor();
        end

        initial begin : AMO_DRV
            amo_drv[core_idx] = new(amo_if[core_idx], $sformatf("%s[%0d]","amo_driver",core_idx));
        end


        initial begin : CACHE_SCBD
            cache_scbd[core_idx] = new(sram_if[core_idx], gnt_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","dcache_checker",core_idx));

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

            cache_scbd[core_idx].run();
        end

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
    int test_id = -1;
    int rep_cnt;

    initial begin : TESTS
        logic [63:0] addr, base_addr;

        automatic string testname="";
        if (!$value$plusargs("TESTNAME=%s", testname)) begin
            $error("No TESTNAME plusarg given");
        end


        fork

            begin

                `WAIT_SIG(clk, rst_n)
                `WAIT_CYC(clk, 300)

                case (testname)

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_miss" : begin
                        test_header(testname, "8 consecutive read misses in the same cache set");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // write to address 0-7 and then some more
                        for (int i=0; i<16; i++) begin
                            dcache_drv[0][2].wr(.addr(addr + (i << DCACHE_INDEX_WIDTH)), .data(i));
                        end

                        // read miss x 8 - fill cache 0
                        for (int i=0; i<8; i++) begin
                            dcache_drv[0][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)));
                        end

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "write_collision" : begin
                        test_header(testname, "Part 1 : Write conflicts to single address");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make sure data 0 is in cache
                        dcache_drv[0][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)
                        dcache_drv[1][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)

                        // simultaneous writes to same address
                        for (int i=0; i<100; i++) begin
                            fork
                                begin
                                    dcache_drv[0][2].wr(.addr(addr), .data(64'hBEEFCAFE0000 + i));
                                    `WAIT_CYC(clk, 10)
                                    dcache_drv[0][2].wr(.addr(addr), .data(64'hBEEFCAFE0100 + i));
                                end
                                begin
                                    dcache_drv[1][2].wr(.addr(addr), .data(64'hBAADF00D0000 + i));
                                    `WAIT_CYC(clk, (i%19))
                                    dcache_drv[1][2].wr(.addr(addr), .data(64'hDEADABBA0000 + i));
                                end
                            join
                        end

                        `WAIT_CYC(clk, 100)

                        test_header(testname, "Part 2 : Write conflicts to addresses in the same cache set");

                        // simultaneous writes to same set
                        for (int i=0; i<100; i++) begin
                            fork
                                begin
                                    dcache_drv[0][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBEEFCAFE0000 + i));
                                    `WAIT_CYC(clk, 10)
                                    dcache_drv[0][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBEEFCAFE0100 + i));
                                    `WAIT_CYC(clk, 10)
                                end
                                begin
                                    dcache_drv[1][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBAADF00D0000 + i));
                                    `WAIT_CYC(clk, i%19)
                                    dcache_drv[1][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hDEADABBA0000 + i));
                                    `WAIT_CYC(clk, 10)
                                end
                            join
                        end

                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_write_collision" : begin
                        test_header(testname, "Part 1 : Write + read conflicts to single address");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make sure data 0 is in cache
                        dcache_drv[0][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)
                        dcache_drv[1][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)

                        // simultaneous writes and read to same address
                        for (int i=0; i<100; i++) begin
                            fork
                                begin
                                    `WAIT_CYC(clk, $urandom_range(5))
                                    dcache_drv[0][0].rd(.addr(addr));
                                end
                                begin
                                    `WAIT_CYC(clk, $urandom_range(5))
                                    dcache_drv[1][2].wr(.addr(addr), .data(64'hBAADF00D0000 + i));
                                end
                            join
                        end

                        `WAIT_CYC(clk, 100)

                        test_header(testname, "Part 1 : Write + read conflicts to addresses in the same cache set");

                        // read x 8 - fill cache set 0 in CPU 0
                        for (int i=0; i<8; i++) begin
                            dcache_drv[0][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)));
                        end

                        // simultaneous writes to same set
                        for (int i=0; i<500; i++) begin
                            fork
                                begin
                                    dcache_drv[0][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH)),     .data(64'hBEEFCAFE0000 + i));
                                    `WAIT_CYC(clk, 10)
                                    dcache_drv[0][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8), .data(64'hBEEFCAFE0100 + i));
                                end
                                begin
                                    dcache_drv[1][0].rd(.addr(addr+ ((i%8) << DCACHE_INDEX_WIDTH)));
                                    `WAIT_CYC(clk, i%19)
                                    dcache_drv[1][0].rd(.addr(addr+ ((i%8) << DCACHE_INDEX_WIDTH) + 8));
                                end
                            join
                        end

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_write" : begin
                        test_header(testname, "AMO reads and writes to single address");
                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // simultaneous writes to same address
                        for (int i=0; i<10; i++) begin
                            fork
                                begin
                                    amo_drv[0].wr(.addr(addr), .data(64'hBEEFCAFE0000 + i));
                                    `WAIT_CYC(clk, 5)
                                    amo_drv[0].rd(.addr(addr));
                                end
                                begin
                                    amo_drv[1].wr(.addr(addr), .data(64'hBAADF00D0000 + i));
                                    `WAIT_CYC(clk, (i))
                                    amo_drv[1].rd(.addr(addr));
                                end
                            join
                        end

                        `WAIT_CYC(clk, 100)
                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_write_collision" : begin
                        test_header(testname, "AMO write and read while other core is active");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;
                        fork
                            begin
                                `WAIT_CYC(clk, rep_cnt*10)
                                amo_drv[0].wr(.addr(base_addr), .data(64'hBEEFCAFE0000));
                                `WAIT_CYC(clk, 5)
                                amo_drv[0].rd(.addr(base_addr));
                            end
                            begin
                                automatic int port;
                                automatic int offset;
                                for (int i=0; i<rep_cnt; i++) begin
                                    port   = $urandom_range(2);
                                    offset = $urandom_range(1024);
                                    if (port == 2) begin
                                        dcache_drv[1][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                    end else begin
                                        dcache_drv[1][port].rd_wait(.addr(base_addr + offset));
                                    end
                                end
                            end
                        join

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
                        amo_drv[0].rd(.addr(base_addr));
                        amo_drv[0].rd(.addr(base_addr + 8));

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
                                amo_drv[0].rd(.addr(addr));
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
                    "amo_snoop_single_collision" : begin
                        // This test is targeted towards triggering bug PROJ-150 "AMO request skips cache flush if snoop_cache_ctrl is busy" specifically
                        test_header(testname, "Single AMO request while receiving snoop");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        fork
                            begin
                                // make sure there is something dirty in the cache of core 0
                                dcache_drv[0][2].wr(.addr(base_addr));
                            end
                            begin
                                // read cache in core 1 to trigger a snoop transaction towards other cores
                                dcache_drv[1][0].rd(.addr(base_addr+1));
                            end
                        join

                        `WAIT_CYC(clk, 100)
                    end


                    //******************************************************************************
                    //*** NOTE: this test currently fails at it hits bug described in PROJ-150
                    //******************************************************************************
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached" : begin
                        test_header(testname, "Writes and reads to random cacheable addresses ");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;

                        for (int core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
                            fork
                                automatic int my_core_idx = core_idx;
                                automatic int port;
                                automatic int offset;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        if ($urandom_range(99) < 99) begin
                                            port   = $urandom_range(2);
                                            offset = $urandom_range(1024);
                                            if (port == 2) begin
                                                dcache_drv[my_core_idx][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                            end else begin
                                                dcache_drv[my_core_idx][port].rd_wait(.addr(base_addr + offset));
                                            end
                                        end else begin
                                            if ($urandom_range(1) > 0) begin
                                                amo_drv[my_core_idx].wr(.addr(base_addr+offset), .data(64'hBEEFCAFE00000000 + offset));
                                            end else begin
                                                amo_drv[my_core_idx].rd(.addr(base_addr+offset));
                                            end
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 100)
                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_shared" : begin
                        test_header(testname, "Writes and reads to random shareable addresses");

                        base_addr = ArianeCfg.SharedRegionAddrBase[0];
                        rep_cnt   = 1000;

                        for (int core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
                            fork
                                automatic int my_core_idx = core_idx;
                                automatic int port;
                                automatic int offset;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port   = $urandom_range(2);
                                        offset = $urandom_range(1024);
                                        if (port == 2) begin
                                            dcache_drv[my_core_idx][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                        end else begin
                                            dcache_drv[my_core_idx][port].rd_wait(.addr(base_addr + offset));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 100)
                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_non-shared" : begin
                        test_header(testname, "Writes and reads to random non-shareable addresses");

                        base_addr = 0;
                        rep_cnt   = 1500;

                        for (int core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
                            fork
                                automatic int my_core_idx = core_idx;
                                automatic int port;
                                automatic int offset;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port   = $urandom_range(2);
                                        offset = $urandom_range(1024);
                                        if (port == 2) begin
                                            dcache_drv[my_core_idx][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                        end else begin
                                            dcache_drv[my_core_idx][port].rd_wait(.addr(base_addr + offset));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 100)
                    end


                    //******************************************************************************
                    //*** NOTE: this test currently fails at it hits bug described in PROJ-149
                    //******************************************************************************
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_shared" : begin
                        test_header(testname, "Writes and reads to random addresses:\n  cacheable\n  shareable, non-cacheable");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;

                        for (int core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
                            fork
                                automatic int my_core_idx = core_idx;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        offset      = $urandom_range(1024);
                                        addr_region = $urandom_range(1);

                                        case (addr_region)
                                            0       : base_addr = ArianeCfg.CachedRegionAddrBase[0];
                                            default : base_addr = ArianeCfg.SharedRegionAddrBase[0];
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[my_core_idx][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                        end else begin
                                            dcache_drv[my_core_idx][port].rd_wait(.addr(base_addr + offset));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 100)
                    end


                    //******************************************************************************
                    // NOTE: this test currently fails at it hits bug described in PROJ-149
                    //******************************************************************************
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_non-shared" : begin
                        test_header(testname, "Writes and reads to random addresses:\n  cacheable\n  non-shareable, non-cacheable");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;

                        for (int core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
                            fork
                                automatic int my_core_idx = core_idx;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        offset      = $urandom_range(1024);
                                        addr_region = $urandom_range(1);

                                        case (addr_region)
                                            0       : base_addr = ArianeCfg.CachedRegionAddrBase[0];
                                            default : base_addr = 0;
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[my_core_idx][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                        end else begin
                                            dcache_drv[my_core_idx][port].rd_wait(.addr(base_addr + offset));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 1000)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_shared_non-shared" : begin
                        test_header(testname, "Writes and reads to random addresses:\n  shareable, non-cacheable\n  non-shareable, non-cacheable");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;

                        for (int core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
                            fork
                                automatic int my_core_idx = core_idx;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        offset      = $urandom_range(1024);
                                        addr_region = $urandom_range(1);

                                        case (addr_region)
                                            0       : base_addr = ArianeCfg.SharedRegionAddrBase[0];
                                            default : base_addr = 0;
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[my_core_idx][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                        end else begin
                                            dcache_drv[my_core_idx][port].rd_wait(.addr(base_addr + offset));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 100)
                    end


                    //******************************************************************************
                    // This test triggers issue described in JIRA Issue PROJ-149
                    //******************************************************************************
                    "random_all" : begin
                        test_header(testname, "Writes and reads to random addresses in all address areas");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;

                        for (int core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin
                            fork
                                automatic int my_core_idx = core_idx;
                                automatic int port;
                                automatic int offset;
                                automatic int addr_region;

                                begin
                                    for (int i=0; i<rep_cnt; i++) begin
                                        port        = $urandom_range(2);
                                        offset      = $urandom_range(1024);
                                        addr_region = $urandom_range(2);

                                        case (addr_region)
                                            0       : base_addr = ArianeCfg.CachedRegionAddrBase[0];
                                            1       : base_addr = ArianeCfg.SharedRegionAddrBase[0];
                                            default : base_addr = 0;
                                        endcase

                                        if (port == 2) begin
                                            dcache_drv[my_core_idx][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset));
                                        end else begin
                                            dcache_drv[my_core_idx][port].rd_wait(.addr(base_addr + offset));
                                        end
                                    end
                                end

                            join_none
                        end
                        wait fork;

                        `WAIT_CYC(clk, 100)
                    end


                    //******************************************************************************
                    // This test triggers issue described in JIRA Issue PROJ-149
                    //******************************************************************************
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
                    // This test triggers issue described in JIRA Issue PROJ-147
                    //******************************************************************************
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
