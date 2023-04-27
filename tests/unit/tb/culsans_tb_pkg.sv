interface culsans_tb_sram_if (input logic clk);
    import ariane_pkg::*;
    import std_cache_pkg::*;

    // interface for probing into sram

    typedef logic [4*DCACHE_DIRTY_WIDTH-1:0] vld_t;
    typedef logic [63:0]                     data_t;
    typedef logic [63:0]                     tag_t;
    typedef data_t                           data_sram_t [DCACHE_NUM_WORDS-1:0];
    typedef tag_t                            tag_sram_t  [DCACHE_NUM_WORDS-1:0];
    typedef vld_t                            vld_sram_t  [DCACHE_NUM_WORDS-1:0];

    data_sram_t data_sram [DCACHE_SET_ASSOC-1:0];
    tag_sram_t  tag_sram  [DCACHE_SET_ASSOC-1:0];
    vld_sram_t  vld_sram;
endinterface

interface culsans_tb_gnt_if (input logic clk);
    logic [4:0] gnt;
endinterface

package culsans_tb_pkg;
    import ariane_pkg::*;
    import snoop_test::*;
    import std_cache_pkg::*;

    // definitions for dcache request and response
    typedef enum {WR_REQ, RD_REQ, RD_RESP, WR_RESP} dcache_req_t;

    typedef enum logic [3:0] {
        READ_ONCE             = snoop_pkg::READ_ONCE,
        READ_SHARED           = snoop_pkg::READ_SHARED,
        READ_CLEAN            = snoop_pkg::READ_CLEAN,
        READ_NOT_SHARED_DIRTY = snoop_pkg::READ_NOT_SHARED_DIRTY,
        READ_UNIQUE           = snoop_pkg::READ_UNIQUE,
        CLEAN_SHARED          = snoop_pkg::CLEAN_SHARED,
        CLEAN_INVALID         = snoop_pkg::CLEAN_INVALID,
        CLEAN_UNIQUE          = snoop_pkg::CLEAN_UNIQUE,
        MAKE_INVALID          = snoop_pkg::MAKE_INVALID,
        DVM_COMPLETE          = snoop_pkg::DVM_COMPLETE,
        DVM_MESSAGE           = snoop_pkg::DVM_MESSAGE
    } acsnoop_enum;

    class dcache_req;
        dcache_req_t                   req_type;
        logic [DCACHE_INDEX_WIDTH-1:0] address_index;
        logic [DCACHE_TAG_WIDTH-1:0]   address_tag;
        riscv::xlen_t                  data;
        int                            port_idx;
        int                            prio;
        bit                            update_cache;
    endclass

    class dcache_resp;
        dcache_req_t                   req_type;
        riscv::xlen_t                  data;
    endclass

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // get address fields
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    // get tag
    function automatic logic [DCACHE_TAG_WIDTH-1:0] addr2tag (input logic[63:0] addr);
        return addr[DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:DCACHE_INDEX_WIDTH];
    endfunction

    // get index
    function automatic logic [DCACHE_INDEX_WIDTH-1:0] addr2index (input logic[63:0] addr);
        return addr[DCACHE_INDEX_WIDTH-1:0];
    endfunction

    // get mem_idx
    function automatic logic [DCACHE_INDEX_WIDTH-DCACHE_BYTE_OFFSET-1:0] addr2mem_idx (input logic[63:0] addr);
        return addr[DCACHE_INDEX_WIDTH-1:DCACHE_BYTE_OFFSET];
    endfunction

    // get addr from index and tag
    function automatic logic [63:0] tag_index2addr (
        input logic [DCACHE_TAG_WIDTH-1:0]   tag, 
        input logic [DCACHE_INDEX_WIDTH-1:0] index
    );
        return {tag, index};
    endfunction



    //--------------------------------------------------------------------------
    // Driver for the LSU / data cache interface
    //--------------------------------------------------------------------------
    class dcache_driver;

        virtual dcache_intf vif;
        string name;
        int verbosity;

        function new (virtual dcache_intf vif, string name="dcache_driver");
            this.vif = vif;
            vif.req = '0;
            vif.req.address_tag   = $urandom;
            vif.req.address_index = $urandom;
            this.name=name;
            verbosity = 0;
        endfunction

        // read request
        task rd (
            input logic [63:0] addr      = '0,
            input bit          rand_addr = 0
        );
            logic [63:0] addr_int;

            if (rand_addr) begin
                addr_int = {$urandom(),$urandom()};
            end else begin
                addr_int = addr;
            end

            if (verbosity > 0) begin
                $display("%t ns %s sending read request for address 0x%8h", $time, name, addr_int);
            end

            #0;
            vif.req.data_req      = 1'b1;
            vif.req.data_we       = 1'b0;
            vif.req.data_be       = '1;
            vif.req.data_size     = 2'b11;
            vif.req.address_index = addr2index(addr_int);

            do begin
                @(posedge vif.clk);
            end while (!vif.resp.data_gnt);

            fork
                // send tag while allowing a new read to start
                begin
                    if (verbosity > 0) begin
                        $display("%t ns %s got grant for read address 0x%8h, sending tag 0x%6h",$time, name, addr_int, addr2tag(addr_int));
                    end

                    #0;
                    vif.req.data_req    = 1'b0;
                    #0; // one more zero delay to "win" over an earlier read that sets tag_valid to 0
                    vif.req.tag_valid   = 1'b1;
                    vif.req.address_tag = addr2tag(addr_int);

                    @(posedge vif.clk);
                    #0;
                    vif.req.tag_valid = '0;
                end
                begin
                    ;
                end
            join_any
        endtask

        // write request
        task wr (
            input logic [63:0]          data      = 0,
            input logic [63:0] addr      = '0,
            input bit          rand_data = 0,
            input bit          rand_addr = 0
        );
            logic [63:0] addr_int;
            int          data_int;

            if (rand_addr) begin
                addr_int = {$urandom(),$urandom()};
            end else begin
                addr_int = addr;
            end

            if (rand_data) begin
                data_int = $urandom;
            end else begin
                data_int = data;
            end
            if (verbosity > 0) begin
                $display("%t ns %s sending write request for address 0x%8h with data 0x%8h", $time, name, addr_int, data_int);
            end

            #0;
            vif.req.data_req      = 1'b1;
            vif.req.data_we       = 1'b1;
            vif.req.data_be       = '1;
            vif.req.data_size     = 2'b11;
            vif.req.data_wdata    = data;
            vif.req.address_index = addr2index(addr_int);
            vif.req.address_tag   = addr2tag(addr_int);
            vif.req.tag_valid     = 1'b1;

            do begin
                @(posedge vif.clk);
            end while (!vif.resp.data_gnt);

            #0;
            vif.req.data_req    = 1'b0;
            vif.req.data_we     = 1'b0;
            vif.req.tag_valid   = 1'b0;

        endtask

    endclass



    //--------------------------------------------------------------------------
    // Monitor for the LSU / data cache interface
    //--------------------------------------------------------------------------
    class dcache_monitor;

        mailbox #(dcache_req)  req_mbox;
        mailbox #(dcache_resp) resp_mbox;

        virtual dcache_intf    vif;

        string                 name;
        int                    verbosity;
        int                    port_idx;

        function new (virtual dcache_intf vif, int port_idx=0, string name="dcache_monitor");
            this.vif       = vif;
            this.name      = name;
            this.port_idx  = port_idx;
            verbosity = 0;
        endfunction

        local task mon_rd_req;
            dcache_req rd_req;
            $display("%t ns %s monitoring read requests",$time, name);
            forever begin
                if (vif.req.data_req && !vif.req.data_we) begin // got read request

                    while (!vif.resp.data_gnt) begin
                        @(posedge vif.clk);
                    end
                    if (verbosity > 0) begin
                        $display("%t ns %s got request for read",$time, name);
                    end

                    rd_req = new();
                    rd_req.req_type      = RD_REQ;
                    rd_req.address_index = vif.req.address_index;
                    rd_req.port_idx      = port_idx;

                    @(posedge vif.clk);
                    while (!vif.req.tag_valid) begin
                        @(posedge vif.clk);
                    end

                    rd_req.address_tag = vif.req.address_tag;
                    if (verbosity > 0) begin
                        $display("%t ns %s got request for read tag 0x%6h, index 0x%3h",$time, name, rd_req.address_tag, rd_req.address_index);
                    end
                    req_mbox.put(rd_req);

                end else begin
                    @(posedge vif.clk);
                end
            end
        endtask

        local task mon_rd_resp;
            dcache_resp rd_resp;
            $display("%t ns %s monitoring read responses",$time, name);
            forever begin
                if (vif.resp.data_rvalid) begin // got read request
                    rd_resp = new();
                    rd_resp.req_type = RD_RESP;
                    rd_resp.data = vif.resp.data_rdata;
                    #0; // add zero delay here to make sure read response is repoerted after read request if it gets served immediately
                    if (verbosity > 0) begin
                        $display("%t ns %s got read response with data 0x%8h",$time, name, rd_resp.data);
                    end
                    resp_mbox.put(rd_resp);
                end
                @(posedge vif.clk);
            end
        endtask


        local task mon_wr_req;
            dcache_req  wr_req;
            dcache_resp wr_resp;
            $display("%t ns %s monitoring write requests",$time, name);
            forever begin
                if (vif.req.data_req && vif.req.data_we && vif.wr_gnt) begin // got write request
                    wr_req = new();
                    wr_req.req_type      = WR_REQ;
                    wr_req.address_index = vif.req.address_index;
                    wr_req.address_tag   = vif.req.address_tag;
                    wr_req.data          = vif.req.data_wdata;
                    wr_req.port_idx      = port_idx;

                    if (verbosity > 0) begin
                        $display("%t ns %s got request for write tag 0x%6h, index 0x%3h, data 0x%8h",$time, name, wr_req.address_tag, wr_req.address_index, wr_req.data);
                    end
                    req_mbox.put(wr_req);

                    while (!vif.resp.data_gnt) begin
                        @(posedge vif.clk);
                    end
                    wr_resp = new();
                    wr_resp.req_type = WR_RESP;
                    resp_mbox.put(wr_resp);
                end
                @(posedge vif.clk);
            end
        endtask

        task monitor;
            fork
                mon_rd_req();
                mon_rd_resp();
                mon_wr_req();
            join
        endtask

    endclass




    //--------------------------------------------------------------------------
    // data cache checker
    //--------------------------------------------------------------------------

    class dcache_checker #(
        parameter int unsigned AXI_ADDR_WIDTH = 0,
        parameter int unsigned AXI_DATA_WIDTH = 0,
        parameter int unsigned AXI_ID_WIDTH   = 0,
        parameter int unsigned AXI_USER_WIDTH = 0
    );

        typedef ace_test::ace_driver #(
            .AW(AXI_ADDR_WIDTH), .DW(AXI_DATA_WIDTH), .IW(AXI_ID_WIDTH), .UW(AXI_USER_WIDTH)
        ) ace_driver_t;

        typedef snoop_test::snoop_driver #(
            .AW(AXI_ADDR_WIDTH), .DW(AXI_DATA_WIDTH)
        ) snoop_driver_t;

        typedef ace_driver_t::ax_ace_beat_t   ax_ace_beat_t;
        typedef ace_driver_t::w_beat_t        w_beat_t;
        typedef ace_driver_t::b_beat_t        b_beat_t;
        typedef ace_driver_t::r_ace_beat_t    r_ace_beat_t;

        typedef snoop_driver_t::ace_ac_beat_t ace_ac_beat_t;
        typedef snoop_driver_t::ace_cd_beat_t ace_cd_beat_t;
        typedef snoop_driver_t::ace_cr_beat_t ace_cr_beat_t;

        semaphore snoop_cache_access;
        semaphore req_cache_access [2:0];

        mailbox #(dcache_req)    dcache_req_mbox_prio;
        mailbox #(dcache_req)    dcache_req_mbox_prio_tmp;
        mailbox #(dcache_req)    dcache_req_mbox  [2:0];
        mailbox #(dcache_resp)   dcache_resp_mbox [2:0];
        
        mailbox #(dcache_req)    req_to_cache_update;
        mailbox #(r_ace_beat_t)  r_beat_to_cache_update;

        mailbox #(dcache_req)    req_to_cache_check;
        mailbox #(ace_ac_beat_t) snoop_to_cache_update;



        // ACE mailboxes
        mailbox aw_mbx = new, w_mbx = new, b_mbx = new, ar_mbx = new, r_mbx = new;

        // Snoop mailboxes
        mailbox ac_mbx = new, cd_mbx = new, cr_mbx = new;

        virtual culsans_tb_sram_if sram_vif;
        virtual culsans_tb_gnt_if  gnt_vif;

        string       name;
        ariane_cfg_t ArianeCfg;

        // Cache model
        cache_line_t [DCACHE_NUM_WORDS-1:0][DCACHE_SET_ASSOC-1:0] cache_status;
        logic                              [DCACHE_SET_ASSOC-1:0] lfsr;
        logic                      [$clog2(DCACHE_SET_ASSOC)-1:0] target_way;

        function new (
            virtual culsans_tb_sram_if sram_vif,
            virtual culsans_tb_gnt_if  gnt_vif,
            ariane_cfg_t               cfg,
            string                     name="dcache_checker"
        );
            this.sram_vif             = sram_vif;
            this.gnt_vif              = gnt_vif;
            this.name                 = name;
            this.ArianeCfg            = cfg;

            this.dcache_req_mbox_prio = new();
            this.dcache_req_mbox_prio_tmp = new();

            cache_status              = '0;
            lfsr                      = '0;
            target_way                = '0;

            req_to_cache_update = new();
            r_beat_to_cache_update = new();
            req_to_cache_check = new();
            snoop_to_cache_update = new();

            snoop_cache_access = new(1);
            for (int i=0; i<=2; i++) begin
                req_cache_access[i] = new(1);
            end
        endfunction



        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // cache check functions
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        function automatic bit isHit (input logic [63:0] addr);
            for (int i = 0; i < DCACHE_SET_ASSOC; i++) begin
                if (cache_status[addr2mem_idx(addr)][i].valid && cache_status[addr2mem_idx(addr)][i].tag == addr2tag(addr))
                    return 1'b1;
            end
            return 1'b0;
        endfunction

        function automatic bit isDirty (input logic [63:0] addr);
            for (int i = 0; i < DCACHE_SET_ASSOC; i++) begin
                if (cache_status[addr2mem_idx(addr)][i].dirty && cache_status[addr2mem_idx(addr)][i].valid && cache_status[addr2mem_idx(addr)][i].tag == addr2tag(addr))
                    return 1'b1;
            end
            return 1'b0;
        endfunction

        function automatic bit isShared (input logic [63:0] addr);
            for (int i = 0; i < DCACHE_SET_ASSOC; i++) begin
                if (cache_status[addr2mem_idx(addr)][i].shared && cache_status[addr2mem_idx(addr)][i].valid && cache_status[addr2mem_idx(addr)][i].tag == addr2tag(addr))
                    return 1'b1;
            end
            return 1'b0;
        endfunction

        function automatic int getHitWay (input logic [63:0] addr);
            for (int i = 0; i < DCACHE_SET_ASSOC; i++) begin
                if (cache_status[addr2mem_idx(addr)][i].valid && cache_status[addr2mem_idx(addr)][i].tag == addr2tag(addr))
                    return i;
            end
            $error("No hit way found");
            return -1;
        endfunction

        function automatic bit isCleanUnique (input ax_ace_beat_t ar);
            if (ar.ax_snoop == 4'b1011 && ar.ax_bar[0] == 1'b0 && (ar.ax_domain == 2'b10 || ar.ax_domain == 2'b01))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit isReadShared (input ax_ace_beat_t ar);
            if (ar.ax_snoop == 4'b0001 && ar.ax_bar[0] == 1'b0 && (ar.ax_domain == 2'b01 || ar.ax_domain == 2'b10))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit isReadOnce (input ax_ace_beat_t ar);
            if (ar.ax_snoop == 4'b0000 && ar.ax_bar[0] == 1'b0 && (ar.ax_domain == 2'b01 || ar.ax_domain == 2'b10))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit isReadUnique (input ax_ace_beat_t ar);
            if (ar.ax_snoop == 4'b0111 && ar.ax_bar[0] == 1'b0 && (ar.ax_domain == 2'b01 || ar.ax_domain == 2'b10))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit isReadNoSnoop (input ax_ace_beat_t ar);
            if (ar.ax_snoop == 4'b0000 && ar.ax_bar[0] == 1'b0 && (ar.ax_domain == 2'b00 || ar.ax_domain == 2'b11))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit isWriteBack (input ax_ace_beat_t aw);
            if (aw.ax_snoop == 3'b011 && aw.ax_bar[0] == 1'b0 && (aw.ax_domain == 2'b00 || aw.ax_domain == 2'b01 || aw.ax_domain == 2'b10))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit isWriteUnique ( input ax_ace_beat_t aw );
            if (aw.ax_snoop == 3'b000 && aw.ax_bar[0] == 1'b0 && (aw.ax_domain == 2'b01 || aw.ax_domain == 2'b10))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit isWriteNoSnoop( input ax_ace_beat_t aw );
            if (aw.ax_snoop == 3'b000 && aw.ax_bar[0] == 1'b0 && (aw.ax_domain == 2'b00 || aw.ax_domain == 2'b11))
                return 1'b1;
            else
                return 1'b0;
        endfunction

        function automatic bit mustEvict (input logic [63:0] addr);
            logic valid = 1'b1;
            for (int i = 0; i < DCACHE_SET_ASSOC; i++) begin
                valid = valid & cache_status[addr2mem_idx(addr)][i].valid;
            end
            if (!isHit(addr) && valid == 1'b1 && cache_status[addr2mem_idx(addr)][lfsr[$clog2(DCACHE_SET_ASSOC)-1:0]].dirty == 1'b1)
                return 1'b1;
            else
                return 1'b0;
        endfunction

        // Helper functions
        function automatic logic[7:0] nextLfsr (input logic[7:0] n);
            logic tmp;
            tmp = !(n[7] ^ n[3] ^ n[2] ^ n[1]);
            return {n[6:0], tmp};
        endfunction

        // Check cache contents against real memory
        function automatic bit checkCache (
            input logic [63:0] addr,
            input string       origin = ""
        );
            logic [DCACHE_INDEX_WIDTH-DCACHE_BYTE_OFFSET-1:0] mem_idx_v;
            logic [DCACHE_INDEX_WIDTH-1:0]                    idx_v;
            logic [DCACHE_TAG_WIDTH-1:0]                      tag_v;
            bit                                               OK;

            OK        = 1'b1;
            mem_idx_v = addr2mem_idx(addr);
            idx_v     = addr2index(addr);
            tag_v     = addr2tag(addr);

            // check the target_way
            if (cache_status[mem_idx_v][target_way].dirty != sram_vif.vld_sram[mem_idx_v][8*target_way]) begin
                OK = 1'b0;
                $error("%s: Cache mismatch index %h tag %h way %h - dirty bit: expected %d, actual %d", {name,".",origin}, idx_v, tag_v, target_way, cache_status[mem_idx_v][target_way].dirty, sram_vif.vld_sram[mem_idx_v][8*target_way]);
            end
            if (cache_status[mem_idx_v][target_way].valid != sram_vif.vld_sram[mem_idx_v][8*target_way+1]) begin
                OK = 1'b0;
                $error("%s: Cache mismatch index %h tag %h way %h - valid bit: expected %d, actual %d", {name,".",origin}, idx_v, tag_v, target_way, cache_status[mem_idx_v][target_way].valid, sram_vif.vld_sram[mem_idx_v][8*target_way+1]);
            end
            if (cache_status[mem_idx_v][target_way].shared != sram_vif.vld_sram[mem_idx_v][8*target_way+2]) begin
                OK = 1'b0;
                $error("%s: Cache mismatch index %h tag %h way %h - shared bit: expected %d, actual %d", {name,".",origin}, idx_v, tag_v, target_way, cache_status[mem_idx_v][target_way].shared, sram_vif.vld_sram[mem_idx_v][8*target_way+2]);
            end

            // check tags
            for (int w=0;w<DCACHE_SET_ASSOC; w++) begin
                if (cache_status[mem_idx_v][w].tag != sram_vif.tag_sram[w][mem_idx_v][47:0]) begin
                    OK = 1'b0;
                    $error("%s: Cache mismatch index %h tag %h way %0h - tag: expected %h, actual %h", {name,".",origin}, idx_v, tag_v, w, cache_status[mem_idx_v][w].tag, sram_vif.tag_sram[w][mem_idx_v][47:0]);
                end
            end
            return OK;
        endfunction


        // Get expected CR response from current cache contents
        function automatic ace_cr_beat_t GetCRResp (
            input ace_ac_beat_t req
        );
            ace_cr_beat_t resp;
            resp         = new();
            resp.cr_resp = '0;

            if (req.ac_snoop != snoop_pkg::CLEAN_INVALID &&
                req.ac_snoop != snoop_pkg::READ_ONCE &&
                req.ac_snoop != snoop_pkg::READ_UNIQUE &&
                req.ac_snoop != snoop_pkg::READ_SHARED) begin
                resp.cr_resp.error = 1'b1;
            end

            // if (isDirty(req.ac_addr) && req.ac_snoop != snoop_pkg::CLEAN_INVALID) begin
            if (isDirty(req.ac_addr) && req.ac_snoop == snoop_pkg::READ_UNIQUE) begin
                resp.cr_resp.passDirty = 1'b1;
            end

            if (isHit(req.ac_addr) && req.ac_snoop != snoop_pkg::CLEAN_INVALID) begin
                resp.cr_resp.dataTransfer = 1'b1;
            end
            return resp;

        endfunction


        // Check CR response
        function automatic bit checkCRResp (
            input ace_ac_beat_t req,
            input ace_cr_beat_t exp,
            input ace_cr_beat_t resp
        );
            acsnoop_enum e;
            bit OK;
            e = acsnoop_enum'(req.ac_snoop);
            OK = 1'b1;

            if (exp.cr_resp.error && !resp.cr_resp.error) begin
                $error("CR.resp.error expected for snoop request %s", e.name());
                OK = 1'b0;
            end

            if (isShared(req.ac_addr) != resp.cr_resp.isShared && resp.cr_resp.error == 1'b0 && req.ac_snoop != snoop_pkg::CLEAN_INVALID) begin
                $error("%s: CR.resp.isShared mismatch: expected %h, actual %h", name, isShared(req.ac_addr), resp.cr_resp.isShared);
                OK = 1'b0;
            end

            if(exp.cr_resp.passDirty != resp.cr_resp.passDirty && resp.cr_resp.error == 1'b0) begin
                $error("%s: CR.resp.passDirty mismatch: expected %h, actual %h", name, exp.cr_resp.passDirty, resp.cr_resp.passDirty);
                OK = 1'b0;
            end

            if(exp.cr_resp.dataTransfer != resp.cr_resp.dataTransfer && resp.cr_resp.error == 1'b0) begin
                $error("%s: CR.resp.dataTransfer mismatch: expected %h, actual %h", name, resp.cr_resp.dataTransfer, resp.cr_resp.dataTransfer);
                OK = 1'b0;
            end

        endfunction


        // update cache model contents when receiving snoop
        local task update_cache_from_snoop ();
            // helper variables
            logic [DCACHE_SET_ASSOC-1:0]                      valid_v;
            logic [DCACHE_INDEX_WIDTH-DCACHE_BYTE_OFFSET-1:0] mem_idx_v;
            logic                                             hit_v;
            bit                                               CheckOK;
            ace_ac_beat_t ac;

            forever begin
                snoop_to_cache_update.get(ac);

                // actual cache update takes 3 more cycles with grant                
                repeat (3) begin
                    while (!gnt_vif.gnt[1]) begin
                        $display("%t ns skipping cycle without grant for snoop",$time);
                        @(posedge sram_vif.clk); // skip cycles without grant
                    end
                    @(posedge sram_vif.clk);
                end

//                snoop_cache_access.get();

                $display("%t ns %s updating cache status from snoop",$time, name);

                mem_idx_v = addr2mem_idx(ac.ac_addr);
                for (int i=0; i<DCACHE_SET_ASSOC; i++) begin
                    valid_v[i] = cache_status[mem_idx_v][i].valid;
                end
                hit_v = 1'b0;

                // look for the right tag
                for (int i = 0; i < DCACHE_SET_ASSOC; i++) begin
                    if (valid_v[i] && cache_status[mem_idx_v][i].tag == addr2tag(ac.ac_addr)) begin
                        case (ac.ac_snoop)
                            snoop_pkg::READ_SHARED: begin
                                $display("Update mem [%0d][%0d] from READ_SHARED", mem_idx_v, i);
                                cache_status[mem_idx_v][i].shared = 1'b1;
                            end
                            snoop_pkg::READ_UNIQUE: begin
                                $display("Update mem [%0d][%0d] from READ_UNIQUE", mem_idx_v, i);
                                cache_status[mem_idx_v][i].shared = 1'b0;
                                cache_status[mem_idx_v][i].valid = 1'b0;
                                cache_status[mem_idx_v][i].dirty = 1'b0;
                            end
                            snoop_pkg::CLEAN_INVALID: begin
                                $display("Update mem [%0d][%0d] from CLEAN_INVALID", mem_idx_v, i);
                                cache_status[mem_idx_v][i].shared = 1'b0;
                                cache_status[mem_idx_v][i].valid = 1'b0;
                                cache_status[mem_idx_v][i].dirty = 1'b0;
                            end
                        endcase

                        $display("Updated cache_status[%0d][%0d]: valid : %0d, dirty : %0d, shared : %0d, tag : 0x%6h", mem_idx_v, i,
                            cache_status[mem_idx_v][i].valid,
                            cache_status[mem_idx_v][i].dirty,
                            cache_status[mem_idx_v][i].shared,
                            cache_status[mem_idx_v][i].tag
                        );
                        hit_v = 1'b1;


                        break;
                    end
                end
                if (!hit_v)
                    $display("No hit for addr %8h", ac.ac_addr);

                CheckOK = checkCache(ac.ac_addr,"update_cache_from_snoop");

//                @(posedge sram_vif.clk);
//                snoop_cache_access.put();

            end
        endtask


        local task automatic update_cache_from_req ();

            // helper variables
            logic [DCACHE_SET_ASSOC-1:0]                      valid_v;
            logic [DCACHE_INDEX_WIDTH-DCACHE_BYTE_OFFSET-1:0] mem_idx_v;
            logic [63:0]                                      addr_v;
            bit                                               CheckOK;
            dcache_req   req;
            r_ace_beat_t r_beat;
            bit cache_access_required;

            forever begin

                req_to_cache_update.get(req);
                r_beat_to_cache_update.get(r_beat);

                fork 
                    begin

                        // actual cache update takes 2 more cycles with grant                
//                        repeat (2) begin
//                            @(posedge sram_vif.clk);
//                        end


                        // actual cache update takes 2 more cycles
//                        @(posedge sram_vif.clk);

                        // check that cache access is granted if needed
                        if (req.update_cache) begin
                            while (!gnt_vif.gnt[req.prio]) begin
                                $display("%t ns %s skipping cycle without grant for dcache req from port %0d with prio %0d",$time,name,req.port_idx, req.prio);
                                @(posedge sram_vif.clk); // skip cycles without grant
                            end
                        end
                        @(posedge sram_vif.clk);
                        @(posedge sram_vif.clk);

//                        cache_access_required = !isHit(addr_v) || (req.req_type == WR_REQ);
//                        if (cache_access_required) begin
//                            // request access to cache
//                            for (int i = 2; i >= 0; i--) begin
//                                if (req.port_idx >= i) begin
//                                    req_cache_access[i].get();
//                                    #0;
//                                end
//                            end
//                            snoop_cache_access.get();
//                        end


                        $display("%t ns %s updating cache status from dcache req of type %0s to tag 0x%6h, index 0x%3h from port %0d",$time, name, req.req_type.name(), req.address_tag, req.address_index, req.port_idx);

                        addr_v    = tag_index2addr(.tag(req.address_tag), .index(req.address_index));
                        mem_idx_v = addr2mem_idx(addr_v);
                        for (int i=0; i<DCACHE_SET_ASSOC; i++) begin
                            valid_v[i] = cache_status[mem_idx_v][i].valid;
                        end

                        if (!isHit(addr_v)) begin
                            // cache miss
                            $display("Cache miss");
                            if (&valid_v) begin
                                $display("No empty way");
                                // all ways occupied
                                target_way = lfsr[$clog2(DCACHE_SET_ASSOC)-1:0];
                                cache_status[mem_idx_v][target_way].tag = req.address_tag;
                                if (req.req_type == WR_REQ) begin
                                    cache_status[mem_idx_v][target_way].dirty = 1'b1;
                                    cache_status[mem_idx_v][target_way].shared = 1'b0;
                                end else begin
                                    cache_status[mem_idx_v][target_way].dirty  = r_beat.r_resp[2];
                                    cache_status[mem_idx_v][target_way].shared = r_beat.r_resp[3];
                                end
                                lfsr = nextLfsr(lfsr);
                            end else begin
                                $display("Empty way found");
                                // there is an empty way
                                target_way = one_hot_to_bin(get_victim_cl(~valid_v));
                                cache_status[mem_idx_v][target_way].tag = req.address_tag;
                                cache_status[mem_idx_v][target_way].valid = 1'b1;
                                if (req.req_type == WR_REQ) begin
                                    cache_status[mem_idx_v][target_way].dirty = 1'b1;
                                    cache_status[mem_idx_v][target_way].shared = 1'b0;
                                end else begin
                                    cache_status[mem_idx_v][target_way].dirty  = r_beat.r_resp[2];
                                    cache_status[mem_idx_v][target_way].shared = r_beat.r_resp[3];
                                end
                            end
                        end else begin
                            $display("Cache hit");
                            // cache hit
                            target_way = getHitWay(addr_v);
                            if (req.req_type == WR_REQ) begin
                                cache_status[mem_idx_v][target_way].dirty = 1'b1;
                                cache_status[mem_idx_v][target_way].shared = 1'b0;
                            end
                        end
                        $display("Updated cache_status[%0d][%0d]: valid : %0d, dirty : %0d, shared : %0d, tag : 0x%6h", mem_idx_v, target_way,
                            cache_status[mem_idx_v][target_way].valid,
                            cache_status[mem_idx_v][target_way].dirty,
                            cache_status[mem_idx_v][target_way].shared,
                            cache_status[mem_idx_v][target_way].tag
                        );


                        CheckOK = checkCache(addr_v, "update_cache_from_req");

                        // return cache access
//                        @(posedge sram_vif.clk);
//                        if (cache_access_required) begin
//                            snoop_cache_access.put();
//                            for (int i = 0; i <= 2; i++) begin
//                                if (req.port_idx >= i) begin
//                                    req_cache_access[i].put();
//                                end
//                            end
//                        end


                    end
                join_none

            end
        endtask

                    // check behaviour when receiving snoop requests
        local task check_snoop;
            ace_cd_beat_t cd;
            ace_ac_beat_t ac;
            ace_cr_beat_t cr, cr_exp;
            ax_ace_beat_t aw_beat;
            b_beat_t      b_beat;
            bit           CheckOK;

            forever begin
                acsnoop_enum e;

                // wait for snoop request
                ac_mbx.get(ac);
                e = acsnoop_enum'(ac.ac_snoop);
                $display("%t ns %s got snoop request %0s",$time, name, e.name());

                cr_exp = GetCRResp(ac);
                $display("%t ns %s got expected response PassDirty : %1b, DataTransfer : %1b, Error : %1b",$time, name, cr_exp.cr_resp.passDirty, cr_exp.cr_resp.dataTransfer, cr_exp.cr_resp.error);

                if (is_inside_cacheable_regions(ArianeCfg, ac.ac_addr)) begin
                    snoop_to_cache_update.put(ac);
                end

                fork
                    begin


                        fork // TODO: is fork really necessary?

                            begin
                                // expect a writeback on CLEAN_INVALID
                                if (isHit(ac.ac_addr) && isDirty(ac.ac_addr) && ac.ac_snoop == snoop_pkg::CLEAN_INVALID) begin
                                    // writebacks use the bypass port
                                    repeat(2) begin
                                        aw_mbx.get(aw_beat);
                                        if (!isWriteBack(aw_beat))
                                            $error("%s : WRITEBACK request expected after CLEAN_INVALID",name);
                                        b_mbx.get(b_beat);
                                    end
                                end
                            end

                            begin
                                // wait for the response
                                cr_mbx.get(cr);
                                $display("%t ns %s got snoop response 0b%5b (WasUnique : %1b, isShared : %1b, PassDirty : %1b, Error : %1b, DataTransfer : %1b)",$time, name, cr.cr_resp, cr.cr_resp[4],cr.cr_resp[3],cr.cr_resp[2],cr.cr_resp[1],cr.cr_resp[0]);



                                checkCRResp(.req(ac), .exp(cr_exp), .resp(cr));

                                // expect the data
                                if (isHit(ac.ac_addr) && (ac.ac_snoop == snoop_pkg::READ_UNIQUE ||
                                        ac.ac_snoop == snoop_pkg::READ_ONCE   ||
                                        ac.ac_snoop == snoop_pkg::READ_SHARED)
                                ) begin
                                    cd = new();
                                    cd.cd_last = 1'b0;
                                    while (!cd.cd_last) begin
                                        cd_mbx.get(cd);
                                        $display("%t ns %s got snoop data 0x%64h, last = %0d",$time, name, cd.cd_data,cd.cd_last);
                                    end
                                end
                            end

                        join

//                        CheckOK = checkCache(ac.ac_addr);

                    end

                    // timeout
                    begin
                        repeat (100) @(posedge sram_vif.clk);
                        $error("%s : Timeout in check_snoop", name);
                    end
                join_any
                disable fork;

            end // forever
        endtask


        // get cache requests in prio order
        local task get_cache_msg;
            $display("%t ns %s retreiving dcache messages",$time, name);
            forever begin
                for (int i=0; i<=2; i++) begin
                    dcache_req msg;
                    if (dcache_req_mbox[i].try_get(msg)) begin
                        dcache_req_mbox_prio_tmp.put(msg);                                               
                    end
                end
                @(posedge sram_vif.clk);
            end
        endtask

        local task get_cache_msg_tmp;
            dcache_req msg;
            forever begin
                dcache_req_mbox_prio_tmp.get(msg);                                               
                dcache_req_mbox_prio.put(msg);                                               
                fork
                    begin
                        check_cache_msg();                        
                    end
                    begin
                        @(posedge sram_vif.clk);
                    end
                join_any
            end
        endtask



/*
        local task check_cache_from_req();
            bit CheckOK;
            dcache_req  req;
            dcache_resp  rsp;
            logic [63:0]  addr_v;
            forever begin
                req_to_cache_check.get(req);
                addr_v = tag_index2addr(.tag(req.address_tag), .index(req.address_index));

                dcache_resp_mbox[req.port_idx].get(rsp);
                // allow one cycle delay for cache to be updated
                repeat(3)
                    @(posedge sram_vif.clk);
                CheckOK = checkCache(addr_v);
            end
        endtask
*/

        // check behaviour when receiving dcache requests
        local task automatic check_cache_msg;
            dcache_req    msg;
            dcache_resp   rsp;
            logic [63:0]  addr_v;
            ax_ace_beat_t aw_beat;
            ax_ace_beat_t ar_beat;
            b_beat_t      b_beat;
            r_ace_beat_t  r_beat;
            bit           CheckOK;

            msg = new();
            dcache_req_mbox_prio.get(msg);

            // default
            msg.prio         = msg.port_idx + 2;
            msg.update_cache = 1'b0;

            // add 1 cycle delay after dcache messages to have same delay as AXI / ACE monitors
            @(posedge sram_vif.clk);

            $display("%t ns %s got dcache message of type %0s to tag 0x%6h, index 0x%3h from port %0d",$time, name, msg.req_type.name(), msg.address_tag, msg.address_index, msg.port_idx);
            addr_v = tag_index2addr(.tag(msg.address_tag), .index(msg.address_index));

            fork
                begin
                    // bypass
                    if (!is_inside_cacheable_regions(ArianeCfg, addr_v)) begin
                        if (msg.req_type == WR_REQ) begin
                            aw_mbx.get(aw_beat);
                            if (is_inside_shareable_regions(ArianeCfg, addr_v)) begin
                                if (!isWriteUnique(aw_beat))
                                    $error("%s : WRITE_UNIQUE request expected",name);
                            end else begin
                                if (!isWriteNoSnoop(aw_beat))
                                    $error("%s : WRITE_NO_SNOOP request expected",name);
                            end
                            b_mbx.get(b_beat);
                        end else begin
                            ar_mbx.get(ar_beat);
                            if (is_inside_shareable_regions(ArianeCfg, addr_v)) begin
                                if (!isReadOnce(ar_beat))
                                    $error("%s : READ_ONCE request expected",name);
                            end else begin
                                if (!isReadNoSnoop(ar_beat))
                                    $error("%s : READ_NO_SNOOP request expected",name);
                            end
                            r_beat = new();
                            while (!r_beat.r_last)
                                r_mbx.get(r_beat);
                        end
                    end
                    // cacheable
                    else begin

                        // Cache hit
                        if (isHit(addr_v)) begin
                            if (msg.req_type == WR_REQ) begin
                                msg.update_cache = 1'b1;

                                if (isShared(addr_v)) begin
                                    ar_mbx.get(ar_beat);
                                    if (!isCleanUnique(ar_beat))
                                        $error("%s Error CLEAN_UNIQUE expected", name);

                                    // await response
                                    r_beat = new();
                                    while (!r_beat.r_last)
                                        r_mbx.get(r_beat);

                                end
                            end else begin
                                // otherwise wait only for the response from the port
                                // TODO: how to check this?
                                //  `WAIT_SIG(clk_i, axi_req_o.ar_valid)
                                //  $error("AR_VALID error, expected 0");
                            end
                        end

                        // Cache miss (check again even if it was just hit, could have been changed during CLEAN_UNIQUE)
                        if (!isHit(addr_v)) begin
                            msg.prio         = 0; // miss has highest prio
                            msg.update_cache = 1'b1;
                            // check if eviction is necessary
                            if (mustEvict(addr_v)) begin
                                aw_mbx.get(aw_beat);
                                if (!isWriteBack(aw_beat))
                                    $error("%s : WRITEBACK request expected after eviction",name);
                            end

                            fork
                                begin
                                    ar_mbx.get(ar_beat);
                                    if (msg.req_type == WR_REQ) begin
                                        if (!isReadUnique(ar_beat))
                                            $error("%s : READ_UNIQUE request expected",name);
                                    end else begin
                                        if (!isReadShared(ar_beat))
                                            $error("%s : READ_SHARED request expected",name);
                                    end

                                    r_beat = new();
                                    while (!r_beat.r_last)
                                        r_mbx.get(r_beat);
                                end
                                begin
                                    // check if hit status changes, could be result of miss handler writeback
                                    // in that case stop waiting for an AR beat
                                    while (!isHit(addr_v)) begin
                                        @(posedge sram_vif.clk);
                                    end

                                    // status changed to hit, revert changes in priority
                                    msg.prio = msg.port_idx + 2;
                                    if (msg.req_type == WR_REQ) begin
                                        msg.update_cache = 1'b1;
                                    end else begin
                                        msg.update_cache = 1'b0;
                                    end

                                    $display("%t ns %s Cache status changed from miss to hit, abort waiting for AR", $time, name);
                                end
                            join_any
                            disable fork;

                        end
                    end

                    if (is_inside_cacheable_regions(ArianeCfg, addr_v)) begin
                        // send to cache update
                        req_to_cache_update.put(msg);
                        r_beat_to_cache_update.put(r_beat);

                        // send to cache check
//                        req_to_cache_check.put(msg);
                    end

                end

                // timeout
                begin
                    repeat (100) @(posedge sram_vif.clk);
                        $error("%s : Timeout in check_cache_msg", name);
                end

            join_any
            disable fork;

        endtask


/*
        // check behaviour when receiving dcache requests
        local task check_cache_msg;
            dcache_req    msg;
            dcache_resp   rsp;
            logic [63:0]  addr_v;
            ax_ace_beat_t aw_beat;
            ax_ace_beat_t ar_beat;
            b_beat_t      b_beat;
            r_ace_beat_t  r_beat;
            bit           CheckOK;

            forever begin
                msg = new();
                dcache_req_mbox_prio.get(msg);

                // add 1 cycle delay after dcache messages to have same delay as AXI / ACE monitors
                @(posedge sram_vif.clk);

                $display("%t ns %s got dcache message of type %0s to tag 0x%6h, index 0x%3h from port %0d",$time, name, msg.req_type.name(), msg.address_tag, msg.address_index, msg.port_idx);
                addr_v = tag_index2addr(.tag(msg.address_tag), .index(msg.address_index));

                fork
                    begin
                        // bypass
                        if (!is_inside_cacheable_regions(ArianeCfg, addr_v)) begin
                            if (msg.req_type == WR_REQ) begin
                                aw_mbx.get(aw_beat);
                                if (is_inside_shareable_regions(ArianeCfg, addr_v)) begin
                                    if (!isWriteUnique(aw_beat))
                                        $error("%s : WRITE_UNIQUE request expected",name);
                                end else begin
                                    if (!isWriteNoSnoop(aw_beat))
                                        $error("%s : WRITE_NO_SNOOP request expected",name);
                                end
                                b_mbx.get(b_beat);
                            end else begin
                                ar_mbx.get(ar_beat);
                                if (is_inside_shareable_regions(ArianeCfg, addr_v)) begin
                                    if (!isReadOnce(ar_beat))
                                        $error("%s : READ_ONCE request expected",name);
                                end else begin
                                    if (!isReadNoSnoop(ar_beat))
                                        $error("%s : READ_NO_SNOOP request expected",name);
                                end
                                r_beat = new();
                                while (!r_beat.r_last)
                                    r_mbx.get(r_beat);
                            end
                        end
                        // cacheable
                        else begin

                            // Cache hit
                            if (isHit(addr_v)) begin
                                if (msg.req_type == WR_REQ) begin

                                    if (isShared(addr_v)) begin
                                        ar_mbx.get(ar_beat);
                                        if (!isCleanUnique(ar_beat))
                                            $error("%s Error CLEAN_UNIQUE expected", name);

                                        // await response
                                        r_beat = new();
                                        while (!r_beat.r_last)
                                            r_mbx.get(r_beat);

                                    end
                                end else begin
                                    // otherwise wait only for the response from the port
                                    // TODO: how to check this?
                                    //  `WAIT_SIG(clk_i, axi_req_o.ar_valid)
                                    //  $error("AR_VALID error, expected 0");
                                end
                            end

                            // Cache miss (check again even if it was just hit, could have been changed during CLEAN_UNIQUE)
                            if (!isHit(addr_v)) begin
                                // check if eviction is necessary
                                if (mustEvict(addr_v)) begin
                                    aw_mbx.get(aw_beat);
                                    if (!isWriteBack(aw_beat))
                                        $error("%s : WRITEBACK request expected after eviction",name);
                                end

                                fork
                                    begin
                                        ar_mbx.get(ar_beat);
                                        if (msg.req_type == WR_REQ) begin
                                            if (!isReadUnique(ar_beat))
                                                $error("%s : READ_UNIQUE request expected",name);
                                        end else begin
                                            if (!isReadShared(ar_beat))
                                                $error("%s : READ_SHARED request expected",name);
                                        end

                                        r_beat = new();
                                        while (!r_beat.r_last)
                                            r_mbx.get(r_beat);
                                    end
                                    begin
                                        // check if hit status changes, could be result of miss handler writeback
                                        // in that case stop waiting for an AR beat
                                        while (!isHit(addr_v)) begin
                                            @(posedge sram_vif.clk);
                                        end
                                        $display("%t ns %s Cache status changed from miss to hit, abort waiting for AR", $time, name);
                                    end
                                join_any
                                disable fork;

                            end
                        end

                        if (is_inside_cacheable_regions(ArianeCfg, addr_v)) begin
                            // send to cache update
                            req_to_cache_update.put(msg);
                            r_beat_to_cache_update.put(r_beat);

                            // send to cache check
                            req_to_cache_check.put(msg);
                        end

                    end

                    // timeout
                    begin
                        repeat (100) @(posedge sram_vif.clk);
                        $error("%s : Timeout in check_cache_msg", name);
                    end
        
                join_any
                disable fork;

            end // forever

        endtask
*/
        task run;
            fork
                get_cache_msg();
                get_cache_msg_tmp();
//                check_cache_msg();
                check_snoop();
                update_cache_from_req();
//                check_cache_from_req();
                update_cache_from_snoop();
            join
        endtask

    endclass

endpackage