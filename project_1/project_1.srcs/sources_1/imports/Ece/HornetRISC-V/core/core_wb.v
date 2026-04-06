`timescale 1ns/1ps

module core_wb(
    input         reset_i,
    input         clk_i,

    // Wishbone interface for DATA memory
    output        data_wb_cyc_o,
    output        data_wb_stb_o,
    output        data_wb_we_o,
    output [31:0] data_wb_adr_o,
    output [31:0] data_wb_dat_o,
    output [3:0]  data_wb_sel_o,
    input         data_wb_stall_i,
    input         data_wb_ack_i,
    input  [31:0] data_wb_dat_i,
    input         data_wb_err_i,
    input         data_wb_rst_i,
    input         data_wb_clk_i,

    // Interrupts
    input         meip_i,
    input         mtip_i,
    input         msip_i,
    input  [15:0] fast_irq_i,
    output        irq_ack_o,

    // Tracer
    output [31:0] tr_mem_data, tr_mem_addr, tr_reg_data, tr_pc, tr_instr, fflags,
    output [4:0]  tr_reg_addr,
    output [1:0]  tr_mem_len,
    output        tr_valid, tr_load, tr_store, tr_is_float
);
  // Parameters
  parameter reset_vector = 32'h0000_7400;
  // MEMFILE parameter for direct loading or override
  parameter MEMFILE      = "C:/Users/eren/Desktop/kurtarmalar/kurtarma2/project_1/project_1.srcs/sources_1/imports/fw_hello_uart/uart_main.mem";

  // ---------------- Core Interfaces ----------------
  wire [31:0] data_addr_o;
  wire [31:0] data_i;
  wire [31:0] data_o;
  wire [3:0]  data_wmask_o;
  wire        data_wen_o;
  wire        data_req_o;
  wire        data_stall_i;
  wire        data_err_i;

  wire [31:0] instr_addr_o;
  wire [31:0] instr_i;
  wire        instr_access_fault_i;

  // ---------------- Core Instantiation ----------------
  core #(
    .reset_vector(reset_vector)
  ) core0 (
    .clk_i                 (clk_i),
    .reset_i               (~reset_i), // Active-Low for core

    // Data memory
    .data_addr_o           (data_addr_o),
    .data_i                (data_i),
    .data_o                (data_o),
    .data_wmask_o          (data_wmask_o),
    .data_wen_o            (data_wen_o),
    .data_req_o            (data_req_o),
    .data_stall_i          (data_stall_i),
    .data_err_i            (data_err_i),

    // Instruction memory
    .instr_addr_o          (instr_addr_o),
    .instr_i               (instr_i),
    .instr_access_fault_i  (instr_access_fault_i),

    // IRQ & Trace
    .meip_i(meip_i), .mtip_i(mtip_i), .msip_i(msip_i), .fast_irq_i(fast_irq_i), .irq_ack_o(irq_ack_o),
    .tr_mem_data(tr_mem_data), .tr_mem_addr(tr_mem_addr), .tr_reg_data(tr_reg_data),
    .tr_pc(tr_pc), .tr_instr(tr_instr), .tr_reg_addr(tr_reg_addr), .tr_mem_len(tr_mem_len),
    .tr_valid(tr_valid), .tr_load(tr_load), .tr_store(tr_store), .tr_is_float(tr_is_float), .fflags(fflags)
  );

  // ---------------- Wishbone Logic ----------------
  reg data_cyc;
  always @(posedge data_wb_clk_i or posedge data_wb_rst_i) begin
    if (data_wb_rst_i)
      data_cyc <= 1'b0;
    else if (data_wb_ack_i || data_wb_err_i)
      data_cyc <= 1'b0;
    else if (data_req_o)
      data_cyc <= 1'b1;
  end

  assign data_wb_cyc_o = data_req_o | data_cyc;
  assign data_wb_stb_o = data_wb_cyc_o;
  assign data_wb_we_o  = ~data_wen_o;
  assign data_wb_adr_o = data_addr_o;
  assign data_wb_dat_o = data_o;
  assign data_wb_sel_o = data_wmask_o;
  assign data_i        = data_wb_dat_i;
  // Stall until Ack/Err.
  assign data_stall_i  = data_wb_stall_i | (data_wb_cyc_o & ~(data_wb_ack_i | data_wb_err_i));
  assign data_err_i    = data_wb_err_i;

  // ---------------- IMEM ----------------
  wire [31:0] imem_data;

  // Instruction Memory
  inst_mem #(
      .MEMFILE(MEMFILE)
  ) imem (
    .addr (instr_addr_o),
    .data (imem_data)
  );

  // Pipeline Register (RESTORED for Timing Fix)
  reg [31:0] instr_q;
  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i)
      instr_q <= 32'h00000013;  // NOP
    else
      instr_q <= imem_data;
  end

  assign instr_i              = instr_q; 
  assign instr_access_fault_i = 1'b0;

endmodule
