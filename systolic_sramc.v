`include "systolic.vh"

module systolic_sramc (
    input                           CLK,
    input                           RST_N,

    // Decoder IF, Read Write
    input                           REQ_DEC_ISRAM_EN_I,
    input                           REQ_DEC_ISRAM_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_DEC_ISRAM_ADDR_I,
    input [`DATA_WIDTH-1:0]         REQ_DEC_ISRAM_WDATA_I
    input [`BANK_NUM_WIDTH-1:0]     REQ_DEC_ISRAM_BANK_NUM_I,

    output                          CPL_DEC_ISRAM_VALID_O,
    output [`DATA_WIDTH-1:0]        CPL_DEC_ISRAM_RDATA_O,

    input                           REQ_DEC_WSRAM_EN_I,
    input                           REQ_DEC_WSRAM_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_DEC_WSRAM_ADDR_I,
    input [`DATA_WIDTH-1:0]         REQ_DEC_WSRAM_WDATA_I
    input [`BANK_NUM_WIDTH-1:0]     REQ_DEC_WSRAM_BANK_NUM_I,

    output                          CPL_DEC_WSRAM_VALID_O,
    output [`DATA_WIDTH-1:0]        CPL_DEC_WSRAM_RDATA_O,

    input                           REQ_DEC_PSRAM_EN_I,
    input                           REQ_DEC_PSRAM_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_DEC_PSRAM_ADDR_I,
    input [`PSUM_WIDTH-1:0]         REQ_DEC_PSRAM_WDATA_I
    input [`BANK_NUM_WIDTH-1:0]     REQ_DEC_PSRAM_BANK_NUM_I,

    output                          CPL_DEC_PSRAM_VALID_O,
    output [`PSUM_WIDTH-1:0]        CPL_DEC_PSRAM_RDATA_O,

    // Ctrl Matmul IF, Read only
    input [`PE_ROW-1:0]             REQ_MAT_ISRAM_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_MAT_ISRAM_ADDR_I,

    input [`PE_COL-1:0]             REQ_MAT_WSRAM_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_MAT_WSRAM_ADDR_I,

    input [`PE_COL-1:0]             REQ_MAT_PSRAM_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_MAT_PSRAM_ADDR_I,

    // pe_array IF, write only
    input [`PE_COL-1:0]             REQ_PEARR_PSRAM_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_PEARR_PSRAM_ADDR_I,
    input [`PSUM_WIDTH*`PE_COL-1:0] REQ_PEARR_PSRAM_WDATA_I

    // Input, Weight, PSUM Loader If
    output [`PE_ROW-1:0]            CPL_LOADER_ISRAM_VALID_O,
    output [`DATA_WIDTH*`PE_ROW-1:0]CPL_LOADER_ISRAM_RDATA_O,

    output [`PE_COL-1:0]            CPL_LOADER_WSRAM_VALID_O,
    output [`DATA_WIDTH*`PE_COL-1:0]CPL_LOADER_WSRAM_RDATA_O,

    output [`PE_COL-1:0]            CPL_LOADER_PSRAM_VALID_O,
    output [`PSUM_WIDTH*`PE_COL-1:0]CPL_LOADER_PSRAM_RDATA_O,
);

    // Input SRAM (ISRAM)
    wire [`PE_ROW-1:0]              cen_isram_bank;
    wire [`PE_ROW-1:0]              wen_isram_bank;
    wire [`ADDR_WIDTH-1:0]          a_isram;
    wire [`DATA_WIDTH-1:0]          d_isram; // only decode writes data
    wire [`DATA_WIDTH*`PE_ROW-1:0]  q_isram_bank;

    wire [`PE_ROW-1:0]              isram_bank_sel_onecold;

    // Weight SRAM (WSRAM)
    wire [`PE_COL-1:0]              cen_wsram_bank;
    wire [`PE_COL-1:0]              wen_wsram_bank;
    wire [`ADDR_WIDTH-1:0]          a_wsram;
    wire [`DATA_WIDTH-1:0]          d_wsram;
    wire [`DATA_WIDTH*`PE_COL-1:0]  q_wsram_bank;

    wire [`PE_COL-1:0]              wsram_bank_sel_onecold;

    // Partial Sum SRAM (PSRAM)
    wire [`PE_COL-1:0]              cen_psram_p0_bank;
    wire [`PE_COL-1:0]              wen_psram_p0_bank;
    wire [`ADDR_WIDTH-1:0]          a_psram_p0;
    wire [`PSUM_WIDTH*`PE_COL-1:0]  d_psram_p0_bank;
    wire [`PSUM_WIDTH*`PE_COL-1:0]  q_psram_p0_bank;

    wire [`PE_COL-1:0]              cen_psram_p1_bank;
    wire [`PE_COL-1:0]              wen_psram_p1_bank;
    wire [`ADDR_WIDTH-1:0]          a_psram_p1;
    wire [`PSUM_WIDTH*`PE_COL-1:0]  d_psram_p1_bank;
    wire [`PSUM_WIDTH*`PE_COL-1:0]  q_psram_p1_bank;

    wire [`PE_COL-1:0]              psram_bank_sel_onecold;

    // SRAM control signals
    reg                             dec_isram_valid_r;
    reg                             dec_wsram_valid_r;
    reg                             dec_psram_valid_r;

    reg [`BANK_NUM_WIDTH-1:0]       dec_isram_bank_num_r;
    reg [`BANK_NUM_WIDTH-1:0]       dec_wsram_bank_num_r;
    reg [`BANK_NUM_WIDTH-1:0]       dec_psram_bank_num_r;

    reg                             mat_isram_valid_r;
    reg                             mat_wsram_valid_r;
    reg                             mat_psram_valid_r;

    assign isram_bank_sel_onecold = ~(1 << REQ_DEC_ISRAM_BANK_NUM_I); // Reverse of one-hot (sram enable is active low)
    assign wsram_bank_sel_onecold = ~(1 << REQ_DEC_WSRAM_BANK_NUM_I);
    assign psram_bank_sel_onecold = ~(1 << REQ_DEC_PSRAM_BANK_NUM_I);

    genvar row, col;

    generate
        for (row = 0; row < `PE_ROW; row = row + 1) begin : ASSIGN_ISRAM_BANK
            assign cen_isram_bank[row] = ~REQ_DEC_ISRAM_EN_I ? isram_bank_sel_onecold[row] : ~REQ_MAT_ISRAM_EN_I[row];
            assign wen_isram_bank[row] = ~REQ_DEC_ISRAM_EN_I ? REQ_DEC_ISRAM_WE_I : 1'b1; // Matmul, read only
        end
    endgenerate
    assign a_isram = ~REQ_DEC_ISRAM_EN_I ? REQ_DEC_ISRAM_ADDR_I : REQ_MAT_ISRAM_ADDR_I;
    assign d_isram = REQ_DEC_ISRAM_WDATA_I; // matmul, read only

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin: ASSIGN_WSRAM_BANK
            assign cen_wsram_bank[col] = ~REQ_DEC_WSRAM_EN_I ? wsram_bank_sel_onecold[col] : ~REQ_MAT_WSRAM_EN_I[col];
            assign wen_wsram_bank[col] = ~REQ_DEC_WSRAM_EN_I ? REQ_DEC_WSRAM_WE_I : 1'b1;
        end
    endgenerate
    assign a_wsram = ~REQ_DEC_WSRAM_EN_I ? REQ_DEC_WSRAM_ADDR_I : REQ_MAT_WSRAM_ADDR_I;
    assign d_wsram = REQ_DEC_WSRAM_WDATA_I;

    // PSRAM Usage: Decoder R/W, Matmul R/W, PE Array Write
    // PSRAM port 0: Decoder read/write, matmul read
    // PSRAM port 1: pe array write
    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin: ASSIGN_PSRAM_P0_BANK
            assign cen_psram_p0_bank[col] = ~REQ_DEC_PSRAM_EN_I ? psram_bank_sel_onecold[col] : ~REQ_MAT_PSRAM_EN_I[col];
            assign wen_psram_p0_bank[col] = ~REQ_DEC_PSRAM_EN_I ? REQ_DEC_PSRAM_WE_I : 1'b1;
        end
    endgenerate
    assign a_psram_p0 = ~REQ_DEC_PSRAM_EN_I ? REQ_DEC_PSRAM_ADDR_I : REQ_MAT_PSRAM_ADDR_I;
    assign d_psram_p0 = REQ_DEC_PSRAM_WDATA_I;

    assign cen_psram_p1_bank = ~REQ_PEARR_PSRAM_EN_I;
    assign wen_psram_p1_bank = 'h0; // pe_arry write only
    assign a_psram_p1 = REQ_PEARR_PSRAM_ADDR_I;
    assign d_psram_p1_bank = REQ_PEARR_PSRAM_WDATA_I;

    generate
        for (row = 0; row < `PE_ROW; row = row + 1) begin : GEN_ISRAM
            `ifdef SIM
                // For simulation, use a simpler SRAM model if available
                spsram #(
                    .DEPTH(1024),
                    .DATA_WIDTH(`DATA_WIDTH)
                ) U_ISRAM (
                    .clk        (CLK),
                    .ena        (cen_isram_bank[row]), // Active low
                    .wea        (wen_isram_bank[row]), // WR: 0, RD: 1
                    .addra      (a_isram),
                    .dina       (d_isram),
                    .douta      (q_isram_bank[`DATA_WIDTH*row +: `DATA_WIDTH])
                );
            `else // FPGA
                systolic_isram_sp_1024x8w1 U_ISRAM(
                    .CLK        (CLK),
                    .RST_N      (RST_N),
                    .cen        (cen_isram_bank[row]), // Active low
                    .wen        (wen_isram_bank[row]), // WR: 0, RD: 1
                    .a          (a_isram),
                    .d          (d_isram),
                    .q          (q_isram_bank[`DATA_WIDTH*row +: `DATA_WIDTH])
                );
            `endif
        end
    endgenerate

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin : GEN_WSRAM
            `ifdef SIM
                // For simulation, use a simpler SRAM model if available
                spsram #(
                    .DEPTH(1024),
                    .DATA_WIDTH(`DATA_WIDTH)
                ) U_WSRAM (
                    .clk        (CLK),
                    .ena        (cen_wsram_bank[col]), // Active low
                    .wea        (wen_wsram_bank[col]), // WR: 0, RD: 1
                    .addra      (a_wsram),
                    .dina       (d_wsram),
                    .douta      (q_wsram_bank[`DATA_WIDTH*col +: `DATA_WIDTH])
                );
            `else // FPGA
                systolic_wsram_sp_1024x8w1 U_WSRAM(
                    .CLK        (CLK),
                    .RST_N      (RST_N),
                    .cen        (cen_wsram_bank[col]), // Active low
                    .wen        (wen_wsram_bank[col]), // WR: 0, RD: 1
                    .a          (a_wsram),
                    .d          (d_wsram),
                    .q          (q_wsram_bank[`DATA_WIDTH*col +: `DATA_WIDTH])
                );
            `endif
        end
    endgenerate

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin : GEN_PSRAM
            // To do add: read, write port
            `ifdef SIM
                dpsram #(
                    .DEPTH(256),
                    .DATA_WIDTH(`PSUM_WIDTH)
                ) U_PSRAM (
                    .clka       (CLK),
                    .ena        (cen_psram_p0_bank[col]), // Active low
                    .wea        (wen_psram_p0_bank[col]), // WR: 0, RD: 1
                    .addra      (a_psram_p0),
                    .dina       (d_psram_p0),
                    .douta      (q_psram_p0_bank[`PSUM_WIDTH*col +: `PSUM_WIDTH])

                    .clkb       (CLK),
                    .enb        (cen_wsram_p1_bank[col]), // Active low
                    .web        (wen_wsram_p1_bank[col]), // WR: 0, RD: 1
                    .addrb      (a_psram_p1),
                    .dinb       (d_psram_p1),
                    .doutb      (q_psram_p1_bank[`PSUM_WIDTH*col +: `PSUM_WIDTH])
                );
            `else
                //
                ;
            `endif
        end
    endgenerate

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            dec_isram_bank_num_r <= 'h0;
            dec_wsram_bank_num_r <= 'h0;
            dec_psram_bank_num_r <= 'h0;
        end
        else begin
            if (~REQ_DEC_ISRAM_EN_I)
                dec_isram_bank_num_r <= REQ_DEC_ISRAM_BANK_NUM_I;

            if (~REQ_DEC_WSRAM_EN_I)
                dec_wsram_bank_num_r <= REQ_DEC_WSRAM_BANK_NUM_I;

            if (~REQ_DEC_PSRAM_EN_I)
                dec_psram_bank_num_r <= REQ_DEC_PSRAM_BANK_NUM_I;
        end
    end

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            dec_isram_valid_r <= 1'b0;
            dec_wsram_valid_r <= 1'b0;
            dec_psram_valid_r <= 1'b0;

            mat_isram_valid_r <= 'h0;
            mat_wsram_valid_r <= 'h0;
            mat_psram_valid_r <= 'h0;
        end
        else begin
            // Active low
            dec_isram_valid_r <= ~REQ_DEC_ISRAM_EN_I & REQ_DEC_ISRAM_WE_I; // WE_I -> 1: Read
            dec_wsram_valid_r <= ~REQ_DEC_WSRAM_EN_I & REQ_DEC_ISRAM_WE_I;
            dec_psram_valid_r <= ~REQ_DEC_PSRAM_EN_I & REQ_DEC_ISRAM_WE_I;

            mat_isram_valid_r <= ~REQ_MAT_ISRAM_EN_I; // matmul, read only: EN active low == WE also 1
            mat_wsram_valid_r <= ~REQ_MAT_WSRAM_EN_I;
            mat_psram_valid_r <= ~REQ_MAT_PSRAM_EN_I;
        end
    end

    // Output assignments
    assign CPL_DEC_ISRAM_VALID_O = dec_isram_valid_r;
    assign CPL_DEC_ISRAM_RDATA_O = dec_isram_valid_r ? q_isram_bank[`DATA_WIDTH*dec_isram_bank_num_r +: `DATA_WIDTH] : 'h0;

    assign CPL_DEC_WSRAM_VALID_O = dec_wsram_valid_r;
    assign CPL_DEC_WSRAM_RDATA_O = dec_wsram_valid_r ? q_wsram_bank[`DATA_WIDTH*dec_wsram_bank_num_r +: `DATA_WIDTH] : 'h0;

    assign CPL_DEC_PSRAM_VALID_O = dec_psram_valid_r;
    assign CPL_DEC_PSRAM_RDATA_O = dec_psram_valid_r ? q_psram_bank[`PSUM_WIDTH*dec_psram_bank_num_r +: `PSUM_WIDTH] : 'h0;

    assign CPL_LOADER_ISRAM_VALID_O = mat_isram_valid_r;
    assign CPL_LOADER_ISRAM_RDATA_O = |mat_isram_valid_r ? q_isram_bank : 'h0;

    assign CPL_LOADER_WSRAM_VALID_O = mat_wsram_valid_r;
    assign CPL_LOADER_WSRAM_RDATA_O = |mat_wsram_valid_r ? q_wsram_bank : 'h0;

    assign CPL_LOADER_PSRAM_VALID_O = mat_psram_valid_r;
    assign CPL_LOADER_PSRAM_RDATA_O = |mat_psram_valid_r ? q_psram_p0_bank : 'h0;
endmodule