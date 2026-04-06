`timescale 1ns/1ps

module uart_wb #(
    parameter integer SYS_CLK_FREQ = 100_000_000,
    parameter integer BAUD         = 9600
)(
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    input  [3:0]  wb_sel_i,
    output        wb_stall_o,
    output        wb_ack_o,
    output [31:0] wb_dat_o,
    output        wb_err_o,
    input         wb_rst_i,
    input         wb_clk_i,

    input         rx_i,
    output        tx_o,
    output [7:0]  rx_byte_o,
    output        rx_irq_o
);
  localparam integer CLKS_PER_BIT = (SYS_CLK_FREQ + (BAUD/2)) / BAUD;

  wire clk    = wb_clk_i;
  wire rst_hi = wb_rst_i;
  wire rst_lo = ~wb_rst_i;

  assign wb_stall_o = 1'b0;
  assign wb_err_o   = 1'b0;

  reg ack_q;
  always @(posedge clk or posedge rst_hi) begin
    if (rst_hi) ack_q <= 1'b0;
    else        ack_q <= (wb_cyc_i & wb_stb_i) & ~ack_q;
  end
  assign wb_ack_o = ack_q;

  wire wb_acc = wb_cyc_i & wb_stb_i & ~ack_q;
  wire wb_wr  = wb_acc & wb_we_i;
  wire wb_rd  = wb_acc & ~wb_we_i;

  // Registers
  reg [7:0] r_IER;
  reg [7:0] r_LCR; // Bit 7 is DLAB
  reg [7:0] r_MCR;
  reg [7:0] r_SCR; 
  
  // TX Logic
  reg        tx_start;
  reg [7:0] tx_byte;
  wire       tx_active, tx_done;
  reg        tx_done_latched; 
  
  // RX Logic
  wire        rx_dv;
  wire [7:0] rx_byte;
  reg [7:0]  rx_fifo;
  reg        rx_data_ready;  

  wire is_base_0 = (wb_adr_i[2] == 1'b0); // 0x3F8
  wire is_base_4 = (wb_adr_i[2] == 1'b1); // 0x3FC

  always @(posedge clk or posedge rst_hi) begin
    if (rst_hi) begin
      r_IER <= 0;
      r_LCR <= 0;
      r_MCR <= 0;
      r_SCR <= 0;
      tx_start        <= 0;
      tx_byte         <= 0;
      tx_done_latched <= 1; 
      rx_data_ready   <= 0;
    end else begin
      tx_start <= 0;

      // WRITES
      if (wb_wr) begin
        if (is_base_0) begin
           // Offset 3: LCR
           if (wb_sel_i[3]) r_LCR <= wb_dat_i[31:24];
           // Offset 1: IER
           if (wb_sel_i[1]) begin
             if (!r_LCR[7]) r_IER <= wb_dat_i[15:8];
           end
           // Offset 0: THR
           if (wb_sel_i[0]) begin
             if (!r_LCR[7]) begin
               tx_byte         <= wb_dat_i[7:0];
               tx_start        <= 1'b1;
               tx_done_latched <= 1'b0; 
             end
           end
        end
        else if (is_base_4) begin
           if (wb_sel_i[3]) r_SCR <= wb_dat_i[31:24];
           if (wb_sel_i[0]) r_MCR <= wb_dat_i[7:0];
        end
      end
      
      // READS
      if (wb_rd && is_base_0 && wb_sel_i[0] && !r_LCR[7]) begin
          rx_data_ready <= 1'b0;
      end

      if (tx_done) tx_done_latched <= 1'b1;
      if (rx_dv) begin
        rx_fifo       <= rx_byte;
        rx_data_ready <= 1'b1;
      end
    end
  end

  wire [7:0] status_byte = {2'b11, tx_done_latched, 4'b0000, rx_data_ready};

  reg [31:0] rdata;
  always @(*) begin
    rdata = 32'h0;
    if (is_base_0) begin
       if (!r_LCR[7]) rdata[7:0]   = rx_fifo;
       if (!r_LCR[7]) rdata[15:8]  = r_IER;
       rdata[23:16] = status_byte;
       rdata[31:24] = r_LCR;
    end
    else if (is_base_4) begin
       rdata[7:0]   = r_MCR;
       rdata[15:8]  = status_byte;
       rdata[23:16] = 8'h00;
       rdata[31:24] = r_SCR;
    end
  end
  assign wb_dat_o = rdata;

  assign rx_byte_o = rx_fifo;
  assign rx_irq_o  = rx_dv;

  UART_TX #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
    .i_Rst_L    (rst_lo),
    .i_Clock    (clk),
    .i_TX_DV    (tx_start),
    .i_TX_Byte  (tx_byte),
    .o_TX_Active(tx_active),
    .o_TX_Serial(tx_o),
    .o_TX_Done  (tx_done)
  );

  UART_RX #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
    .i_Rst_L    (rst_lo),
    .i_Clock    (clk),
    .i_RX_Serial(rx_i),
    .o_RX_DV    (rx_dv), 
    .o_RX_Byte  (rx_byte)
  );
endmodule