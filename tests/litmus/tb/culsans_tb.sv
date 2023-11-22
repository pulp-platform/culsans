module culsans_tb ();

    // Clock & reset generation

    logic clk;
    logic rst;

    localparam CLK_PERIOD = 10ns;

   initial begin
        clk = 1'b0;
        rst = 1'b1;

        repeat(8)
            #(CLK_PERIOD/2) clk = ~clk;

        rst = 1'b0;

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

    // Detect the end of the simulation

    logic [31:0] exit_val;

    initial begin
        forever begin
            wait (exit_val[0]);
            #(CLK_PERIOD*1000)
            $finish();
        end
    end

    initial begin
        wait (i_culsans.gen_ariane[0].i_ariane.i_cva6.commit_instr_id_commit[0].pc == 64'h800600a0 && i_culsans.gen_ariane[0].i_ariane.i_cva6.commit_instr_id_commit[0].valid == 1'b1 && i_culsans.gen_ariane[0].i_ariane.i_cva6.commit_ack[0] == 1'b1);
        $finish();
    end

    // Memory initialisation

    initial begin
        integer file;
        integer error;
        static string mem_init_file = "main.hex";

        @(negedge rst);
        #2

        `ifdef USE_XILINX_SRAM
            $readmemh(mem_init_file, i_culsans.i_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem);
        `else
            $readmemh(mem_init_file, i_culsans.i_sram.i_tc_sram.sram);
        `endif

    end

    // DUT

    culsans_top #(
        .InclSimDTM (1'b0),
        .NUM_WORDS  (80*1024*1024), // 4Kwords
        .BootAddress (culsans_pkg::DRAMBase + 64'h60000),
        .ArianeCfg (culsans_pkg::ArianeFpgaSocCfg)
    ) i_culsans (
        .clk_i (clk),
        .rtc_i (rtc),
        .rst_ni(~rst),
        .exit_o (exit_val)
    );
    


    // ...

endmodule
