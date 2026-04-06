`timescale 1ns/1ps
// Force Recompile 1

module fpga_top #(
  parameter integer CLK_FREQ_HZ = 20_000_000
)(
    input  wire M100_clk_i,
    input  wire reset_i,
    input  wire rx_i,
    output wire tx_o,
    output wire led1, led2, led4
);

  // Clock Generation
  reg [2:0] clk_div = 0;
  always @(posedge M100_clk_i) begin
    if (clk_div == 4) clk_div <= 0;
    else              clk_div <= clk_div + 1;
  end
  
  reg clk_20mhz_raw;
  always @(posedge M100_clk_i) begin
      if (clk_div < 2) clk_20mhz_raw <= 1'b1;
      else             clk_20mhz_raw <= 1'b0;
  end

  wire clk;
  generate
    if (CLK_FREQ_HZ == 40_000_000) assign clk = M100_clk_i;
    else                           assign clk = clk_20mhz_raw;
  endgenerate

  // Reset Logic
  wire loader_rstn;
  wire reset;
  assign reset = loader_rstn & reset_i; 
  wire rst_hi = reset_i;

  // WISHBONE SINYALLERI
  wire        data_wb_cyc_o;
  wire        data_wb_stb_o;
  wire        data_wb_we_o;
  wire [31:0] data_wb_adr_o;
  wire [31:0] data_wb_dat_o;
  wire [3:0]  data_wb_sel_o;
  wire        data_wb_stall_i;
  wire        data_wb_ack_i;
  wire [31:0] data_wb_dat_i;
  wire        data_wb_err_i;

  wire        mtip;
  wire        rx_irq_o;
  wire [7:0]  rx_byte;
  wire        irq_ack_o;

  // CORE
  core_wb #(
    .reset_vector(32'h0000_7400),
    .MEMFILE("C:/Users/eren/Desktop/kurtarmalar/kurtarma2/project_1/project_1.srcs/sources_1/imports/fw_hello_uart/sca_attack.mem")
  ) core0 (
    .reset_i         (rst_hi | ~loader_rstn),
    .clk_i           (clk),
    .data_wb_cyc_o   (data_wb_cyc_o),
    .data_wb_stb_o   (data_wb_stb_o),
    .data_wb_we_o    (data_wb_we_o),
    .data_wb_adr_o   (data_wb_adr_o),
    .data_wb_dat_o   (data_wb_dat_o),
    .data_wb_sel_o   (data_wb_sel_o),
    .data_wb_stall_i (data_wb_stall_i),
    .data_wb_ack_i   (data_wb_ack_i),
    .data_wb_dat_i   (data_wb_dat_i),
    .data_wb_err_i   (data_wb_err_i),
    .data_wb_rst_i   (rst_hi | ~loader_rstn),
    .data_wb_clk_i   (clk),
    .meip_i          (1'b0),
    .mtip_i          (mtip),
    .msip_i          (1'b0),
    .fast_irq_i      ({15'b0, rx_irq_o}),
    .irq_ack_o       (irq_ack_o)
  );

  // ============= SIMPLIFIED ADDRESS DECODER =============
  // Use lower 16 bits for decoding, ignore upper bits (firmware uses 0x3D1xxx etc)
  wire [15:0] addr_lo = data_wb_adr_o[15:0];
  
  // UART: 0x03F8-0x03FF OR 0x8010-0x8017
  wire sel_uart  = ((addr_lo >= 16'h03F8) && (addr_lo <= 16'h03FF)) ||
                   ((addr_lo >= 16'h8010) && (addr_lo <= 16'h8017));
  
  // ROM: 0x7400-0xF3FF
  wire sel_rom   = (addr_lo >= 16'h7400) && (addr_lo <= 16'hF3FF) && !sel_uart;
  
  // MTIME: 0x0800-0x080F  
  wire sel_mtime = (addr_lo >= 16'h0800) && (addr_lo <= 16'h080F);
  
  // LOADER: 0x8018-0x801B
  wire sel_loader = (addr_lo >= 16'h8018) && (addr_lo <= 16'h801B);
  
  // MEMORY: everything else (RAM + stack)
  wire sel_mem   = !sel_uart && !sel_rom && !sel_mtime && !sel_loader;

  wire wb_cyc_mem    = data_wb_cyc_o & sel_mem;   wire wb_stb_mem    = data_wb_stb_o & sel_mem;
  wire wb_cyc_rom    = data_wb_cyc_o & sel_rom;   wire wb_stb_rom    = data_wb_stb_o & sel_rom;
  wire wb_cyc_mtime  = data_wb_cyc_o & sel_mtime; wire wb_stb_mtime  = data_wb_stb_o & sel_mtime;
  wire wb_cyc_uart   = data_wb_cyc_o & sel_uart;  wire wb_stb_uart   = data_wb_stb_o & sel_uart;
  wire wb_cyc_loader = data_wb_cyc_o & sel_loader;wire wb_stb_loader = data_wb_stb_o & sel_loader;

  wire [31:0] dati_mem, dati_rom, dati_mtime, dati_uart, dati_loader;
  wire ack_mem, ack_rom, ack_mtime, ack_uart, ack_loader;
  wire stall_mem, stall_rom, stall_mtime, stall_uart, stall_loader;
  wire err_mem, err_rom, err_mtime, err_uart, err_loader;

  wire [31:0] wb_adr_masked = {16'h0000, addr_lo};

  assign data_wb_dat_i = sel_mem ? dati_mem : sel_rom ? dati_rom : sel_mtime ? dati_mtime : sel_uart ? dati_uart : sel_loader ? dati_loader : 32'h0;
  assign data_wb_ack_i = (sel_mem & ack_mem) | (sel_rom & ack_rom) | (sel_mtime & ack_mtime) | (sel_uart & ack_uart) | (sel_loader & ack_loader);
  assign data_wb_stall_i = (sel_mem & stall_mem) | (sel_rom & stall_rom) | (sel_mtime & stall_mtime) | (sel_uart & stall_uart) | (sel_loader & stall_loader);
  assign data_wb_err_i = (sel_mem & err_mem) | (sel_rom & err_rom) | (sel_mtime & err_mtime) | (sel_uart & err_uart) | (sel_loader & err_loader);

  memory_2rw_wb #(.MEMFILE ("C:/Users/eren/Desktop/kurtarmalar/kurtarma2/project_1/project_1.srcs/sources_1/imports/fw_hello_uart/sca_attack.mem"), .ADDR_WIDTH(13)) u_dmem (
    .wb_cyc_i(wb_cyc_mem), .wb_stb_i(wb_stb_mem), .wb_we_i(data_wb_we_o), .wb_adr_i(wb_adr_masked), .wb_dat_i(data_wb_dat_o), .wb_sel_i(data_wb_sel_o),
    .wb_stall_o(stall_mem), .wb_ack_o(ack_mem), .wb_dat_o(dati_mem), .wb_err_o(err_mem), .wb_rst_i(rst_hi), .wb_clk_i(clk)
  );

  rom_ro_wb #(.MEMFILE("C:/Users/eren/Desktop/kurtarmalar/kurtarma2/project_1/project_1.srcs/sources_1/imports/fw_hello_uart/sca_attack.mem"), .BASE_ADDR(32'h0000_7400), .WORDS(8192)) u_rom (
    .wb_cyc_i(wb_cyc_rom), .wb_stb_i(wb_stb_rom), .wb_we_i(1'b0), .wb_adr_i(wb_adr_masked), .wb_sel_i(data_wb_sel_o), .wb_dat_i(32'h0),
    .wb_stall_o(stall_rom), .wb_ack_o(ack_rom), .wb_dat_o(dati_rom), .wb_err_o(err_rom), .wb_rst_i(rst_hi), .wb_clk_i(clk)
  );

  mtime_registers_wb u_mtime (
    .wb_cyc_i(wb_cyc_mtime), .wb_stb_i(wb_stb_mtime), .wb_we_i(data_wb_we_o), .wb_adr_i(wb_adr_masked), .wb_dat_i(data_wb_dat_o), .wb_sel_i(data_wb_sel_o),
    .wb_stall_o(stall_mtime), .wb_ack_o(ack_mtime), .wb_dat_o(dati_mtime), .wb_err_o(err_mtime), .wb_rst_i(rst_hi), .wb_clk_i(clk), .mtip_o(mtip)
  );

  uart_wb #(.SYS_CLK_FREQ(CLK_FREQ_HZ), .BAUD(115200)) u_uart (
    .wb_cyc_i(wb_cyc_uart), .wb_stb_i(wb_stb_uart), .wb_we_i(data_wb_we_o), .wb_adr_i(wb_adr_masked), .wb_dat_i(data_wb_dat_o), .wb_sel_i(data_wb_sel_o),
    .wb_stall_o(stall_uart), .wb_ack_o(ack_uart), .wb_dat_o(dati_uart), .wb_err_o(err_uart), .wb_rst_i(rst_hi), .wb_clk_i(clk),
    .rx_i(rx_i), .tx_o(tx_o), .rx_byte_o(rx_byte), .rx_irq_o(rx_irq_o)
  );

  loader_wb #(.SYS_CLK_FREQ(CLK_FREQ_HZ)) u_loader (
    .wb_cyc_i(wb_cyc_loader), .wb_stb_i(wb_stb_loader), .wb_we_i(data_wb_we_o), .wb_adr_i(wb_adr_masked), .wb_dat_i(data_wb_dat_o), .wb_sel_i(data_wb_sel_o),
    .wb_stall_o(stall_loader), .wb_ack_o(ack_loader), .wb_dat_o(dati_loader), .wb_err_o(err_loader), .wb_rst_i(rst_hi), .wb_clk_i(clk),
    .uart_rx_byte(rx_byte), .uart_rx_irq(rx_irq_o), .reset_o(loader_rstn), .led1(led1), .led2(led2), .led4(led4)
  );

endmodule




