`include "systolic.vh"

module systolic_sramc (
    input                           CLK,
    input                           RST_N,

    // Decoder IF
    input                           REQ_ISRAM0_EN_I,
    input                           REQ_ISRAM0_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_ISRAM0_ADDR_I,
    input [`DATA_WIDTH-1:0]         REQ_ISRAM0_WDATA_I
    input [`BANK_NUM_WIDTH-1:0]     REQ_ISRAM0_BANK_NUM_I, 

    output                          CPL_ISRAM0_VALID_O,
    output [`DATA_WIDTH-1:0]        CPL_ISRAM0_RDATA_O,

    input                           REQ_WSRAM0_EN_I,
    input                           REQ_WSRAM0_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_WSRAM0_ADDR_I,
    input [`DATA_WIDTH-1:0]         REQ_WSRAM0_WDATA_I
    input [`BANK_NUM_WIDTH-1:0]     REQ_WSRAM0_BANK_NUM_I, 

    output                          CPL_WSRAM0_VALID_O,
    output [`DATA_WIDTH-1:0]        CPL_WSRAM0_RDATA_O,

    input                           REQ_PSRAM0_EN_I,
    input                           REQ_PSRAM0_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_PSRAM0_ADDR_I,
    input [`PSUM_WIDTH-1:0]         REQ_PSRAM0_WDATA_I
    input [`BANK_NUM_WIDTH-1:0]     REQ_PSRAM0_BANK_NUM_I, 

    output                          CPL_PSRAM0_VALID_O,
    output [`PSUM_WIDTH-1:0]        CPL_PSRAM0_RDATA_O,

    // Matmul IF
    input [`PE_ROW-1:0]             REQ_ISRAM1_EN_I,
    // input                           REQ_ISRAM1_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_ISRAM1_ADDR_I,
    // input [`DATA_WIDTH-1:0]         REQ_ISRAM1_WDATA_I
    // input [`BANK_NUM_WIDTH-1:0]     REQ_ISRAM1_BANK_NUM_I, 

    output                          CPL_ISRAM1_VALID_O,
    output [`DATA_WIDTH*`PE_ROW-1:0]CPL_ISRAM1_RDATA_O,

    input [`PE_COL-1:0]             REQ_WSRAM1_EN_I,
    // input                           REQ_WSRAM1_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_WSRAM1_ADDR_I,
    // input [`DATA_WIDTH-1:0]         REQ_WSRAM1_WDATA_I
    // input [`BANK_NUM_WIDTH-1:0]     REQ_WSRAM1_BANK_NUM_I, 

    output                          CPL_WSRAM1_VALID_O,
    output [`DATA_WIDTH*`PE_COL-1:0]CPL_WSRAM1_RDATA_O,

    input [`PE_COL-1:0]             REQ_PSRAM1_EN_I,
    input                           REQ_PSRAM1_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_PSRAM1_ADDR_I,
    input [`PSUM_WIDTH-1:0]         REQ_PSRAM1_WDATA_I
    // input [`BANK_NUM_WIDTH-1:0]     REQ_PSRAM1_BANK_NUM_I, 

    output                          CPL_PSRAM1_VALID_O,
    output [`PSUM_WIDTH-1:0]        CPL_PSRAM1_RDATA_O,

    // Loader If
);

    // Input SRAM (ISRAM)
    wire [`PE_ROW-1:0]              cen_isram_bank;
    wire [`PE_ROW-1:0]              wen_isram_bank;
    wire [`ADDR_WIDTH-1:0]          a_isram;
    wire [`DATA_WIDTH-1:0]          d_isram; // only decode writes data
    wire [`DATA_WIDTH*`PE_ROW-1:0]  q_isram_bank;

    wire [`PE_ROW-1:0]              isram_bank_sel_onehot;

    // Weight SRAM (WSRAM)
    wire                            cen_wsram_bank;
    wire                            wen_wsram_bank;
    wire [`ADDR_WIDTH-1:0]          a_wsram;
    wire [`DATA_WIDTH-1:0]          d_wsram;
    wire [`DATA_WIDTH*`PE_COL-1:0]  q_wsram_bank;

    wire [`PE_COL-1:0]              wsram_bank_sel_onehot;

    // Partial Sum SRAM (PSRAM)
    wire                            cen_psram;
    wire                            wen_psram;
    wire [`ADDR_WIDTH-1:0]          a_psram;
    wire [`PSUM_WIDTH-1:0]          d_psram;
    wire [`PSUM_WIDTH-1:0]          q_psram;

    // SRAM control signals
    reg                             isram0_valid_r;
    reg                             wsram0_valid_r;
    reg                             psram0_valid_r;

    reg [`BANK_NUM_WIDTH-1:0]       isram0_bank_num_r;
    reg [`BANK_NUM_WIDTH-1:0]       wsram0_bank_num_r;
    reg [`BANK_NUM_WIDTH-1:0]       psram0_bank_num_r;

    reg                             isram1_valid_r;
    reg                             wsram1_valid_r;
    reg                             psram1_valid_r;

    assign isram_bank_sel_onehot = (1 << REQ_ISRAM0_BANK_NUM_I);
    assign wsram_bank_sel_onehot = (1 << REQ_WSRAM0_BANK_NUM_I);
    assign psram_bank_sel_onehot = (1 << REQ_PSRAM0_BANK_NUM_I);

    genvar row, col;

    generate
        for (row = 0; row < `PE_ROW; row = row + 1) begin : ASSIGN_ISRAM_BANK //
            assign cen_isram_bank[row] = ~REQ_ISRAM0_EN_I ? isram_bank_sel_onehot[row] : REQ_ISRAM1_EN_I[row];
            assign wen_isram_bank[row] = ~REQ_ISRAM0_EN_I ? REQ_ISRAM0_WE_I : 1'b1; // Matmul, read only
            assign a_isram = ~REQ_ISRAM0_EN_I ? REQ_ISRAM0_ADDR_I : REQ_ISRAM1_ADDR_I;
            assign d_isram = REQ_ISRAM0_WDATA_I; // Decoder, write only
        end
    endgenerate

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin: ASSIGN_WSRAM_BANK
            assign cen_wsram_bank[col] = ~REQ_WSRAM0_EN_I ? wsram_bank_sel_onehot[col] : REQ_WSRAM1_EN_I[col];
            assign wen_wsram_bank[col] = ~REQ_WSRAM0_EN_I ? REQ_WSRAM0_WE_I : 1'b1;
            assign a_wsram = ~REQ_WSRAM0_EN_I ? REQ_WSRAM0_ADDR_I : REQ_WSRAM1_ADDR_I;
            assign d_wsram = REQ_WSRAM0_WDATA_I;
        end
    endgenerate

    generate
        for (row = 0; row < `PE_ROW; row = row + 1) begin : GEN_ISRAM
            systolic_isram_sp_1024x8w1 U_ISRAM(
                .CLK        (CLK),
                .RST_N      (RST_N),
                .cen        (cen_isram_bank[row]), // Active low
                .wen        (wen_isram_bank[row]), // WR: 0, RD: 1
                .a          (a_isram),
                .d          (d_isram),
                .q          (q_isram_bank[`DATA_WIDTH*row +: `DATA_WIDTH])
            );
        end
    endgenerate

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin : GEN_WSRAM
            systolic_wsram_sp_1024x8w1 U_WSRAM(
                .CLK        (CLK),
                .RST_N      (RST_N),
                .cen        (cen_wsram_bank[col]), // Active low
                .wen        (wen_wsram_bank[col]), // WR: 0, RD: 1
                .a          (a_wsram),
                .d          (d_wsram),
                .q          (q_wsram_bank[`DATA_WIDTH*col +: `DATA_WIDTH])
            );
        end
    endgenerate

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin : GEN_PSRAM
            systolic_isram_sp_256x24w1 U_PSRAM(
                .CLK        (CLK),
                .RST_N      (RST_N),
                .cen        (cen_psram), // Active low
                .wen        (wen_psram), // WR: 0, RD: 1
                .a          (a_psram),
                .d          (d_psram),
                .q          (q_psram)
            );
        end
    endgenerate

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            isram0_bank_num_r <= 'h0;
            wsram0_bank_num_r <= 'h0;
            psram0_bank_num_r <= 'h0;
        end
        else begin
            if (~REQ_ISRAM0_EN_I) begin
                isram0_bank_num_r <= REQ_ISRAM0_BANK_NUM_I;
            end

            if (~REQ_WSRAM0_EN_I) begin
                wsram0_bank_num_r <= REQ_WSRAM0_BANK_NUM_I;
            end

            if (~REQ_PSRAM0_EN_I) begin
                psram0_bank_num_r <= REQ_PSRAM0_BANK_NUM_I;
            end
        end
    end

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            isram0_valid_r <= 1'b0;
            wsram0_valid_r <= 1'b0;
            psram0_valid_r <= 1'b0;

            isram1_valid_r <= 1'b0;
            wsram1_valid_r <= 1'b0;
            psram1_valid_r <= 1'b0;
        end 
        else begin
            // Active low
            isram0_valid_r <= ~REQ_ISRAM0_EN_I;
            wsram0_valid_r <= ~REQ_WSRAM0_EN_I;
            psram0_valid_r <= ~REQ_PSRAM0_EN_I;

            isram1_valid_r <= |(~REQ_ISRAM1_EN_I);
            wsram1_valid_r <= |(~REQ_WSRAM1_EN_I);
            psram1_valid_r <= |(~REQ_PSRAM1_EN_I);
        end
    end

    // Output assignments
    assign CPL_ISRAM0_VALID_O = isram0_valid_r;
    assign CPL_ISRAM0_RDATA_O = isram0_valid_r ? q_isram_bank[`DATA_WIDTH*isram0_bank_num_r +: `DATA_WIDTH] : 'h0;

    assign CPL_WSRAM0_VALID_O = wsram0_valid_r;
    assign CPL_WSRAM0_RDATA_O = wsram0_valid_r ? q_wsram_bank[`DATA_WIDTH*wsram0_bank_num_r +: `DATA_WIDTH] : 'h0;

    assign CPL_ISRAM1_VALID_O = isram1_valid_r;
    assign CPL_ISRAM1_RDATA_O = isram1_valid_r ? q_isram_bank : 'h0;

    assign CPL_WSRAM1_VALID_O = wsram1_valid_r;
    assign CPL_WSRAM1_RDATA_O = wsram1_valid_r ? q_wsram_bank : 'h0;
endmodule