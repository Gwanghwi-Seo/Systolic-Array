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

    // Ctrl Matmul IF
    input [`PE_ROW-1:0]             REQ_ISRAM1_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_ISRAM1_ADDR_I,

    input [`PE_COL-1:0]             REQ_WSRAM1_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_WSRAM1_ADDR_I,

    input [`PE_COL-1:0]             REQ_PSRAM1_RD_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_PSRAM1_RD_ADDR_I,

    // pe_array IF
    input [`PE_COL-1:0]             REQ_PSRAM1_WR_EN_I,
    input [`ADDR_WIDTH-1:0]         REQ_PSRAM1_WR_ADDR_I,
    input [`PSUM_WIDTH*`PE_COL-1:0] REQ_PSRAM1_WDATA_I

    // Input, Weight, PSUM Loader If
    output [`PE_ROW-1:0]            CPL_ISRAM1_VALID_O,
    output [`DATA_WIDTH*`PE_ROW-1:0]CPL_ISRAM1_RDATA_O,

    output [`PE_COL-1:0]            CPL_WSRAM1_VALID_O,
    output [`DATA_WIDTH*`PE_COL-1:0]CPL_WSRAM1_RDATA_O,

    output [`PE_COL-1:0]            CPL_PSRAM1_VALID_O,
    output [`PSUM_WIDTH*`PE_COL-1:0]CPL_PSRAM1_RDATA_O,
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
    wire [`PE_COL-1:0]              cen_psram_bank;
    wire [`PE_COL-1:0]              wen_psram_bank;
    wire [`ADDR_WIDTH-1:0]          a_psram;
    wire [`PSUM_WIDTH*`PE_COL-1:0]  d_psram_bank;
    wire [`PSUM_WIDTH*`PE_COL-1:0]  q_psram_bank;

    wire [`PE_COL-1:0]              psram_bank_sel_onecold;

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

    assign isram_bank_sel_onecold = ~(1 << REQ_ISRAM0_BANK_NUM_I); // Reverse of one-hot (sram enable is active low)
    assign wsram_bank_sel_onecold = ~(1 << REQ_WSRAM0_BANK_NUM_I);
    assign psram_bank_sel_onecold = ~(1 << REQ_PSRAM0_BANK_NUM_I);

    genvar row, col;

    generate
        for (row = 0; row < `PE_ROW; row = row + 1) begin : ASSIGN_ISRAM_BANK
            assign cen_isram_bank[row] = ~REQ_ISRAM0_EN_I ? isram_bank_sel_onecold[row] : REQ_ISRAM1_EN_I[row];
            assign wen_isram_bank[row] = ~REQ_ISRAM0_EN_I ? REQ_ISRAM0_WE_I : 1'b1; // Matmul, read only
        end
    endgenerate
    assign a_isram = ~REQ_ISRAM0_EN_I ? REQ_ISRAM0_ADDR_I : REQ_ISRAM1_ADDR_I;
    assign d_isram = REQ_ISRAM0_WDATA_I; // Decoder, write only

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin: ASSIGN_WSRAM_BANK
            assign cen_wsram_bank[col] = ~REQ_WSRAM0_EN_I ? wsram_bank_sel_onecold[col] : REQ_WSRAM1_EN_I[col];
            assign wen_wsram_bank[col] = ~REQ_WSRAM0_EN_I ? REQ_WSRAM0_WE_I : 1'b1;
        end
    endgenerate
    assign a_wsram = ~REQ_WSRAM0_EN_I ? REQ_WSRAM0_ADDR_I : REQ_WSRAM1_ADDR_I;
    assign d_wsram = REQ_WSRAM0_WDATA_I;

    generate
        for (col = 0; col < `PE_COL; col = col + 1) begin: ASSIGN_PSRAM_BANK
            assign cen_psram_bank[col] = ~REQ_PSRAM0_EN_I ? psram_bank_sel_onecold[col] : REQ_PSRAM1_EN_I[col];
            assign wen_psram_bank[col] = ~REQ_PSRAM0_EN_I ? REQ_PSRAM0_WE_I : 1'b1;
            assign d_psram_bank[col] = ~REQ_PSRAM0_EN_I ? REQ_PSRAM0_WDATA_I : REQ_PSRAM1_WDATA_I[`PSUM_WIDTH*col +: `PSUM_WIDTH];
        end
    endgenerate
    assign a_psram = ~REQ_PSRAM0_EN_I ? REQ_PSRAM0_ADDR_I : REQ_PSRAM1_ADDR_I;

    generate
        for (row = 0; row < `PE_ROW; row = row + 1) begin : GEN_ISRAM
            `ifdef SIM
                // For simulation, use a simpler SRAM model if available
                spram #(
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
                spram #(
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

            isram1_valid_r <= 'h0;
            wsram1_valid_r <= 'h0;
            psram1_valid_r <= 'h0;
        end 
        else begin
            // Active low
            isram0_valid_r <= ~REQ_ISRAM0_EN_I;
            wsram0_valid_r <= ~REQ_WSRAM0_EN_I;
            psram0_valid_r <= ~REQ_PSRAM0_EN_I;

            isram1_valid_r <= ~REQ_ISRAM1_EN_I;
            wsram1_valid_r <= ~REQ_WSRAM1_EN_I;
            psram1_valid_r <= ~REQ_PSRAM1_EN_I;
        end
    end

    // Output assignments
    assign CPL_ISRAM0_VALID_O = isram0_valid_r;
    assign CPL_ISRAM0_RDATA_O = isram0_valid_r ? q_isram_bank[`DATA_WIDTH*isram0_bank_num_r +: `DATA_WIDTH] : 'h0;

    assign CPL_WSRAM0_VALID_O = wsram0_valid_r;
    assign CPL_WSRAM0_RDATA_O = wsram0_valid_r ? q_wsram_bank[`DATA_WIDTH*wsram0_bank_num_r +: `DATA_WIDTH] : 'h0;

    assign CPL_PSRAM0_VALID_O = psram0_valid_r;
    assign CPL_PSRAM0_RDATA_O = psram0_valid_r ? q_psram_bank[`PSUM_WIDTH*psram0_bank_num_r +: `PSUM_WIDTH] : 'h0;

    assign CPL_ISRAM1_VALID_O = isram1_valid_r;
    assign CPL_ISRAM1_RDATA_O = |isram1_valid_r ? q_isram_bank : 'h0;

    assign CPL_WSRAM1_VALID_O = wsram1_valid_r;
    assign CPL_WSRAM1_RDATA_O = |wsram1_valid_r ? q_wsram_bank : 'h0;

    assign CPL_PSRAM1_VALID_O = psram1_valid_r;
    assign CPL_PSRAM1_RDATA_O = |psram1_valid_r ? q_psram_bank : 'h0;
endmodule