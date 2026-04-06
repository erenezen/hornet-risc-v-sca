// top_simple.v
module top_simple(
    input  wire        clk,
    input  wire        rst_n,        // active-low reset

    // gözlem portları
    output wire [31:0] instr_addr_o,
    output wire [31:0] data_addr_o,
    output wire [31:0] data_w_o,
    output wire [31:0] data_r_o
);
    wire [31:0] instr_i;
    wire        data_wen_n;  // core'dan active-low write enable
    wire        data_req;    // handshake, kullanmıyoruz
    wire        data_we;     // RAM için active-high

    // Instruction ROM
    inst_mem imem (
        .addr(instr_addr_o),
        .data(instr_i)
    );

    // Data RAM
    data_mem dmem (
        .clk   (clk),
        .wen   (data_we),
        .addr  (data_addr_o),
        .wdata (data_w_o),
        .rdata (data_r_o)
    );

    // Hornet Core
    core core0 (
        .clk_i           (clk),
        .reset_i         (rst_n),       // !!! artık direkt rst_n
        // instruction
        .instr_addr_o       (instr_addr_o),
        .instr_i            (instr_i),
        .instr_access_fault_i(1'b0),
        // data
        .data_addr_o      (data_addr_o),
        .data_i           (data_r_o),
        .data_o           (data_w_o),
        .data_wmask_o     (),
        .data_wen_o       (data_wen_n),
        .data_req_o       (data_req),
        .data_stall_i     (1'b0),
        .data_err_i       (1'b0),
        // interrupts (unused)
        .meip_i(1'b0), .mtip_i(1'b0),
        .msip_i(1'b0), .fast_irq_i(4'b0),
        .irq_ack_o()
    );

    // tersle: active-low ? active-high
    assign data_we = ~data_wen_n;
endmodule

