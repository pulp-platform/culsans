// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: Test-harness for Ariane
//              Instantiates an AXI-Bus and memories

`include "axi/assign.svh"
`include "ace/assign.svh"

module culsans_top #(
  parameter int unsigned AXI_USER_WIDTH    = ariane_pkg::AXI_USER_WIDTH,
  parameter int unsigned AXI_USER_EN       = ariane_pkg::AXI_USER_EN,
  parameter int unsigned AXI_ADDRESS_WIDTH = 64,
  parameter int unsigned AXI_DATA_WIDTH    = 64,
`ifdef DROMAJO
  parameter bit          InclSimDTM        = 1'b0,
`else
  parameter bit          InclSimDTM        = 1'b0,
`endif
  parameter int unsigned NUM_WORDS         = 2**25,         // memory size
  parameter bit          StallRandomOutput = 1'b0,
  parameter bit          StallRandomInput  = 1'b0,
  parameter BootAddress = 64'h8010_0000 //culsans_pkg::ROMBase
) (
  input  logic                           clk_i,
  input  logic                           rtc_i,
  input  logic                           rst_ni,
  output logic [31:0]                    exit_o
);

  // disable test-enable
  logic        test_en;
  logic        ndmreset;
  logic        ndmreset_n;
  logic        debug_req_core;

  int          jtag_enable;
  logic        init_done;
  logic [31:0] jtag_exit, dmi_exit;

  logic        jtag_TCK;
  logic        jtag_TMS;
  logic        jtag_TDI;
  logic        jtag_TRSTn;
  logic        jtag_TDO_data;
  logic        jtag_TDO_driven;

  logic        debug_req_valid;
  logic        debug_req_ready;
  logic        debug_resp_valid;
  logic        debug_resp_ready;

  logic        jtag_req_valid;
  logic [6:0]  jtag_req_bits_addr;
  logic [1:0]  jtag_req_bits_op;
  logic [31:0] jtag_req_bits_data;
  logic        jtag_resp_ready;
  logic        jtag_resp_valid;

  logic        dmi_req_valid;
  logic        dmi_resp_ready;
  logic        dmi_resp_valid;

  dm::dmi_req_t  jtag_dmi_req;
  dm::dmi_req_t  dmi_req;

  dm::dmi_req_t  debug_req;
  dm::dmi_resp_t debug_resp;

  assign test_en = 1'b0;

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthToXbar ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) to_xbar[1:0]();

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) master[culsans_pkg::NB_PERIPHERALS-1:0]();

  rstgen i_rstgen_main (
    .clk_i        ( clk_i                ),
    .rst_ni       ( rst_ni & (~ndmreset) ),
    .test_mode_i  ( test_en              ),
    .rst_no       ( ndmreset_n           ),
    .init_no      (                      ) // keep open
  );

  // ---------------
  // Debug
  // ---------------
  assign init_done = rst_ni;

  logic debug_enable;
  initial begin
    if (!$value$plusargs("jtag_rbb_enable=%b", jtag_enable)) jtag_enable = 'h0;
    if ($test$plusargs("debug_disable")) debug_enable = 'h0; else debug_enable = 'h1;
    if (riscv::XLEN != 32 & riscv::XLEN != 64) $error("XLEN different from 32 and 64");
  end

  // debug if MUX
  assign debug_req_valid     = (jtag_enable[0]) ? jtag_req_valid     : dmi_req_valid;
  assign debug_resp_ready    = (jtag_enable[0]) ? jtag_resp_ready    : dmi_resp_ready;
  assign debug_req           = (jtag_enable[0]) ? jtag_dmi_req       : dmi_req;
//  assign exit_o              = (jtag_enable[0]) ? jtag_exit          : dmi_exit;
  assign jtag_resp_valid     = (jtag_enable[0]) ? debug_resp_valid   : 1'b0;
  assign dmi_resp_valid      = (jtag_enable[0]) ? 1'b0               : debug_resp_valid;
/*
  // SiFive's SimJTAG Module
  // Converts to DPI calls
  SimJTAG i_SimJTAG (
    .clock                ( clk_i                ),
    .reset                ( ~rst_ni              ),
    .enable               ( jtag_enable[0]       ),
    .init_done            ( init_done            ),
    .jtag_TCK             ( jtag_TCK             ),
    .jtag_TMS             ( jtag_TMS             ),
    .jtag_TDI             ( jtag_TDI             ),
    .jtag_TRSTn           ( jtag_TRSTn           ),
    .jtag_TDO_data        ( jtag_TDO_data        ),
    .jtag_TDO_driven      ( jtag_TDO_driven      ),
    .exit                 ( jtag_exit            )
  );
*/
  dmi_jtag i_dmi_jtag (
    .clk_i            ( clk_i           ),
    .rst_ni           ( rst_ni          ),
    .testmode_i       ( test_en         ),
    .dmi_req_o        ( jtag_dmi_req    ),
    .dmi_req_valid_o  ( jtag_req_valid  ),
    .dmi_req_ready_i  ( debug_req_ready ),
    .dmi_resp_i       ( debug_resp      ),
    .dmi_resp_ready_o ( jtag_resp_ready ),
    .dmi_resp_valid_i ( jtag_resp_valid ),
    .dmi_rst_no       (                 ), // not connected
    .tck_i            ( jtag_TCK        ),
    .tms_i            ( jtag_TMS        ),
    .trst_ni          ( jtag_TRSTn      ),
    .td_i             ( jtag_TDI        ),
    .td_o             ( jtag_TDO_data   ),
    .tdo_oe_o         ( jtag_TDO_driven )
  );

  // SiFive's SimDTM Module
  // Converts to DPI calls
  logic [1:0] debug_req_bits_op;
  assign dmi_req.op = dm::dtm_op_e'(debug_req_bits_op);

  if (InclSimDTM) begin
    SimDTM i_SimDTM (
      .clk                  ( clk_i                 ),
      .reset                ( ~rst_ni               ),
      .debug_req_valid      ( dmi_req_valid         ),
      .debug_req_ready      ( debug_req_ready       ),
      .debug_req_bits_addr  ( dmi_req.addr          ),
      .debug_req_bits_op    ( debug_req_bits_op     ),
      .debug_req_bits_data  ( dmi_req.data          ),
      .debug_resp_valid     ( dmi_resp_valid        ),
      .debug_resp_ready     ( dmi_resp_ready        ),
      .debug_resp_bits_resp ( debug_resp.resp       ),
      .debug_resp_bits_data ( debug_resp.data       ),
      .exit                 ( dmi_exit              )
    );
  end else begin
    assign dmi_req_valid = '0;
    assign debug_req_bits_op = '0;
    assign dmi_exit = 1'b0;
  end

  // this delay window allows the core to read and execute init code
  // from the bootrom before the first debug request can interrupt
  // core. this is needed in cases where an fsbl is involved that
  // expects a0 and a1 to be initialized with the hart id and a
  // pointer to the dev tree, respectively.
  localparam int unsigned DmiDelCycles = 500;

  logic debug_req_core_ungtd;
  int dmi_del_cnt_d, dmi_del_cnt_q;

  assign dmi_del_cnt_d  = (dmi_del_cnt_q) ? dmi_del_cnt_q - 1 : 0;
  assign debug_req_core = (dmi_del_cnt_q) ? 1'b0 :
                          (!debug_enable) ? 1'b0 : debug_req_core_ungtd;

  always_ff @(posedge clk_i or negedge rst_ni) begin : p_dmi_del_cnt
    if(!rst_ni) begin
      dmi_del_cnt_q <= DmiDelCycles;
    end else begin
      dmi_del_cnt_q <= dmi_del_cnt_d;
    end
  end

  ariane_axi::req_t    dm_axi_m_req;
  ariane_axi::resp_t   dm_axi_m_resp;

  logic                dm_slave_req;
  logic                dm_slave_we;
  logic [64-1:0]       dm_slave_addr;
  logic [64/8-1:0]     dm_slave_be;
  logic [64-1:0]       dm_slave_wdata;
  logic [64-1:0]       dm_slave_rdata;

  logic                dm_master_req;
  logic [64-1:0]       dm_master_add;
  logic                dm_master_we;
  logic [64-1:0]       dm_master_wdata;
  logic [64/8-1:0]     dm_master_be;
  logic                dm_master_gnt;
  logic                dm_master_r_valid;
  logic [64-1:0]       dm_master_r_rdata;

  // debug module
  dm_top #(
    .NrHarts              ( 1                           ),
    .BusWidth             ( AXI_DATA_WIDTH              ),
    .SelectableHarts      ( 1'b1                        )
  ) i_dm_top (
    .clk_i                ( clk_i                       ),
    .rst_ni               ( rst_ni                      ), // PoR
    .testmode_i           ( test_en                     ),
    .ndmreset_o           ( ndmreset                    ),
    .dmactive_o           (                             ), // active debug session
    .debug_req_o          ( debug_req_core_ungtd        ),
    .unavailable_i        ( '0                          ),
    .hartinfo_i           ( {ariane_pkg::DebugHartInfo} ),
    .slave_req_i          ( dm_slave_req                ),
    .slave_we_i           ( dm_slave_we                 ),
    .slave_addr_i         ( dm_slave_addr               ),
    .slave_be_i           ( dm_slave_be                 ),
    .slave_wdata_i        ( dm_slave_wdata              ),
    .slave_rdata_o        ( dm_slave_rdata              ),
    .master_req_o         ( dm_master_req               ),
    .master_add_o         ( dm_master_add               ),
    .master_we_o          ( dm_master_we                ),
    .master_wdata_o       ( dm_master_wdata             ),
    .master_be_o          ( dm_master_be                ),
    .master_gnt_i         ( dm_master_gnt               ),
    .master_r_valid_i     ( dm_master_r_valid           ),
    .master_r_rdata_i     ( dm_master_r_rdata           ),
    .dmi_rst_ni           ( rst_ni                      ),
    .dmi_req_valid_i      ( debug_req_valid             ),
    .dmi_req_ready_o      ( debug_req_ready             ),
    .dmi_req_i            ( debug_req                   ),
    .dmi_resp_valid_o     ( debug_resp_valid            ),
    .dmi_resp_ready_i     ( debug_resp_ready            ),
    .dmi_resp_o           ( debug_resp                  )
  );


  axi2mem #(
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) i_dm_axi2mem (
    .clk_i      ( clk_i                     ),
    .rst_ni     ( rst_ni                    ),
    .slave      ( master[culsans_pkg::Debug] ),
    .req_o      ( dm_slave_req              ),
    .we_o       ( dm_slave_we               ),
    .addr_o     ( dm_slave_addr             ),
    .be_o       ( dm_slave_be               ),
    .user_o     (                           ),
    .data_o     ( dm_slave_wdata            ),
    .user_i     ( '0                        ),
    .data_i     ( dm_slave_rdata            )
  );

  `AXI_ASSIGN_FROM_REQ(to_xbar[1], dm_axi_m_req)
  `AXI_ASSIGN_TO_RESP(dm_axi_m_resp, to_xbar[1])

  axi_adapter #(
    .DATA_WIDTH            ( AXI_DATA_WIDTH            ),
    .AXI_ID_WIDTH          ( culsans_pkg::IdWidth       ),
    .mst_req_t             ( ariane_axi::req_t ),
    .mst_resp_t            ( ariane_axi::resp_t )
  ) i_dm_axi_master (
    .clk_i                 ( clk_i                     ),
    .rst_ni                ( rst_ni                    ),
    .req_i                 ( dm_master_req             ),
    .type_i                ( ariane_axi::SINGLE_REQ    ),
    .trans_type_i          ( ariane_ace::READ_SHARED ),
    .amo_i                 ( ariane_pkg::AMO_NONE      ),
    .gnt_o                 ( dm_master_gnt             ),
    .addr_i                ( dm_master_add             ),
    .we_i                  ( dm_master_we              ),
    .wdata_i               ( dm_master_wdata           ),
    .be_i                  ( dm_master_be              ),
    .size_i                ( 2'b11                     ), // always do 64bit here and use byte enables to gate
    .id_i                  ( '0                        ),
    .valid_o               ( dm_master_r_valid         ),
    .rdata_o               ( dm_master_r_rdata         ),
    .id_o                  (                           ),
    .critical_word_o       (                           ),
    .critical_word_valid_o (                           ),
    .dirty_o (),
    .shared_o(),
    .axi_req_o             ( dm_axi_m_req              ),
    .axi_resp_i            ( dm_axi_m_resp             )
  );


  // ---------------
  // ROM
  // ---------------
  logic                         rom_req;
  logic [AXI_ADDRESS_WIDTH-1:0] rom_addr;
  logic [AXI_DATA_WIDTH-1:0]    rom_rdata;

  axi2mem #(
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) i_axi2rom (
    .clk_i  ( clk_i                   ),
    .rst_ni ( ndmreset_n              ),
    .slave  ( master[culsans_pkg::ROM] ),
    .req_o  ( rom_req                 ),
    .we_o   (                         ),
    .addr_o ( rom_addr                ),
    .be_o   (                         ),
    .user_o (                         ),
    .data_o (                         ),
    .user_i ( '0                      ),
    .data_i ( rom_rdata               )
  );

`ifdef DROMAJO
  dromajo_bootrom i_bootrom (
    .clk_i      ( clk_i     ),
    .req_i      ( rom_req   ),
    .addr_i     ( rom_addr  ),
    .rdata_o    ( rom_rdata )
  );
