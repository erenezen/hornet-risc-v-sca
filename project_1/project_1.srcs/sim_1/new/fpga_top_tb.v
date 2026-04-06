`timescale 1ns/1ps

module fpga_top_tb;

  localparam CLK_FREQ_HZ  = 40_000_000;
  localparam BAUD_RATE    = 115200;
  localparam CLKS_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE/2)) / BAUD_RATE;
  localparam CLK_PERIOD   = 1000.0 / (CLK_FREQ_HZ / 1000000.0);

  reg clk = 0;
  integer access_count = 0;
  integer heartbeat = 0;
  
  // Core Debug Signals - CORRECTED PATHS
  wire [31:0] debug_pc   = dut.core0.instr_addr_o;
  wire        stall_IF   = dut.core0.core0.stall_IF;
  wire        stall_ID   = dut.core0.core0.stall_ID;
  wire        stall_EX   = dut.core0.core0.stall_EX;
  wire        data_stall = dut.core0.data_stall_i;
  
  // WB Signals
  wire        wb_cyc = dut.data_wb_cyc_o;
  wire        wb_stb = dut.data_wb_stb_o;
  wire        wb_ack = dut.data_wb_ack_i;
  wire        wb_stall = dut.data_wb_stall_i;

  always @(posedge clk) begin
    // HEARTBEAT with extensive pipeline debug
    heartbeat <= heartbeat + 1;
    if (heartbeat % 10000 == 0) begin
         $display("[HEARTBEAT] Time=%t PC=%h | Stalls: IF=%b ID=%b EX=%b Data=%b | WB: Cyc=%b Stb=%b Ack=%b Stall=%b", 
                   $time, debug_pc, stall_IF, stall_ID, stall_EX, data_stall, 
                   wb_cyc, wb_stb, wb_ack, wb_stall);
    end

    // Detailed WB Trace
    if (wb_cyc && wb_stb) begin
      access_count <= access_count + 1;
      if (access_count < 20) begin
        if (dut.data_wb_we_o)
          $display("[WB WR] PC=%h Addr=%h Data=%h Sel=%b", debug_pc, dut.data_wb_adr_o, dut.data_wb_dat_o, dut.data_wb_sel_o);
        else
          $display("[WB RD] PC=%h Addr=%h Sel=%b", debug_pc, dut.data_wb_adr_o, dut.data_wb_sel_o);
      end
    end
    
    // ACK Trace
    if (wb_ack && access_count <= 20) begin
      $display("[WB ACK] Data=%h", dut.data_wb_dat_i);
    end
  end
  
  // TX Monitor
  always @(posedge clk) begin
    if (dut.u_uart.tx_start) 
        $display("[UART TX] Byte: %h ('%c')", dut.u_uart.tx_byte, 
                 (dut.u_uart.tx_byte >= 32 && dut.u_uart.tx_byte < 127) ? dut.u_uart.tx_byte : 8'h3F);
  end
  
  reg  reset = 1;
  reg  rx_i  = 1;
  wire tx_o;
  wire led1, led2, led4;

  always #(CLK_PERIOD/2) clk = ~clk;

  fpga_top #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ)
  ) dut (
    .M100_clk_i(clk),
    .reset_i   (reset),
    .rx_i      (rx_i),
    .tx_o      (tx_o),
    .led1      (led1),
    .led2      (led2),
    .led4      (led4)
  );

  initial begin
    $display("[TB] Simulation Started");
    reset = 1;
    #200;
    reset = 0;
    $display("[TB] Reset Released");

    #20000000;
    $display("[TB] Done");
    $finish;
  end

endmodule
