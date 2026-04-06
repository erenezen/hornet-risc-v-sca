// tb_simple.v
`timescale 1ns/1ps
module tb_simple;
    reg         clk   = 0;
    reg         rst_n = 0;
    wire [31:0] instr_addr_o, data_addr_o, data_w_o, data_r_o;

    // DUT
    top_simple dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .instr_addr_o(instr_addr_o),
        .data_addr_o (data_addr_o),
        .data_w_o    (data_w_o),
        .data_r_o    (data_r_o)
    );

    // 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    initial begin
        // VCD dump (xsim isteðe baðlý görmezden gelebilir)
        $dumpfile("tb_simple.vcd");
        $dumpvars(0, tb_simple);

        // Reset uygula (aktif-düþük)
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Biraz koþtur
        repeat (200) @(posedge clk);

        $display("TB finished.");
        $finish;
    end
endmodule