`else
  bootrom i_bootrom (
    .clk_i      ( clk_i     ),
    .req_i      ( rom_req   ),
    .addr_i     ( rom_addr  ),
    .rdata_o    ( rom_rdata )
  );
`endif

  // ------------------------------
  // GPIO
  // ------------------------------

  // GPIO not implemented, adding an error slave here

  culsans_pkg::req_slv_t  gpio_req;
  culsans_pkg::resp_slv_t gpio_resp;
  `AXI_ASSIGN_TO_REQ(gpio_req, master[culsans_pkg::GPIO])
  `AXI_ASSIGN_FROM_RESP(master[culsans_pkg::GPIO], gpio_resp)
  axi_err_slv #(
    .AxiIdWidth ( culsans_pkg::IdWidthSlave   ),
    .axi_req_t      ( culsans_pkg::req_slv_t  ),
    .axi_resp_t     ( culsans_pkg::resp_slv_t )
  ) i_gpio_err_slv (
    .clk_i      ( clk_i      ),
    .rst_ni     ( ndmreset_n ),
    .test_i     ( test_en    ),
    .slv_req_i  ( gpio_req ),
    .slv_resp_o ( gpio_resp )
  );


  // ------------------------------
  // Memory + Exclusive Access
  // ------------------------------
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) dram();

  logic                         req;
  logic                         we;
  logic [AXI_ADDRESS_WIDTH-1:0] addr;
  logic [AXI_DATA_WIDTH/8-1:0]  be;
  logic [AXI_DATA_WIDTH-1:0]    wdata;
  logic [AXI_DATA_WIDTH-1:0]    rdata;
  logic [AXI_USER_WIDTH-1:0]    wuser;
  logic [AXI_USER_WIDTH-1:0]    ruser;

  axi_riscv_atomics_wrap #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           ),
    .AXI_MAX_WRITE_TXNS ( 1  ),
    .RISCV_WORD_WIDTH   ( 64 )
  ) i_axi_riscv_atomics (
    .clk_i,
    .rst_ni ( ndmreset_n               ),
    .slv    ( master[culsans_pkg::DRAM] ),
    .mst    ( dram                     )
  );

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) dram_delayed();

  axi_delayer_intf #(
    .AXI_ID_WIDTH        ( culsans_pkg::IdWidthSlave ),
    .AXI_ADDR_WIDTH      ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH      ( AXI_DATA_WIDTH           ),
    .AXI_USER_WIDTH      ( AXI_USER_WIDTH           ),
    .STALL_RANDOM_INPUT  ( StallRandomInput         ),
    .STALL_RANDOM_OUTPUT ( StallRandomOutput        ),
    .FIXED_DELAY_INPUT   ( 0                        ),
    .FIXED_DELAY_OUTPUT  ( 0                        )
  ) i_axi_delayer (
    .clk_i  ( clk_i        ),
    .rst_ni ( ndmreset_n   ),
    .slv    ( dram         ),
    .mst    ( dram_delayed )
  );

  axi2mem #(
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) i_axi2mem (
    .clk_i  ( clk_i        ),
    .rst_ni ( ndmreset_n   ),
    .slave  ( dram_delayed ),
    .req_o  ( req          ),
    .we_o   ( we           ),
    .addr_o ( addr         ),
    .be_o   ( be           ),
    .user_o ( wuser        ),
    .data_o ( wdata        ),
    .user_i ( ruser        ),
    .data_i ( rdata        )
  );

  sram #(
    .DATA_WIDTH ( AXI_DATA_WIDTH ),
    .USER_WIDTH ( AXI_USER_WIDTH ),
    .USER_EN    ( AXI_USER_EN    ),
