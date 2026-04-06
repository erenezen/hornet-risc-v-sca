// -----------------------------------------------------------------------------
// Tek portlu DMEM (Wishbone arayüzlü)
// - Modül adı korunuyor: memory_2rw_wb
// - Tek WB portu: cyc/stb/we/sel/adr/dat
// - Başlangıçta sıfırlı, dışarıdan yükleme yok
// -----------------------------------------------------------------------------
module memory_2rw_wb(
    // Wishbone port
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    input  [3:0]  wb_sel_i,
    output        wb_stall_o,
    output        wb_ack_o,
    output reg [31:0] wb_dat_o,
    output        wb_err_o,
    input         wb_rst_i,
    input         wb_clk_i
);
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 10;                // word adres genişliği
    
    // *** EKLEME 1: Parametre buraya eklendi ***
    parameter MEMFILE    = "";                // Hex dosyası adı (varsayılan boş)

    localparam RAM_DEPTH = (1 << ADDR_WIDTH); // word sayısı

    // *** 1) BRAM ipucu: tam BU satırın üstünde/aynı satırda olmalı ***
    (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1]; // Bellek dizisi

    // *** Memory initialization - TEK initial blok ***
`ifndef SYNTHESIS
    integer i;
    initial begin
        // 1) Önce sıfırla
        for (i = 0; i < RAM_DEPTH; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};
        // 2) Sonra dosyadan yükle (sıfırları ezer)
        if (MEMFILE != "") begin
            $readmemh(MEMFILE, mem);
        end
    end
`else
    // Sentez için sadece MEMFILE yükle
    initial begin
        if (MEMFILE != "") begin
            $readmemh(MEMFILE, mem);
        end
    end
`endif

    // Adres (word-aligned)
    wire [ADDR_WIDTH-1:0] a = wb_adr_i[ADDR_WIDTH+1:2]; // Adresin 2. dereceden kesiti

    // WB sabitleri
    assign wb_stall_o = 1'b0;
    assign wb_err_o   = 1'b0;

    // ACK ve R/W
    reg ack_q;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ack_q    <= 1'b0;
            wb_dat_o <= {DATA_WIDTH{1'b0}};
        end else begin
            // tek-cycle ACK (zero-wait-state)
            ack_q <= (wb_cyc_i & wb_stb_i) & ~ack_q;

            // Yazma (byte enable)
            if (wb_cyc_i & wb_stb_i & wb_we_i) begin
                if (wb_sel_i[0]) mem[a][7:0]   <= wb_dat_i[7:0];
                if (wb_sel_i[1]) mem[a][15:8]  <= wb_dat_i[15:8];
                if (wb_sel_i[2]) mem[a][23:16] <= wb_dat_i[23:16];
                if (wb_sel_i[3]) mem[a][31:24] <= wb_dat_i[31:24];
            end

            // Okuma (senkron; çıkış register'lı)
            if (wb_cyc_i & wb_stb_i & ~wb_we_i)
                wb_dat_o <= mem[a]; // Okuma işlemi
        end
    end

    assign wb_ack_o = ack_q;

endmodule