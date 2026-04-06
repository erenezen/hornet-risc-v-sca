`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Instruction ROM (.mem file) - Vivado uyumlu, fetch mesajı yazar
// BASE_ADDR = 0x0000_7400
// -----------------------------------------------------------------------------
module inst_mem #(
    parameter BASE_ADDR = 32'h0000_7400,
    parameter WORDS     = 8192,
    parameter ADDR_BITS = 13,
    parameter MEMFILE   = "c:/Users/eren/Desktop/kurtarma/project_1/firmware.mem"
)(
    input  wire [31:0] addr,   // PC (byte address)
    output wire [31:0] data    // 0-cycle combinational ROM output
);

    // ROM tanımı
    (* rom_style = "distributed", ram_style = "distributed" *)
    reg [31:0] mem_w [0:WORDS-1];

    // Başlangıçta belleği yükle
    initial begin
        $readmemh(MEMFILE, mem_w);
        `ifndef SYNTHESIS
            $display("IMEM: Loading %s, Words=%0d, Base=0x%h", MEMFILE, WORDS, BASE_ADDR);
            $display("IMEM: [0]=%h, [1]=%h", mem_w[0], mem_w[1]); 
        `endif
    end

    // Adres çözümleme
    wire [31:0] off = addr - BASE_ADDR;
    wire        hit = (addr >= BASE_ADDR) && (off < (WORDS << 2));
    wire [ADDR_BITS-1:0] idx = off[ADDR_BITS+1:2];

    // FETCH log (sadece simülasyonda)
    `ifndef SYNTHESIS
    reg [31:0] last_addr = 32'hFFFF_FFFF;
    always @ (addr) begin
        if (hit && addr != last_addr) begin
            // $display("IMEM: fetch @0x%08h (hit=%b idx=%h) -> %08h", addr, hit, idx, mem_w[idx]);
            last_addr <= addr;
        end else if (!hit && addr != last_addr) begin
             $display("IMEM: MISS  @0x%08h (hit=%b off=%h)", addr, hit, off);
             last_addr <= addr;
        end
    end
    `endif

    // ROM çıkışı
    assign data = hit ? mem_w[idx] : 32'h00000013;  // NOP (ADDI x0,x0,0)

endmodule
