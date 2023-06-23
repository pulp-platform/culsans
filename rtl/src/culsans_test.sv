// non synthesisable ace master logger module
// this module logs the activity of the input axi channel
// the log files will be found in "./ace_log/<LoggerName>/"
// one log file for all writes
// a log file per id for the reads
// atomic transactions with read response are injected into the corresponding log file of the read
module ccu_master_logger #(
  parameter time TestTime     = 8ns,          // Time after clock, where sampling happens
  parameter string LoggerName = "ace_logger", // name of the logger
  parameter type aw_chan_t    = logic,        // axi AW type
  parameter type  w_chan_t    = logic,        // axi  W type
  parameter type  b_chan_t    = logic,        // axi  B type
  parameter type ar_chan_t    = logic,        // axi AR type
  parameter type  r_chan_t    = logic         // axi  R type
) (
  input logic     clk_i,     // Clock
  input logic     rst_ni,    // Asynchronous reset active low, when `1'b0` no sampling
  input logic     end_sim_i, // end of simulation
  // AW channel
  input aw_chan_t aw_chan_i,
  input logic     aw_valid_i,
  input logic     aw_ready_i,
  //  W channel
  input w_chan_t  w_chan_i,
  input logic     w_valid_i,
  input logic     w_ready_i,
  //  B channel
  input b_chan_t  b_chan_i,
  input logic     b_valid_i,
  input logic     b_ready_i,
  // AR channel
  input ar_chan_t ar_chan_i,
  input logic     ar_valid_i,
  input logic     ar_ready_i,
  //  R channel
  input r_chan_t  r_chan_i,
  input logic     r_valid_i,
  input logic     r_ready_i
);

 typedef ariane_axi::id_t  id;
  // id width from channel
  localparam int unsigned IdWidth = $bits(id);
  localparam int unsigned NoIds   = 2**IdWidth;

  // queues for writes and reads
  aw_chan_t aw_queue[$];
  w_chan_t  w_queue[$];
  b_chan_t  b_queue[$];
  aw_chan_t ar_queues[NoIds-1:0][$];
  r_chan_t  r_queues[NoIds-1:0][$];

  // channel sampling into queues
  always @(posedge clk_i) #TestTime begin : proc_channel_sample
    automatic aw_chan_t ar_beat;
    automatic int       fd;
    automatic string    log_file;
    automatic string    log_str;
    // only execute when reset is high
    if (rst_ni) begin
      // AW channel
      if (aw_valid_i && aw_ready_i) begin
        aw_queue.push_back(aw_chan_i);
        log_file = $sformatf("./ace_log/%s/write.log", LoggerName);
        fd = $fopen(log_file, "a");
        if (fd) begin
          log_str = $sformatf("%0t> ID: %h AW on channel: ADDR: 0x%h LEN: %d, ATOP: %b, AWSNOOP:%b, AWBAR:%b, AWDOMAIN:%b",
                        $time, aw_chan_i.id, aw_chan_i.addr, aw_chan_i.len, aw_chan_i.atop, aw_chan_i.snoop, aw_chan_i.bar, aw_chan_i.domain);
          $fdisplay(fd, log_str);
          $fclose(fd);
        end

        // inject AR into queue, if there is an atomic
        if (aw_chan_i.atop[axi_pkg::ATOP_R_RESP]) begin
          $display("Atomic detected with response");
          ar_beat.id     = aw_chan_i.id;
          ar_beat.addr   = aw_chan_i.addr;
          if (aw_chan_i.len > 1) begin
            ar_beat.len    = aw_chan_i.len / 2;
          end else begin
            ar_beat.len    = aw_chan_i.len;
          end
          ar_beat.size   = aw_chan_i.size;
          ar_beat.burst  = aw_chan_i.burst;
          ar_beat.lock   = aw_chan_i.lock;
          ar_beat.cache  = aw_chan_i.cache;
          ar_beat.prot   = aw_chan_i.prot;
          ar_beat.qos    = aw_chan_i.qos;
          ar_beat.region = aw_chan_i.region;
          ar_beat.atop   = aw_chan_i.atop;
          ar_beat.user   = aw_chan_i.user;
          ar_beat.snoop  = aw_chan_i.snoop;
          ar_beat.bar    = aw_chan_i.bar;
          ar_beat.domain = aw_chan_i.domain;

          ar_queues[aw_chan_i.id].push_back(ar_beat);
          log_file = $sformatf("./ace_log/%s/read_%0h.log", LoggerName, aw_chan_i.id);
          fd = $fopen(log_file, "a");
          if (fd) begin
            log_str = $sformatf("%0t> ID: %h AR on channel: ADDR: 0x%h LEN: %d injected ATOP: %b, ARSNOOP:%b, ARBAR:%b, ARDOMAIN:%b",
                          $time, ar_beat.id, ar_beat.addr, ar_beat.len, ar_beat.atop, ar_beat.snoop, ar_beat.bar, ar_beat.domain);
            $fdisplay(fd, log_str);
            $fclose(fd);
          end
        end
      end
      // W channel
      if (w_valid_i && w_ready_i) begin
        w_queue.push_back(w_chan_i);
      end
      // B channel
      if (b_valid_i && b_ready_i) begin
        b_queue.push_back(b_chan_i);
      end
      // AR channel
      if (ar_valid_i && ar_ready_i) begin
        log_file = $sformatf("./ace_log/%s/read_%0h.log", LoggerName, ar_chan_i.id);
        fd = $fopen(log_file, "a");
        if (fd) begin
          log_str = $sformatf("%0t> ID: %h AR on channel: ADDR: 0x%h LEN: %d, ARSNOOP:%b, ARBAR:%b, ARDOMAIN:%b",
                          $time, ar_chan_i.id, ar_chan_i.addr, ar_chan_i.len, ar_chan_i.snoop, ar_chan_i.bar, ar_chan_i.domain);
          $fdisplay(fd, log_str);
          $fclose(fd);
        end
        ar_beat.id     = ar_chan_i.id;
        ar_beat.addr   = ar_chan_i.addr;
        ar_beat.len    = ar_chan_i.len;
        ar_beat.size   = ar_chan_i.size;
        ar_beat.burst  = ar_chan_i.burst;
        ar_beat.lock   = ar_chan_i.lock;
        ar_beat.cache  = ar_chan_i.cache;
        ar_beat.prot   = ar_chan_i.prot;
        ar_beat.qos    = ar_chan_i.qos;
        ar_beat.region = ar_chan_i.region;
        ar_beat.atop   = '0;
        ar_beat.user   = ar_chan_i.user;
        ar_beat.snoop  = ar_chan_i.snoop;
        ar_beat.bar    = ar_chan_i.bar;
        ar_beat.domain = ar_chan_i.domain;
        ar_queues[ar_chan_i.id].push_back(ar_beat);
      end
      // R channel
      if (r_valid_i && r_ready_i) begin
        r_queues[r_chan_i.id].push_back(r_chan_i);
      end
    end
  end

  initial begin : proc_log
    automatic string       log_name;
    automatic string       log_string;
    automatic aw_chan_t    aw_beat;
    automatic w_chan_t     w_beat;
    automatic int unsigned no_w_beat = 0;
    automatic b_chan_t     b_beat;
    automatic aw_chan_t    ar_beat;
    automatic r_chan_t     r_beat;
    automatic int unsigned no_r_beat[NoIds];
    automatic int          fd;

    // init r counter
    for (int unsigned i = 0; i < NoIds; i++) begin
      no_r_beat[i] = 0;
    end

    // make the log dirs
    log_name = $sformatf("mkdir -p ./ace_log/%s/", LoggerName);
    $system(log_name);

    // open log files
    log_name = $sformatf("./ace_log/%s/write.log", LoggerName);
    fd = $fopen(log_name, "w");
    if (fd) begin
      $display("File was opened successfully : %0d", fd);
      $fdisplay(fd, "This is the write log file");
      $fclose(fd);
    end else
      $display("File was NOT opened successfully : %0d", fd);
    for (int unsigned i = 0; i < NoIds; i++) begin
      log_name = $sformatf("./ace_log/%s/read_%0h.log", LoggerName, i);
      fd = $fopen(log_name, "w");
      if (fd) begin
        $display("File was opened successfully : %0d", fd);
        $fdisplay(fd, "This is the read log file for ID: %0h", i);
        $fclose(fd);
      end else
        $display("File was NOT opened successfully : %0d", fd);
    end

    // on each clock cycle update the logs if there is something in the queues
    wait (rst_ni);
    while (!end_sim_i) begin
      @(posedge clk_i);

      // update the write log file
      while (aw_queue.size() != 0 && w_queue.size() != 0) begin
        aw_beat = aw_queue[0];
        w_beat  = w_queue.pop_front();

        log_string = $sformatf("%0t> ID: %h W %d of %d, ADDR: 0x%h LAST: %b ATOP: %b",
                        $time, aw_beat.id, no_w_beat, aw_beat.len, aw_beat.addr, w_beat.last, aw_beat.atop);

        log_name = $sformatf("./ace_log/%s/write.log", LoggerName);
        fd = $fopen(log_name, "a");
        if (fd) begin
          $fdisplay(fd, log_string);
          // write out error if last beat does not match!
          if (w_beat.last && !(aw_beat.len == no_w_beat)) begin
            $fdisplay(fd, "ERROR> Last flag was not expected!!!!!!!!!!!!!");
          end
          $fclose(fd);
        end
        // pop the AW if the last flag is set
        no_w_beat++;
        if (w_beat.last) begin
          aw_beat = aw_queue.pop_front();
          no_w_beat = 0;
        end
      end

      // check b queue
      if (b_queue.size() != 0) begin
        b_beat = b_queue.pop_front();
        log_string = $sformatf("%0t> ID: %h B recieved",
                        $time, b_beat.id);
        log_name = $sformatf("./ace_log/%s/write.log", LoggerName);
        fd = $fopen(log_name, "a");
        if (fd) begin
          $fdisplay(fd, log_string);
          $fclose(fd);
        end
      end

      // update the read log files
      for (int unsigned i = 0; i < NoIds; i++) begin
        while (ar_queues[i].size() != 0 && r_queues[i].size() != 0) begin
          ar_beat = ar_queues[i][0];
          r_beat  = r_queues[i].pop_front();

          log_name = $sformatf("./ace_log/%s/read_%0h.log", LoggerName, i);
          fd = $fopen(log_name, "a");
          if (fd) begin
            log_string = $sformatf("%0t> ID: %h R %d of %d, ADDR: 0x%h LAST: %b ATOP: %b",
                            $time, r_beat.id, no_r_beat[i], ar_beat.len, ar_beat.addr, r_beat.last, ar_beat.atop);

            $fdisplay(fd, log_string);
            // write out error if last beat does not match!
            if (r_beat.last && !(ar_beat.len == no_r_beat[i])) begin
              $fdisplay(fd, "ERROR> Last flag was not expected!!!!!!!!!!!!!");
            end
            $fclose(fd);
          end
          no_r_beat[i]++;
          // pop the queue if it is the last flag
          if (r_beat.last) begin
            ar_beat = ar_queues[i].pop_front();
            no_r_beat[i] = 0;
          end
        end
      end
    end
    $fclose(fd);
  end
