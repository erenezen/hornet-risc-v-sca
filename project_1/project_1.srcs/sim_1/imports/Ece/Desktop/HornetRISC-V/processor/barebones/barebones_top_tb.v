`timescale 1ns/1ps

module barebones_top_tb();

  reg reset_i, clk_i;
  wire irq_ack_o;
  reg meip_i;
  reg [15:0] fast_irq_i;

  barebones_wb_top uut (
    .reset_i(reset_i),
    .clk_i(clk_i),
    .meip_i(meip_i),
    .fast_irq_i(fast_irq_i),
    .irq_ack_o(irq_ack_o)
  );

  // Saat üretimi
  always begin
    clk_i = 1'b0; #5;
    clk_i = 1'b1; #5;
  end

  initial begin
    reset_i    = 1'b1;
    meip_i     = 1'b0;
    fast_irq_i = 16'b0;

    // Bellek yüklenmesi için 1 ns bekle
    #1;
    $display("mem[8192] after load = %h", uut.memory.mem[8192]);
    $display("mem[8193] after load = %h", uut.memory.mem[8193]);
    $display("mem[8194] after load = %h", uut.memory.mem[8194]);

    // Reset süresi
    #100;
    reset_i = 1'b0;

    // Simülasyonu biraz daha ilerlet
    #10000;
    $finish;
  end

endmodule

