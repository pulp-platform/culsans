// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright 2022 PlanV GmbH
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

package culsans_pkg;

  localparam NB_CORES = 4; // 2~4 number of cores

  // M-Mode Hart, S-Mode Hart
  localparam int unsigned NumTargets = 2*NB_CORES;
  // Uart, SPI, Ethernet, reserved
  localparam int unsigned NumSources = 30;
  localparam int unsigned MaxPriority = 7;

  localparam NrSlaves = 2; // actually masters, but slaves on the crossbar

  // 4 is recommended by AXI standard, so lets stick to it, do not change
  localparam IdWidth = 4;
  localparam IdWidthToXbar = IdWidth + $clog2(NB_CORES) + $clog2(NB_CORES+1);
  localparam IdWidthSlave = IdWidthToXbar + $clog2(NrSlaves);

  typedef enum int unsigned {
    DRAM     = 0,
    GPIO     = 1,
    Ethernet = 2,
    SPI      = 3,
    Timer    = 4,
    UART     = 5,
    PLIC     = 6,
    CLINT    = 7,
    ROM      = 8,
    Debug    = 9
  } axi_slaves_t;

  localparam NB_PERIPHERALS = Debug + 1;


  localparam logic[63:0] DebugLength    = 64'h1000;
  localparam logic[63:0] ROMLength      = 64'h10000;
  localparam logic[63:0] CLINTLength    = 64'hC0000;
  localparam logic[63:0] PLICLength     = 64'h3FF_FFFF;
  localparam logic[63:0] UARTLength     = 64'h1000;
  localparam logic[63:0] TimerLength    = 64'h1000;
  localparam logic[63:0] SPILength      = 64'h800000;
  localparam logic[63:0] EthernetLength = 64'h10000;
  localparam logic[63:0] GPIOLength     = 64'h1000;
  localparam logic[63:0] DRAMLength     = 64'h40000000; // 1GByte of DDR (split between two chips on Genesys2)

  localparam logic[63:0] uncachedLength = 64'h60000;

  localparam logic[63:0] SRAMLength     = 64'h1800000;  // 24 MByte of SRAM
  // Instantiate AXI protocol checkers
  localparam bit GenProtocolChecker = 1'b0;

  typedef enum logic [63:0] {
    DebugBase    = 64'h0000_0000,
    ROMBase      = 64'h0001_0000,
    CLINTBase    = 64'h0200_0000,
    PLICBase     = 64'h0C00_0000,
    UARTBase     = 64'h1000_0000,
    TimerBase    = 64'h1800_0000,
    SPIBase      = 64'h2000_0000,
    EthernetBase = 64'h3000_0000,
    GPIOBase     = 64'h4000_0000,
    DRAMBase     = 64'h8000_0000
  } soc_bus_start_t;

  localparam logic [63:0] sharedOffset = 64'h40000;
  localparam logic [63:0] sharedLength = 64'h40000;

  localparam NrRegion = 1;
  localparam logic [NrRegion-1:0][NB_PERIPHERALS-1:0] ValidRule = {{NrRegion * NB_PERIPHERALS}{1'b1}};

  localparam ariane_pkg::ariane_cfg_t ArianeSocCfg = '{
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
    // idempotent region
    NrNonIdempotentRules:  1,
    NonIdempotentAddrBase: {64'b0},
    NonIdempotentLength:   {DRAMBase},
    NrExecuteRegionRules:  3,
    ExecuteRegionAddrBase: {DRAMBase,   ROMBase,   DebugBase},
    ExecuteRegionLength:   {DRAMLength, ROMLength, DebugLength},
    // cached region
    NrCachedRegionRules:    1,
    CachedRegionAddrBase:  {DRAMBase + uncachedLength},
    CachedRegionLength:    {DRAMLength - uncachedLength},
    // shared region
    NrSharedRegionRules:    1,
    SharedRegionAddrBase:  {DRAMBase + sharedOffset},
    SharedRegionLength:    {sharedLength},
    //  cache config
    AxiCompliant:           1'b1,
    SwapEndianess:          1'b0,
    // debug
    DmBaseAddress:          DebugBase,
    NrPMPEntries:           8
  };

   localparam ariane_pkg::ariane_cfg_t ArianeFpgaSocCfg = '{
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
    // idempotent region
    NrNonIdempotentRules:  1,
    NonIdempotentAddrBase: {64'b0},
    NonIdempotentLength:   {DRAMBase},
    NrExecuteRegionRules:  3,
    ExecuteRegionAddrBase: {DRAMBase,   ROMBase,   DebugBase},
    ExecuteRegionLength:   {DRAMLength, ROMLength, DebugLength},
    // cached region
    NrCachedRegionRules:    1,
    CachedRegionAddrBase:  {DRAMBase},
    CachedRegionLength:    {DRAMLength},
    // shared region
    NrSharedRegionRules:    1,
    SharedRegionAddrBase:  {DRAMBase},
    SharedRegionLength:    {DRAMLength},
    //  cache config
    AxiCompliant:           1'b1,
    SwapEndianess:          1'b0,
    // debug
    DmBaseAddress:          DebugBase,
    NrPMPEntries:           8
  };

  localparam exitOffset = 64'h0;
  localparam exitAddr = DRAMBase + exitOffset;

  // used in axi_adapter.sv
  typedef enum logic { SINGLE_REQ, CACHE_LINE_REQ } ad_req_t;

  localparam UserWidth = ariane_pkg::AXI_USER_WIDTH;
  localparam AddrWidth = 64;
  localparam DataWidth = 64;
  localparam StrbWidth = DataWidth / 8;

  typedef logic [IdWidth-1:0]      id_t;
  typedef logic [IdWidthSlave-1:0] id_slv_t;
  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [StrbWidth-1:0] strb_t;
  typedef logic [UserWidth-1:0] user_t;

  // AW Channel
  typedef struct packed {
      id_t              id;
      addr_t            addr;
      axi_pkg::len_t    len;
      axi_pkg::size_t   size;
      axi_pkg::burst_t  burst;
      logic             lock;
      axi_pkg::cache_t  cache;
      axi_pkg::prot_t   prot;
      axi_pkg::qos_t    qos;
      axi_pkg::region_t region;
      axi_pkg::atop_t   atop;
      user_t            user;
      ace_pkg::awsnoop_t snoop;
      ace_pkg::bar_t    bar;
      ace_pkg::domain_t domain;
      ace_pkg::awunique_t awunique;
  } aw_chan_t;

  // AW Channel - Slave
  typedef struct packed {
      id_slv_t          id;
      addr_t            addr;
      axi_pkg::len_t    len;
      axi_pkg::size_t   size;
      axi_pkg::burst_t  burst;
      logic             lock;
      axi_pkg::cache_t  cache;
      axi_pkg::prot_t   prot;
      axi_pkg::qos_t    qos;
      axi_pkg::region_t region;
      axi_pkg::atop_t   atop;
      user_t            user;
      ace_pkg::awsnoop_t snoop;
      ace_pkg::bar_t    bar;
      ace_pkg::domain_t domain;
      ace_pkg::awunique_t awunique;
  } aw_chan_slv_t;

  // W Channel - AXI4 doesn't define a wid
  typedef struct packed {
      data_t data;
      strb_t strb;
      logic  last;
      user_t user;
  } w_chan_t;

  // B Channel
  typedef struct packed {
      id_t            id;
      axi_pkg::resp_t resp;
      user_t          user;
  } b_chan_t;

  // B Channel - Slave
  typedef struct packed {
      id_slv_t        id;
      axi_pkg::resp_t resp;
      user_t          user;
  } b_chan_slv_t;

  // AR Channel
  typedef struct packed {
      id_t             id;
      addr_t            addr;
      axi_pkg::len_t    len;
      axi_pkg::size_t   size;
      axi_pkg::burst_t  burst;
      logic             lock;
      axi_pkg::cache_t  cache;
      axi_pkg::prot_t   prot;
      axi_pkg::qos_t    qos;
      axi_pkg::region_t region;
      user_t            user;
      ace_pkg::arsnoop_t snoop;
      ace_pkg::bar_t    bar;
      ace_pkg::domain_t domain;
  } ar_chan_t;

  // AR Channel - Slave
  typedef struct packed {
      id_slv_t          id;
      addr_t            addr;
      axi_pkg::len_t    len;
      axi_pkg::size_t   size;
      axi_pkg::burst_t  burst;
      logic             lock;
      axi_pkg::cache_t  cache;
      axi_pkg::prot_t   prot;
      axi_pkg::qos_t    qos;
      axi_pkg::region_t region;
      user_t            user;
      ace_pkg::arsnoop_t snoop;
      ace_pkg::bar_t    bar;
      ace_pkg::domain_t domain;
  } ar_chan_slv_t;

  // R Channel
  typedef struct packed {
      id_t            id;
      data_t          data;
      ace_pkg::rresp_t resp;
      logic           last;
      user_t          user;
  } r_chan_t;

  // R Channel - Slave
  typedef struct packed {
      id_slv_t        id;
      data_t          data;
      ace_pkg::rresp_t resp;
      logic           last;
      user_t          user;
  } r_chan_slv_t;

  // Request/Response structs
  typedef struct packed {
      aw_chan_t aw;
      logic     aw_valid;
      w_chan_t  w;
      logic     w_valid;
      logic     b_ready;
      ar_chan_t ar;
      logic     ar_valid;
      logic     r_ready;
  } req_t;

  typedef struct packed {
      logic     aw_ready;
      logic     ar_ready;
      logic     w_ready;
      logic     b_valid;
      b_chan_t  b;
      logic     r_valid;
      r_chan_t  r;
  } resp_t;

  typedef struct packed {
      aw_chan_slv_t aw;
      logic         aw_valid;
      w_chan_t      w;
      logic         w_valid;
      logic         b_ready;
      ar_chan_slv_t ar;
      logic         ar_valid;
      logic         r_ready;
  } req_slv_t;

  typedef struct packed {
      logic         aw_ready;
      logic         ar_ready;
      logic         w_ready;
      logic         b_valid;
      b_chan_slv_t  b;
      logic         r_valid;
      r_chan_slv_t  r;
  } resp_slv_t;

endpackage