endmodule

// non synthesisable axi slave logger module
// this module logs the activity of the input axi channel
// the log files will be found in "./axi_log/<LoggerName>/"
// one log file for all writes
// a log file per id for the reads
// atomic transactions with read response are injected into the corresponding log file of the read
module ccu_slave_logger #(
  parameter time TestTime     = 8ns,          // Time after clock, where sampling happens
  parameter string LoggerName = "axi_logger", // name of the logger
  parameter type aw_chan_t    = logic,        // axi AW type
  parameter type  w_chan_t    = logic,        // axi  W type
  parameter type  b_chan_t    = logic,        // axi  B type
  parameter type ar_chan_t    = logic,        // axi AR type
  parameter type  r_chan_t    = logic         // axi  R type
) (
  input logic     clk_i,     // Clock
  input logic     rst_ni,    // Asynchronous reset active low, when `1'b0` no sampling
  input logic     end_sim_i, // end of simulation
  // AW channel
  input aw_chan_t aw_chan_i,
  input logic     aw_valid_i,
  input logic     aw_ready_i,
  //  W channel
  input w_chan_t  w_chan_i,
  input logic     w_valid_i,
  input logic     w_ready_i,
  //  B channel
  input b_chan_t  b_chan_i,
  input logic     b_valid_i,
  input logic     b_ready_i,
  // AR channel
  input ar_chan_t ar_chan_i,
  input logic     ar_valid_i,
  input logic     ar_ready_i,
  //  R channel
  input r_chan_t  r_chan_i,
  input logic     r_valid_i,
  input logic     r_ready_i
);

  typedef ariane_axi::id_t  id;
  // id width from channel
  localparam int unsigned IdWidth = $bits(id);
  localparam int unsigned NoIds   = 2**IdWidth;

  // queues for writes and reads
  aw_chan_t aw_queue[$];
  w_chan_t  w_queue[$];
  b_chan_t  b_queue[$];
  aw_chan_t ar_queues[NoIds-1:0][$];
  r_chan_t  r_queues[NoIds-1:0][$];

  // channel sampling into queues
  always @(posedge clk_i) #TestTime begin : proc_channel_sample
    automatic aw_chan_t ar_beat;
    automatic int       fd;
    automatic string    log_file;
    automatic string    log_str;
    // only execute when reset is high
    if (rst_ni) begin
      // AW channel
      if (aw_valid_i && aw_ready_i) begin
        aw_queue.push_back(aw_chan_i);
        log_file = $sformatf("./axi_log/%s/write.log", LoggerName);
        fd = $fopen(log_file, "a");
        if (fd) begin
          log_str = $sformatf("%0t> ID: %h AW on channel: ADDR: 0x%h LEN: %d, ATOP: %b",
                        $time, aw_chan_i.id, aw_chan_i.addr, aw_chan_i.len, aw_chan_i.atop);
          $fdisplay(fd, log_str);
          $fclose(fd);
        end

        // inject AR into queue, if there is an atomic
        if (aw_chan_i.atop[axi_pkg::ATOP_R_RESP]) begin
          $display("Atomic detected with response");
          ar_beat.id     = aw_chan_i.id;
          ar_beat.addr   = aw_chan_i.addr;
          if (aw_chan_i.len > 1) begin
            ar_beat.len    = aw_chan_i.len / 2;
          end else begin
            ar_beat.len    = aw_chan_i.len;
          end
          ar_beat.size   = aw_chan_i.size;
          ar_beat.burst  = aw_chan_i.burst;
          ar_beat.lock   = aw_chan_i.lock;
          ar_beat.cache  = aw_chan_i.cache;
          ar_beat.prot   = aw_chan_i.prot;
          ar_beat.qos    = aw_chan_i.qos;
          ar_beat.region = aw_chan_i.region;
          ar_beat.atop   = aw_chan_i.atop;
          ar_beat.user   = aw_chan_i.user;
          ar_queues[aw_chan_i.id].push_back(ar_beat);
          log_file = $sformatf("./axi_log/%s/read_%0h.log", LoggerName, aw_chan_i.id);
          fd = $fopen(log_file, "a");
          if (fd) begin
            log_str = $sformatf("%0t> ID: %h AR on channel: ADDR:0x%h LEN: %d injected ATOP: %b",
                          $time, ar_beat.id, ar_beat.addr, ar_beat.len, ar_beat.atop);
            $fdisplay(fd, log_str);
            $fclose(fd);
          end
        end
      end
      // W channel
      if (w_valid_i && w_ready_i) begin
        w_queue.push_back(w_chan_i);
      end
      // B channel
      if (b_valid_i && b_ready_i) begin
        b_queue.push_back(b_chan_i);
      end
      // AR channel
      if (ar_valid_i && ar_ready_i) begin
        log_file = $sformatf("./axi_log/%s/read_%0h.log", LoggerName, ar_chan_i.id);
        fd = $fopen(log_file, "a");
        if (fd) begin
          log_str = $sformatf("%0t> ID: %h AR on channel: ADDR: 0x%h LEN: %d",
                          $time, ar_chan_i.id, ar_chan_i.addr, ar_chan_i.len);
          $fdisplay(fd, log_str);
          $fclose(fd);
        end
        ar_beat.id     = ar_chan_i.id;
        ar_beat.addr   = ar_chan_i.addr;
        ar_beat.len    = ar_chan_i.len;
        ar_beat.size   = ar_chan_i.size;
        ar_beat.burst  = ar_chan_i.burst;
        ar_beat.lock   = ar_chan_i.lock;
        ar_beat.cache  = ar_chan_i.cache;
        ar_beat.prot   = ar_chan_i.prot;
        ar_beat.qos    = ar_chan_i.qos;
        ar_beat.region = ar_chan_i.region;
        ar_beat.atop   = '0;
        ar_beat.user   = ar_chan_i.user;
        ar_queues[ar_chan_i.id].push_back(ar_beat);
      end
      // R channel
      if (r_valid_i && r_ready_i) begin
        r_queues[r_chan_i.id].push_back(r_chan_i);
      end
    end
  end

  initial begin : proc_log
    automatic string       log_name;
    automatic string       log_string;
    automatic aw_chan_t    aw_beat;
    automatic w_chan_t     w_beat;
    automatic int unsigned no_w_beat = 0;
    automatic b_chan_t     b_beat;
    automatic aw_chan_t    ar_beat;
    automatic r_chan_t     r_beat;
    automatic int unsigned no_r_beat[NoIds];
    automatic int          fd;

    // init r counter
    for (int unsigned i = 0; i < NoIds; i++) begin
      no_r_beat[i] = 0;
    end

    // make the log dirs
    log_name = $sformatf("mkdir -p ./axi_log/%s/", LoggerName);
    $system(log_name);

    // open log files
    log_name = $sformatf("./axi_log/%s/write.log", LoggerName);
    fd = $fopen(log_name, "w");
    if (fd) begin
      $display("File was opened successfully : %0d", fd);
      $fdisplay(fd, "This is the write log file");
      $fclose(fd);
    end else
      $display("File was NOT opened successfully : %0d", fd);
    for (int unsigned i = 0; i < NoIds; i++) begin
      log_name = $sformatf("./axi_log/%s/read_%0h.log", LoggerName, i);
      fd = $fopen(log_name, "w");
      if (fd) begin
        $display("File was opened successfully : %0d", fd);
        $fdisplay(fd, "This is the read log file for ID: %0h", i);
        $fclose(fd);
      end else
        $display("File was NOT opened successfully : %0d", fd);
    end

    // on each clock cycle update the logs if there is something in the queues
    wait (rst_ni);
    while (!end_sim_i) begin
      @(posedge clk_i);

      // update the write log file
      while (aw_queue.size() != 0 && w_queue.size() != 0) begin
        aw_beat = aw_queue[0];
        w_beat  = w_queue.pop_front();

        log_string = $sformatf("%0t> ID: %h  ADDR: 0x%h W %d of %d, LAST: %b ATOP: %b",
                        $time, aw_beat.id, aw_beat.addr, no_w_beat, aw_beat.len, w_beat.last, aw_beat.atop);

        log_name = $sformatf("./axi_log/%s/write.log", LoggerName);
        fd = $fopen(log_name, "a");
        if (fd) begin
          $fdisplay(fd, log_string);
          // write out error if last beat does not match!
          if (w_beat.last && !(aw_beat.len == no_w_beat)) begin
            $fdisplay(fd, "ERROR> Last flag was not expected!!!!!!!!!!!!!");
          end
          $fclose(fd);
        end
        // pop the AW if the last flag is set
        no_w_beat++;
        if (w_beat.last) begin
          aw_beat = aw_queue.pop_front();
          no_w_beat = 0;
        end
      end

      // check b queue
      if (b_queue.size() != 0) begin
        b_beat = b_queue.pop_front();
        log_string = $sformatf("%0t> ID: %h B recieved",
                        $time, b_beat.id);
        log_name = $sformatf("./axi_log/%s/write.log", LoggerName);
        fd = $fopen(log_name, "a");
        if (fd) begin
          $fdisplay(fd, log_string);
          $fclose(fd);
        end
      end

      // update the read log files
      for (int unsigned i = 0; i < NoIds; i++) begin
        while (ar_queues[i].size() != 0 && r_queues[i].size() != 0) begin
          ar_beat = ar_queues[i][0];
          r_beat  = r_queues[i].pop_front();

          log_name = $sformatf("./axi_log/%s/read_%0h.log", LoggerName, i);
          fd = $fopen(log_name, "a");
          if (fd) begin
            log_string = $sformatf("%0t> ID: %h R %d of %d, ADDR: 0x%h LAST: %b ATOP: %b",
                          $time, r_beat.id, no_r_beat[i], ar_beat.len, ar_beat.addr, r_beat.last, ar_beat.atop);
            $fdisplay(fd, log_string);
            // write out error if last beat does not match!
            if (r_beat.last && !(ar_beat.len == no_r_beat[i])) begin
              $fdisplay(fd, "ERROR> Last flag was not expected!!!!!!!!!!!!!");
            end
            $fclose(fd);
          end
          no_r_beat[i]++;
          // pop the queue if it is the last flag
          if (r_beat.last) begin
            ar_beat = ar_queues[i].pop_front();
            no_r_beat[i] = 0;
          end
        end
      end
    end
    $fclose(fd);
  end
endmodule
