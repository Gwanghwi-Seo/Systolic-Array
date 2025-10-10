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
    input                           REQ_ISRAM1_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_ISRAM1_ADDR_I,
    // input [`DATA_WIDTH-1:0]         REQ_ISRAM1_WDATA_I
    // input [`BANK_NUM_WIDTH-1:0]     REQ_ISRAM1_BANK_NUM_I, 

    output                          CPL_ISRAM1_VALID_O,
    output [`DATA_WIDTH-1:0]        CPL_ISRAM1_RDATA_O,

    input                           REQ_WSRAM1_EN_I,
    input                           REQ_WSRAM1_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_WSRAM1_ADDR_I,
    // input [`DATA_WIDTH-1:0]         REQ_WSRAM1_WDATA_I
    // input [`BANK_NUM_WIDTH-1:0]     REQ_WSRAM1_BANK_NUM_I, 

    output                          CPL_WSRAM1_VALID_O,
    output [`DATA_WIDTH-1:0]        CPL_WSRAM1_RDATA_O,

    input                           REQ_PSRAM1_EN_I,
    input                           REQ_PSRAM1_WE_I,
    input [`ADDR_WIDTH-1:0]         REQ_PSRAM1_ADDR_I,
    input [`PSUM_WIDTH-1:0]         REQ_PSRAM1_WDATA_I
    // input [`BANK_NUM_WIDTH-1:0]     REQ_PSRAM1_BANK_NUM_I, 

    output                          CPL_PSRAM1_VALID_O,
    output [`PSUM_WIDTH-1:0]        CPL_PSRAM1_RDATA_O,

    // Loader If
);
    assign cen_isram0_bank = (1 << REQ_ISRAM0_BANK_NUM_I) 

    wire [`PE_ROW-1:0]              cen_isram_bank;
    wire [`PE_ROW-1:0]              wen_isram_bank;
    wire [`ADDR_WIDTH*`PE_ROW-1:0]  a_isram_bank;
    wire [`DATA_WIDTH*`PE_ROW-1:0]  d_isram_bank;
    wire [`DATA_WIDTH*`PE_ROW-1:0]  q_isram_bank;

    wire                            cen_wsram;
    wire                            wen_wsram;
    wire [`ADDR_WIDTH-1:0]          a_wsram;
    wire [`DATA_WIDTH-1:0]          d_wsram;
    wire [`DATA_WIDTH-1:0]          q_wsram;

    wire                            cen_psram;
    wire                            wen_psram;
    wire [`ADDR_WIDTH-1:0]          a_psram;
    wire [`PSUM_WIDTH-1:0]          d_psram;
    wire [`PSUM_WIDTH-1:0]          q_psram;

    reg                             isram_valid_r;
    reg                             wsram_valid_r;
    reg                             psram_valid_r;

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            isram_valid_r <= 1'b0;
            wsram_valid_r <= 1'b0;
            psram_valid_r <= 1'b0;
        end 
        else begin
            // Active low
            isram_valid_r <= (~REQ_ISRAM_EN_I);
            wsram_valid_r <= (~REQ_WSRAM_EN_I);
            psram_valid_r <= (~REQ_PSRAM_EN_I);
        end
    end

    genvar row, col;

    generate
        for (row = 0; row < `PE_ROW; row = row + 1) begin : G_ISRAM
            systolic_isram_sp_1024x8w1 U_ISRAM(
                .CLK        (CLK),
                .RST_N      (RST_N),
                .cen        (cen_isram), // Active low
                .wen        (wen_isram), // WR: 0, RD: 1
                .a          (a_isram),
                .d          (d_isram),
                .q          (q_isram)
            );
        end
    endgenerate

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin : G_WSRAM
            systolic_wsram_sp_1024x8w1 U_WSRAM(
                .CLK        (CLK),
                .RST_N      (RST_N),
                .cen        (cen_wsram), // Active low
                .wen        (wen_wsram), // WR: 0, RD: 1
                .a          (a_wsram),
                .d          (d_wsram),
                .q          (q_wsram)
            );
        end
    endgenerate

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin : G_PSRAM
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

    assign cen_isram = REQ_ISRAM_EN_I ? 1'b0 : 1'b1;
    assign wen_isram = REQ_ISRAM_WEN_I;
    assign a_isram   = REQ_ISRAM_ADDR_I;
    assign d_isram   = REQ_ISRAM_WDATA_I;

    assign cen_wsram = REQ_WSRAM_EN_I ? 1'b0 : 1'b1;
    assign wen_wsram = REQ_WSRAM_WEN_I;
    assign a_wsram   = REQ_WSRAM_ADDR_I;
    assign d_wsram   = REQ_WSRAM_WDATA_I;

    assign cen_psram = REQ_PSRAM_EN_I ? 1'b0 : 1'b1;
    assign wen_psram = REQ_PSRAM_WEN_I;
    assign a_psram   = REQ_PSRAM_ADDR_I;
    assign d_psram   = REQ_PSRAM_WDATA_I;

    // Output assignments
    assign CPL_ISRAM_VALID_O = isram_valid_r;
    assign CPL_ISRAM_RDATA_O = isram_valid_r ? q_isram : 'h0;

    assign CPL_WSRAM_VALID_O = wsram_valid_r;
    assign CPL_WSRAM_RDATA_O = wsram_valid_r ? q_wsram : 'h0;

    assign CPL_PSRAM_VALID_O = psram_valid_r;
    assign CPL_PSRAM_RDATA_O = psram_valid_r ? q_psram : 'h0;

endmodule