`timescale 1ns/1ps
// Wishbone Read-Only ROM: Basic 32-bit distributed ROM for synthesis
module rom_ro_wb #(
  parameter MEMFILE   = "uart_main.mem",
  parameter BASE_ADDR = 32'h00007400,
  parameter WORDS     = 8192,
  parameter MEM_BYTES = 128*1024
)(
  input  wb_cyc_i, input wb_stb_i, input wb_we_i,
  input  [31:0] wb_adr_i, input [3:0] wb_sel_i, input [31:0] wb_dat_i,
  output wb_stall_o, output reg wb_ack_o, output reg [31:0] wb_dat_o,
  output wb_err_o, input wb_rst_i, input wb_clk_i
);

  // Basit 32-bit ROM (Vivado Synthesis uyumlu)
  (* rom_style = "distributed" *)
  reg [31:0] rom [0:WORDS-1];

  initial begin
    $display("ROMRO: loading %s ...", MEMFILE);
    $readmemh(MEMFILE, rom);
  end

  assign wb_stall_o = 1'b0;
  assign wb_err_o   = 1'b0;

  wire hit        = (wb_adr_i >= BASE_ADDR) && (wb_adr_i < (BASE_ADDR + MEM_BYTES));
  // Word-aligned index
  wire [11:0] word_idx = (wb_adr_i - BASE_ADDR) >> 2;

  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
      wb_ack_o <= 1'b0; 
      wb_dat_o <= 32'h0;
    end else begin
      wb_ack_o <= 1'b0;
      if (wb_cyc_i & wb_stb_i & hit) begin
        wb_ack_o <= 1'b1;
        // Return full word. CPU handles byte selection via masking if needed.
        wb_dat_o <= rom[word_idx];
      end
    end
  end

endmodule