`ifdef VERILATOR
    .SIM_INIT   ( "none"         ),
`else
    .SIM_INIT   ( "zeros"        ),
`endif
`ifdef DROMAJO
    .DROMAJO_RAM (1),
`endif
    .NUM_WORDS  ( NUM_WORDS      )
  ) i_sram (
    .clk_i      ( clk_i                                                                       ),
    .rst_ni     ( rst_ni                                                                      ),
    .req_i      ( req                                                                         ),
    .we_i       ( we                                                                          ),
    .addr_i     ( addr[$clog2(NUM_WORDS)-1+$clog2(AXI_DATA_WIDTH/8):$clog2(AXI_DATA_WIDTH/8)] ),
    .wuser_i    ( wuser                                                                       ),
    .wdata_i    ( wdata                                                                       ),
    .be_i       ( be                                                                          ),
    .ruser_o    ( ruser                                                                       ),
    .rdata_o    ( rdata                                                                       )
  );

  assign exit_o = (req == 1'b1 && we == 1'b1 && addr == culsans_pkg::exitAddr) ? wdata : '0;

  // ---------------
  // CCU
  // ---------------

  ACE_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH   ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidth ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
  ) core_to_CCU[culsans_pkg::NB_CORES - 1 : 0]();

   SNOOP_BUS
     #(
       .SNOOP_ADDR_WIDTH (AXI_ADDRESS_WIDTH),
       .SNOOP_DATA_WIDTH (AXI_DATA_WIDTH)
       )
   CCU_to_core[culsans_pkg::NB_CORES-1:0]();

  localparam ace_pkg::ccu_cfg_t CCU_CFG = '{
    NoSlvPorts: culsans_pkg::NB_CORES,
    MaxMstTrans: 2, // Probably requires update
    MaxSlvTrans: 2, // Probably requires update
    FallThrough: 1'b0,
    LatencyMode: axi_pkg::NO_LATENCY,
    AxiIdWidthSlvPorts: culsans_pkg::IdWidth,
    AxiIdUsedSlvPorts: culsans_pkg::IdWidth,
    UniqueIds: 1'b1,
    AxiAddrWidth: AXI_ADDRESS_WIDTH,
    AxiDataWidth: AXI_DATA_WIDTH
  };

  ace_ccu_top_intf #(
    .AXI_USER_WIDTH ( AXI_USER_WIDTH          ),
    .Cfg            ( CCU_CFG       )
  ) i_ccu (
    .clk_i                 ( clk_i      ),
    .rst_ni                ( ndmreset_n ),
    .test_i                ( test_en    ),
    .slv_ports             ( core_to_CCU ),
    .snoop_ports           ( CCU_to_core ),
    .mst_ports             ( to_xbar[0]  )
  );

  // ---------------
  // AXI Xbar
  // ---------------

  axi_pkg::xbar_rule_64_t [culsans_pkg::NB_PERIPHERALS-1:0] addr_map;

  assign addr_map = '{
    '{ idx: culsans_pkg::Debug,    start_addr: culsans_pkg::DebugBase,    end_addr: culsans_pkg::DebugBase + culsans_pkg::DebugLength       },
    '{ idx: culsans_pkg::ROM,      start_addr: culsans_pkg::ROMBase,      end_addr: culsans_pkg::ROMBase + culsans_pkg::ROMLength           },
    '{ idx: culsans_pkg::CLINT,    start_addr: culsans_pkg::CLINTBase,    end_addr: culsans_pkg::CLINTBase + culsans_pkg::CLINTLength       },
    '{ idx: culsans_pkg::PLIC,     start_addr: culsans_pkg::PLICBase,     end_addr: culsans_pkg::PLICBase + culsans_pkg::PLICLength         },
    '{ idx: culsans_pkg::UART,     start_addr: culsans_pkg::UARTBase,     end_addr: culsans_pkg::UARTBase + culsans_pkg::UARTLength         },
    '{ idx: culsans_pkg::Timer,    start_addr: culsans_pkg::TimerBase,    end_addr: culsans_pkg::TimerBase + culsans_pkg::TimerLength       },
    '{ idx: culsans_pkg::SPI,      start_addr: culsans_pkg::SPIBase,      end_addr: culsans_pkg::SPIBase + culsans_pkg::SPILength           },
    '{ idx: culsans_pkg::Ethernet, start_addr: culsans_pkg::EthernetBase, end_addr: culsans_pkg::EthernetBase + culsans_pkg::EthernetLength },
    '{ idx: culsans_pkg::GPIO,     start_addr: culsans_pkg::GPIOBase,     end_addr: culsans_pkg::GPIOBase + culsans_pkg::GPIOLength         },
    '{ idx: culsans_pkg::DRAM,     start_addr: culsans_pkg::DRAMBase,     end_addr: culsans_pkg::DRAMBase + culsans_pkg::DRAMLength         }
  };

  localparam axi_pkg::xbar_cfg_t AXI_XBAR_CFG = '{
    NoSlvPorts: culsans_pkg::NrSlaves,
    NoMstPorts: culsans_pkg::NB_PERIPHERALS,
    MaxMstTrans: 1, // Probably requires update
    MaxSlvTrans: 1, // Probably requires update
    FallThrough: 1'b0,
    LatencyMode: axi_pkg::NO_LATENCY,
    PipelineStages: 1,
    AxiIdWidthSlvPorts: culsans_pkg::IdWidthToXbar,
    AxiIdUsedSlvPorts: culsans_pkg::IdWidthToXbar,
    UniqueIds: 1'b0,
    AxiAddrWidth: AXI_ADDRESS_WIDTH,
    AxiDataWidth: AXI_DATA_WIDTH,
    NoAddrRules: culsans_pkg::NB_PERIPHERALS
  };

  axi_xbar_intf #(
    .AXI_USER_WIDTH ( AXI_USER_WIDTH          ),
    .Cfg            ( AXI_XBAR_CFG            ),
    .rule_t         ( axi_pkg::xbar_rule_64_t )
  ) i_axi_xbar (
    .clk_i                 ( clk_i      ),
    .rst_ni                ( ndmreset_n ),
    .test_i                ( test_en    ),
    .slv_ports             ( to_xbar    ),
    .mst_ports             ( master     ),
    .addr_map_i            ( addr_map   ),
    .en_default_mst_port_i ( '0         ),
    .default_mst_port_i    ( '0         )
  );

  // ---------------
  // CLINT
  // ---------------
  logic [culsans_pkg::NB_CORES-1:0] ipi;
  logic [culsans_pkg::NB_CORES-1:0] timer_irq;

  culsans_pkg::req_slv_t  axi_clint_req;
  culsans_pkg::resp_slv_t axi_clint_resp;

  clint #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH          ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH             ),
    .AXI_ID_WIDTH   ( culsans_pkg::IdWidthSlave   ),
    .NR_CORES       ( culsans_pkg::NB_CORES       ),
    .axi_req_t      ( culsans_pkg::req_slv_t  ),
    .axi_resp_t     ( culsans_pkg::resp_slv_t )
  ) i_clint (
    .clk_i       ( clk_i          ),
    .rst_ni      ( ndmreset_n     ),
    .testmode_i  ( test_en        ),
    .axi_req_i   ( axi_clint_req  ),
    .axi_resp_o  ( axi_clint_resp ),
    .rtc_i       ( rtc_i          ),
    .timer_irq_o ( timer_irq      ),
    .ipi_o       ( ipi            )
  );

  `AXI_ASSIGN_TO_REQ(axi_clint_req, master[culsans_pkg::CLINT])
  `AXI_ASSIGN_FROM_RESP(master[culsans_pkg::CLINT], axi_clint_resp)

  // ---------------
  // Peripherals
  // ---------------
  logic tx, rx;
  logic [culsans_pkg::NumTargets-1:0] irqs;

  culsans_peripherals #(
    .AxiAddrWidth ( AXI_ADDRESS_WIDTH        ),
    .AxiDataWidth ( AXI_DATA_WIDTH           ),
    .AxiIdWidth   ( culsans_pkg::IdWidthSlave ),
`ifndef VERILATOR
  // disable UART when using Spike, as we need to rely on the mockuart
  `ifdef SPIKE_TANDEM
    .InclUART     ( 1'b0                     ),
  `else
    .InclUART     ( 1'b0                     ),
  `endif
`else
    .InclUART     ( 1'b0                     ),
`endif
    .InclSPI      ( 1'b0                     ),
    .InclEthernet ( 1'b0                     )
  ) i_ariane_peripherals (
    .clk_i     ( clk_i                        ),
    .rst_ni    ( ndmreset_n                   ),
    .plic      ( master[culsans_pkg::PLIC]     ),
    .uart      ( master[culsans_pkg::UART]     ),
    .spi       ( master[culsans_pkg::SPI]      ),
    .ethernet  ( master[culsans_pkg::Ethernet] ),
    .timer     ( master[culsans_pkg::Timer]    ),
    .irq_o     ( irqs                         ),
    .rx_i      ( rx                           ),
    .tx_o      ( tx                           ),
    .eth_txck  ( ),
    .eth_rxck  ( ),
    .eth_rxctl ( ),
    .eth_rxd   ( ),
    .eth_rst_n ( ),
    .eth_tx_en ( ),
    .eth_txd   ( ),
    .phy_mdio  ( ),
    .eth_mdc   ( ),
    .mdio      ( ),
    .mdc       ( ),
    .spi_clk_o ( ),
    .spi_mosi  ( ),
    .spi_miso  ( ),
    .spi_ss    ( )
  );

  uart_bus #(.BAUD_RATE(115200), .PARITY_EN(0)) i_uart_bus (.rx(tx), .tx(rx), .rx_en(1'b1));

  // ---------------
  // Cores
  // ---------------
  ariane_ace::m2s_t [culsans_pkg::NB_CORES-1:0] ace_ariane_req;
  ariane_ace::s2m_t [culsans_pkg::NB_CORES-1:0] ace_ariane_resp;
  ariane_rvfi_pkg::rvfi_port_t [culsans_pkg::NB_CORES-1:0] rvfi;

  logic [culsans_pkg::NB_CORES-1:0][7:0] hart_id;

  for (genvar i = 0; i < culsans_pkg::NB_CORES; i++) begin

    assign hart_id[i] = i;

    ariane #(
      .ArianeCfg  ( culsans_pkg::ArianeSocCfg ),
      .mst_req_t (ariane_ace::m2s_t),
      .mst_resp_t (ariane_ace::s2m_t)
    ) i_ariane (
      .clk_i                ( clk_i               ),
      .rst_ni               ( ndmreset_n          ),
      .boot_addr_i          ( BootAddress         ),
      .hart_id_i            ( {56'h0, hart_id[i]} ),
      .irq_i                ( irqs[2*i+1:2*i]     ),
      .ipi_i                ( ipi[i]              ),
      .time_irq_i           ( timer_irq[i]        ),
  `ifdef RVFI_TRACE
      .rvfi_o               ( rvfi[i]             ),
  `endif
  // Disable Debug when simulating with Spike
  `ifdef SPIKE_TANDEM
      .debug_req_i          ( 1'b0                ),
  `else
      .debug_req_i          ( debug_req_core      ),
  `endif
      .axi_req_o            ( ace_ariane_req[i]   ),
      .axi_resp_i           ( ace_ariane_resp[i]  )
    );

    `ACE_ASSIGN_FROM_REQ(core_to_CCU[i], ace_ariane_req[i])
    `ACE_ASSIGN_TO_RESP(ace_ariane_resp[i], core_to_CCU[i])
     `SNOOP_ASSIGN_FROM_RESP(CCU_to_core[i], ace_ariane_req[i])
     `SNOOP_ASSIGN_TO_REQ(ace_ariane_resp[i], CCU_to_core[i])

  end

  // -------------
  // Simulation Helper Functions
  // -------------
  // check for response errors
  for (genvar i = 0; i < culsans_pkg::NB_CORES; i++) begin

    always_ff @(posedge clk_i) begin : p_assert
      if (ace_ariane_req[i].r_ready &&
        ace_ariane_resp[i].r_valid &&
        ace_ariane_resp[i].r.resp inside {axi_pkg::RESP_DECERR, axi_pkg::RESP_SLVERR}) begin
        $warning("R Response Errored");
      end
      if (ace_ariane_req[i].b_ready &&
        ace_ariane_resp[i].b_valid &&
        ace_ariane_resp[i].b.resp inside {axi_pkg::RESP_DECERR, axi_pkg::RESP_SLVERR}) begin
        $warning("B Response Errored");
      end
    end

    rvfi_tracer  #(
      .HART_ID(i),
      .DEBUG_START(0),
      .DEBUG_STOP(0)
    ) rvfi_tracer_i (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .rvfi_i(rvfi[i])
    );
  end

`ifdef AXI_SVA
  // AXI 4 Assertion IP integration - You will need to get your own copy of this IP if you want
  // to use it
  Axi4PC #(
    .DATA_WIDTH(culsans_pkg::DataWidth),
    .WID_WIDTH(culsans_pkg::IdWidthSlave),
    .RID_WIDTH(culsans_pkg::IdWidthSlave),
    .AWUSER_WIDTH(culsans_pkg::UserWidth),
    .WUSER_WIDTH(culsans_pkg::UserWidth),
    .BUSER_WIDTH(culsans_pkg::UserWidth),
    .ARUSER_WIDTH(culsans_pkg::UserWidth),
    .RUSER_WIDTH(culsans_pkg::UserWidth),
    .ADDR_WIDTH(culsans_pkg::AddrWidth)
  ) i_Axi4PC (
    .ACLK(clk_i),
    .ARESETn(ndmreset_n),
    .AWID(dram.aw_id),
    .AWADDR(dram.aw_addr),
    .AWLEN(dram.aw_len),
    .AWSIZE(dram.aw_size),
    .AWBURST(dram.aw_burst),
    .AWLOCK(dram.aw_lock),
    .AWCACHE(dram.aw_cache),
    .AWPROT(dram.aw_prot),
    .AWQOS(dram.aw_qos),
    .AWREGION(dram.aw_region),
    .AWUSER(dram.aw_user),
    .AWVALID(dram.aw_valid),
    .AWREADY(dram.aw_ready),
    .WLAST(dram.w_last),
    .WDATA(dram.w_data),
    .WSTRB(dram.w_strb),
    .WUSER(dram.w_user),
    .WVALID(dram.w_valid),
    .WREADY(dram.w_ready),
    .BID(dram.b_id),
    .BRESP(dram.b_resp),
    .BUSER(dram.b_user),
    .BVALID(dram.b_valid),
    .BREADY(dram.b_ready),
    .ARID(dram.ar_id),
    .ARADDR(dram.ar_addr),
    .ARLEN(dram.ar_len),
    .ARSIZE(dram.ar_size),
    .ARBURST(dram.ar_burst),
    .ARLOCK(dram.ar_lock),
    .ARCACHE(dram.ar_cache),
    .ARPROT(dram.ar_prot),
    .ARQOS(dram.ar_qos),
    .ARREGION(dram.ar_region),
    .ARUSER(dram.ar_user),
    .ARVALID(dram.ar_valid),
    .ARREADY(dram.ar_ready),
    .RID(dram.r_id),
    .RLAST(dram.r_last),
    .RDATA(dram.r_data),
    .RRESP(dram.r_resp),
    .RUSER(dram.r_user),
    .RVALID(dram.r_valid),
    .RREADY(dram.r_ready),
    .CACTIVE('0),
    .CSYSREQ('0),
    .CSYSACK('0)
  );
`endif
endmodule
