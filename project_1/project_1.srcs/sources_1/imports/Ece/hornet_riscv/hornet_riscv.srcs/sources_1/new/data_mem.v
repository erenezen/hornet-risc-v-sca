
module data_mem(
    input  wire        clk,
    input  wire        wen,      // active-high write enable
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);
    reg [31:0] mem [0:255];
    integer    j;

    // power-on reset
    initial begin
        for (j = 0; j < 256; j = j + 1)
            mem[j] = 32'd0;
    end

    always @(posedge clk) begin
        if (wen)
            mem[addr[9:2]] <= wdata;
        rdata <= mem[addr[9:2]];
    end
endmodule

