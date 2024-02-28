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
        
        int fd;

        forever begin

            wait (exit_val[0]);

            fd = $fopen("result.rpt", "w");

            if (exit_val) begin
                $fdisplay(fd, "return code: 0x%x", (exit_val >> 1));
            end

            $fclose(fd);

            $finish();
        end
    end

    // Memory initialisation

    initial begin
        integer file;
        integer error;
        static string  mem_init_file = "main.hex";
        static string  instr_init_file = "main_instr.hex";
        static string  data_init_file = "main_data.hex";

        @(negedge rst);
        #2

        `ifdef USE_XILINX_SRAM
            $readmemh(mem_init_file, i_culsans.i_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem);
        `else
            $readmemh(mem_init_file, i_culsans.i_sram.i_tc_sram.sram);
        `endif
        //end
    end

    // DUT

    culsans_top #(
        .InclSimDTM       (1'b0),
        .NUM_WORDS        (4**10), // 4Kwords
        .StallRandomInput (1'b0),
        .StallRandomOutput(1'b0),
        .FixedDelayInput  (0),
        .FixedDelayOutput (0),
        .HasLLC           (1'b0),
        .BootAddress      (culsans_pkg::DRAMBase + 64'h10_0000)
    ) i_culsans (
        .clk_i (clk),
        .rtc_i (rtc),
        .rst_ni(~rst),
        .exit_o (exit_val)
    );
    


    // ...

endmodule
