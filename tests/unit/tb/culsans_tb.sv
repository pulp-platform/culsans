`include "ace/assign.svh"
module culsans_tb 
  import ariane_pkg::*; 
//  import culsans_tb_pkg::*; 
#()();

    `define WAIT_CYC(CLK, N)            \
    repeat(N) @(posedge(CLK));


    `define WAIT_SIG(CLK,SIG)           \
    do begin                            \
        @(posedge(CLK));                \
    end while(SIG == 1'b0);

    // ID width of the Full AXI slave port, master port has ID `AxiIdWidthFull + 32'd1`
    parameter  int unsigned AxiIdWidth   = 32'd6;
    // Address width of the full AXI bus
    parameter  int unsigned AxiAddrWidth = 32'd64;
    // Data width of the full AXI bus
    parameter  int unsigned AxiDataWidth = 32'd64;
    localparam int unsigned AxiUserWidth = 32'd1;

    localparam CLK_PERIOD = 10ns;


    localparam ariane_cfg_t ArianeCfg = culsans_pkg::ArianeSocCfg;

    //--------------------------------------------------------------------------
    // Signals
    //--------------------------------------------------------------------------

    // TB signals

    dcache_req_i_t           [culsans_pkg::NB_CORES-1:0][2:0] dcache_req_ports_i;
    dcache_req_o_t           [culsans_pkg::NB_CORES-1:0][2:0] dcache_req_ports_o;
    ariane_ace::snoop_resp_t [culsans_pkg::NB_CORES-1:0]      snoop_port_o;
    ariane_ace::snoop_req_t  [culsans_pkg::NB_CORES-1:0]      snoop_port_i;

    logic                                                     clk;
    logic                                                     rst_n;



    //--------------------------------------------------------------------------
    // Tasks and functions
    //--------------------------------------------------------------------------


    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // get tag from address
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
    function logic [DCACHE_TAG_WIDTH-1:0] addr2tag (logic[63:0] addr);
        return addr[DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:DCACHE_INDEX_WIDTH];
    endfunction


    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // get index from address
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    function logic [DCACHE_INDEX_WIDTH-1:0] addr2index (logic[63:0] addr);
        return addr[DCACHE_INDEX_WIDTH-1:0];
    endfunction

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // read request
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    task automatic genRdReq (
        input int          core      = 0,
        input int          port      = 0,
        input logic [63:0] addr      = '0,
        input bit          rand_core = 0,
        input bit          rand_port = 0,
        input bit          rand_addr = 0
    );
        logic [63:0] addr_int;
        int          port_int;
        int          core_int;

        if (rand_core) begin
            core_int = $urandom_range(culsans_pkg::NB_CORES-1);
        end else begin
            core_int = core;
        end

        if (rand_port) begin
            port_int = $urandom_range(2);
        end else begin
            port_int = port;
        end

        if (rand_addr) begin
            addr_int = $urandom_range(32'h8000);
            if ($urandom_range(1)) begin
                addr_int = addr_int + ArianeCfg.CachedRegionAddrBase[0];
            end
        end else begin
            addr_int = addr;
        end

        `WAIT_CYC(clk, 1)
        #0.1;
        dcache_req_ports_i[core_int][port_int].data_req      = 1'b1;
        dcache_req_ports_i[core_int][port_int].data_size     = 2'b11;
        dcache_req_ports_i[core_int][port_int].address_tag   = addr2tag(addr_int);
        dcache_req_ports_i[core_int][port_int].address_index = addr2index(addr_int);

        `WAIT_SIG(clk, dcache_req_ports_o[core_int][port_int].data_gnt)
        #0.1;
        dcache_req_ports_i[core_int][port_int].data_req  = 1'b0;
        dcache_req_ports_i[core_int][port_int].tag_valid = 1'b1;

        `WAIT_CYC(clk,1)
        #0.1;
        dcache_req_ports_i[core_int][port_int] = '0;

        `WAIT_CYC(clk,1)
        #0.1;
    endtask

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // write request
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    task automatic genWrReq (
        input int          data      = 0,
        input int          core      = 0,
        input int          port      = 0,
        input logic [63:0] addr      = '0,
        input bit          rand_data = 0,
        input bit          rand_core = 0,
        input bit          rand_port = 0,
        input bit          rand_addr = 0
    );
        logic [63:0] addr_int;
        int          port_int;
        int          core_int;
        int          data_int;

        if (rand_core) begin
            core_int = $urandom_range(culsans_pkg::NB_CORES-1);
        end else begin
            core_int = core;
        end

        if (rand_port) begin
            port_int = $urandom_range(2);
        end else begin
            port_int = port;
        end

        if (rand_addr) begin
            addr_int = $urandom_range(32'h8000);
            if ($urandom_range(1)) begin
                addr_int = addr_int + ArianeCfg.CachedRegionAddrBase[0];
            end
        end else begin
            addr_int = addr;
        end

        if (rand_data) begin
            data_int = $urandom;
        end else begin
            data_int = data;
        end


        `WAIT_CYC(clk, 1)
        #0.1;
        dcache_req_ports_i[core_int][port_int].data_req      = 1'b1;
        dcache_req_ports_i[core_int][port_int].data_we       = 1'b1;
        dcache_req_ports_i[core_int][port_int].data_be       = '1;
        dcache_req_ports_i[core_int][port_int].data_size     = 2'b11;
        dcache_req_ports_i[core_int][port_int].data_wdata    = data;
        dcache_req_ports_i[core_int][port_int].address_tag   = addr2tag(addr_int);
        dcache_req_ports_i[core_int][port_int].tag_valid     = 1'b1;
        dcache_req_ports_i[core_int][port_int].address_index = addr2index(addr_int);

        `WAIT_SIG(clk, dcache_req_ports_o[core_int][port_int].data_gnt)
        #0.1;
        dcache_req_ports_i[core_int][port_int] = '0;

        `WAIT_CYC(clk,1)
        #0.1;
    endtask




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

    logic rtc;

    localparam int unsigned RTC_CLOCK_PERIOD = 30.517us;

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
    // AXI bus interfaces
    //--------------------------------------------------------------------------
    ACE_BUS #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth       ),
        .AXI_DATA_WIDTH ( AxiDataWidth       ),
        .AXI_ID_WIDTH   ( AxiIdWidth + 32'd1 ),
        .AXI_USER_WIDTH ( AxiUserWidth       )
    ) axi_bus [culsans_pkg::NB_CORES] ();
      
    // AXI bus monitor interfaces
    ACE_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth       ),
        .AXI_DATA_WIDTH ( AxiDataWidth       ),
        .AXI_ID_WIDTH   ( AxiIdWidth + 32'd1 ),
        .AXI_USER_WIDTH ( AxiUserWidth       )
    )  axi_bus_dv [culsans_pkg::NB_CORES] (clk);


    for (genvar core_idx=0; core_idx<culsans_pkg::NB_CORES; core_idx++) begin : G

        // connect signals to interface
        `ACE_ASSIGN_FROM_REQ   (axi_bus[core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o)
        `ACE_ASSIGN_FROM_RESP  (axi_bus[core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_resp_i)

        // connect interfaces
        `ACE_ASSIGN_MONITOR (axi_bus_dv[core_idx], axi_bus[core_idx])


        assign snoop_port_i[core_idx].ac        = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_resp_i.ac;
        assign snoop_port_i[core_idx].ac_valid  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_resp_i.ac_valid;
        assign snoop_port_i[core_idx].cr_ready  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_resp_i.cr_ready;
        assign snoop_port_i[core_idx].cd_ready  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_resp_i.cd_ready;
        assign snoop_port_o[core_idx].ac_ready  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o.ac_ready;
        assign snoop_port_o[core_idx].cr_valid  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o.cr_valid;
        assign snoop_port_o[core_idx].cr_resp   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o.cr_resp;
        assign snoop_port_o[core_idx].cd_valid  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o.cd_valid;
        assign snoop_port_o[core_idx].cd        = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.i_cache_subsystem.axi_req_o.cd;

        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache = dcache_req_ports_i[core_idx];
        assign dcache_req_ports_o[core_idx] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_cache_ex;

    end


    //--------------------------------------------------------------------------
    // Tests
    //--------------------------------------------------------------------------

    localparam timeout = 100000;
    int test_id = -1;

    initial begin : TESTS
        int start_idx;
        int end_idx;

        fork

            //------------------------------------------------------------------
            // Tests
            //------------------------------------------------------------------
            begin

                `WAIT_SIG(clk, rst_n)
/*
                // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                // Test 0 - 8 consecutive read misses in the same cache set
                // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                test_id = 0;
                dcache_req_ports_i  = '0;

                // write to address 0-7 and then some more
                for (int i=0; i<16; i++) begin
                    genWrReq(.core(0), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0] + (i << DCACHE_INDEX_WIDTH)), .data(i)) ;
                end

                // read miss x 8 - fill cache 0
                for (int i=0; i<8; i++) begin
                    genRdReq(.core(0), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0] + (i<<DCACHE_INDEX_WIDTH)));
                end

                `WAIT_CYC(clk, 100)
*/
                // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                // Test 1 - write conflicts
                // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                test_id = 1;
                dcache_req_ports_i  = '0;
/*
                // write to address 0-7 and then some more
                for (int i=0; i<16; i++) begin
                    genWrReq(.core(0), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0] + (i << DCACHE_INDEX_WIDTH)), .data(i)) ;
                end

                // read miss x 8 - fill cache 0 in core 0
                for (int i=0; i<8; i++) begin
                    genRdReq(.core(0), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0] + (i<<DCACHE_INDEX_WIDTH)));
                end

                // read miss x 8 - fill cache 0 in core 1
                for (int i=0; i<8; i++) begin
                    genRdReq(.core(1), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0] + (i<<DCACHE_INDEX_WIDTH)));
                end
*/
                // make sure data 0 is in cache
                genRdReq(.core(0), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0]));
                `WAIT_CYC(clk, 100)
                genRdReq(.core(1), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0]));
                `WAIT_CYC(clk, 100)

                // simultaneous writes to same address
                fork 
                    begin
                        genWrReq(.core(0), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0]), .data(16'hDEAD));
                        `WAIT_CYC(clk, 2)
                        genWrReq(.core(0), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0]), .data(16'hABBA));
                    end
                    begin
                        genWrReq(.core(1), .port(0), .addr(ArianeCfg.CachedRegionAddrBase[0]), .data(16'hBEEF));
                    end
                join


                `WAIT_CYC(clk, 100)

                //--------------------------------------------------------------
                // end of tests
                //--------------------------------------------------------------
                `WAIT_CYC(clk, 1000)
                $display("Test done");
                $finish();

            end

            //------------------------------------------------------------------
            // Timeout
            //------------------------------------------------------------------
            begin
                `WAIT_CYC(clk, timeout)
                $error("Timeout");
                $finish();
            end

        join_any
        disable fork;

    end

endmodule
