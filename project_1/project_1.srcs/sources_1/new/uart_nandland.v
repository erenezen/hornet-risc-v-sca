`timescale 1ns/1ps

// Basit Nandland tarzı UART TX/RX modülleri
// Arayüzler mevcut tasarımdaki instantiation'larla bire bir uyumludur.

// ------------------------------------------------------------
// UART_TX
//   Girdi  : i_Rst_L   (aktif-düşük senkron reset)
//            i_Clock   (sistem saati)
//            i_TX_DV   (tek-clock "data valid" pulu)
//            i_TX_Byte (gönderilecek 8‑bit veri)
//   Çıktı  : o_TX_Active (gönderim sırasında 1)
//            o_TX_Serial (UART TX hattı)
//            o_TX_Done   (gönderim bittiğinde tek-clock pulse)
// ------------------------------------------------------------
module UART_TX #(
  parameter integer CLKS_PER_BIT = 434  // saat/baud oranı
)(
  input        i_Rst_L,
  input        i_Clock,
  input        i_TX_DV,
  input  [7:0] i_TX_Byte,
  output reg   o_TX_Active = 1'b0,
  output reg   o_TX_Serial = 1'b1,
  output reg   o_TX_Done   = 1'b0
);

  localparam [2:0]
    IDLE       = 3'd0,
    START_BIT  = 3'd1,
    DATA_BITS  = 3'd2,
    STOP_BIT   = 3'd3,
    CLEANUP    = 3'd4;

  reg [2:0] r_State        = IDLE;
  reg [15:0] r_Clock_Count = 0;
  reg [2:0]  r_Bit_Index   = 0;
  reg [7:0]  r_TX_Data     = 0;

  always @(posedge i_Clock) begin
    if (!i_Rst_L) begin
      r_State        <= IDLE;
      r_Clock_Count  <= 0;
      r_Bit_Index    <= 0;
      o_TX_Serial    <= 1'b1;
      o_TX_Active    <= 1'b0;
      o_TX_Done      <= 1'b0;
      r_TX_Data      <= 8'h00;
    end else begin
      o_TX_Done <= 1'b0; // default

      case (r_State)
        IDLE: begin
          o_TX_Serial <= 1'b1;
          o_TX_Active <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;

          if (i_TX_DV) begin
            o_TX_Active <= 1'b1;
            r_TX_Data   <= i_TX_Byte;
            r_State     <= START_BIT;
          end
        end

        START_BIT: begin
          o_TX_Serial <= 1'b0;  // start bit
          if (r_Clock_Count == CLKS_PER_BIT-1) begin
            r_Clock_Count <= 0;
            r_State       <= DATA_BITS;
          end else begin
            r_Clock_Count <= r_Clock_Count + 1;
          end
        end

        DATA_BITS: begin
          o_TX_Serial <= r_TX_Data[r_Bit_Index];

          if (r_Clock_Count == CLKS_PER_BIT-1) begin
            r_Clock_Count <= 0;

            if (r_Bit_Index == 3'd7) begin
              r_Bit_Index <= 0;
              r_State     <= STOP_BIT;
            end else begin
              r_Bit_Index <= r_Bit_Index + 1;
            end
          end else begin
            r_Clock_Count <= r_Clock_Count + 1;
          end
        end

        STOP_BIT: begin
          o_TX_Serial <= 1'b1;  // stop bit
          if (r_Clock_Count == CLKS_PER_BIT-1) begin
            r_Clock_Count <= 0;
            r_State       <= CLEANUP;
          end else begin
            r_Clock_Count <= r_Clock_Count + 1;
          end
        end

        CLEANUP: begin
          o_TX_Active <= 1'b0;
          o_TX_Done   <= 1'b1;
          r_State     <= IDLE;
        end

        default: r_State <= IDLE;
      endcase
    end
  end

endmodule


// ------------------------------------------------------------
// UART_RX
//   Girdi  : i_Rst_L    (aktif-düşük reset)
//            i_Clock    (sistem saati)
//            i_RX_Serial(UART RX hattı)
//   Çıktı  : o_RX_DV    (tek-clock "data valid" pulu)
//            o_RX_Byte  (alınan 8‑bit veri)
// ------------------------------------------------------------
module UART_RX #(
  parameter integer CLKS_PER_BIT = 434
)(
  input        i_Rst_L,
  input        i_Clock,
  input        i_RX_Serial,
  output reg   o_RX_DV,
  output reg [7:0] o_RX_Byte
);

  localparam [2:0]
    IDLE        = 3'd0,
    START_BIT   = 3'd1,
    DATA_BITS   = 3'd2,
    STOP_BIT    = 3'd3,
    CLEANUP     = 3'd4;

  reg [2:0]  r_State        = IDLE;
  reg [15:0] r_Clock_Count  = 0;
  reg [2:0]  r_Bit_Index    = 0;
  reg [7:0]  r_RX_Byte      = 0;
  reg        r_RX_Data      = 1'b1;

  // basit senkronizasyon (tek flop yeterli)
  always @(posedge i_Clock) begin
    r_RX_Data <= i_RX_Serial;
  end

  always @(posedge i_Clock) begin
    if (!i_Rst_L) begin
      r_State       <= IDLE;
      r_Clock_Count <= 0;
      r_Bit_Index   <= 0;
      o_RX_DV       <= 1'b0;
      o_RX_Byte     <= 8'h00;
      r_RX_Byte     <= 8'h00;
    end else begin
      o_RX_DV <= 1'b0; // default

      case (r_State)
        IDLE: begin
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          if (r_RX_Data == 1'b0) begin  // start bit bekleniyor
            r_State <= START_BIT;
          end
        end

        START_BIT: begin
          if (r_Clock_Count == (CLKS_PER_BIT/2)) begin
            // start bit'in ortasından örnekle
            if (r_RX_Data == 1'b0) begin
              r_Clock_Count <= 0;
              r_State       <= DATA_BITS;
            end else begin
              r_State <= IDLE; // gürültü
            end
          end else begin
            r_Clock_Count <= r_Clock_Count + 1;
          end
        end

        DATA_BITS: begin
          if (r_Clock_Count == CLKS_PER_BIT-1) begin
            r_Clock_Count         <= 0;
            r_RX_Byte[r_Bit_Index] <= r_RX_Data;

            if (r_Bit_Index == 3'd7) begin
              r_Bit_Index <= 0;
              r_State     <= STOP_BIT;
            end else begin
              r_Bit_Index <= r_Bit_Index + 1;
            end
          end else begin
            r_Clock_Count <= r_Clock_Count + 1;
          end
        end

        STOP_BIT: begin
          if (r_Clock_Count == CLKS_PER_BIT-1) begin
            r_Clock_Count <= 0;
            o_RX_Byte     <= r_RX_Byte;
            o_RX_DV       <= 1'b1;
            r_State       <= CLEANUP;
          end else begin
            r_Clock_Count <= r_Clock_Count + 1;
          end
        end

        CLEANUP: begin
          r_State <= IDLE;
        end

        default: r_State <= IDLE;
      endcase
    end
  end

endmodule


