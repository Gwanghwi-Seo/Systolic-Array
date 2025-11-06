module systolic_mat_b_loader (
    input                                    CLK,
    input                                    RST_N,

    input   [`PE_COL*`PE_ROW_ID_WIDTH-1:0]   LOADER_MAT_B_PE_ROW_ID_I,
    input   [`PE_COL-1:0]                    LOADER_MAT_B_VALID_I,
    input   [`PE_COL*`DATA_WIDTH-1:0]        LOADER_MAT_B_DATA_I,

    output  [`PE_COL*`PE_ROW_ID_WIDTH-1:0]   LOADER_MAT_B_PE_ROW_ID_O,
    output  [`PE_COL-1:0]                    LOADER_MAT_B_VALID_O,
    output  [`PE_COL*`DATA_WIDTH-1:0]        LOADER_MAT_B_DATA_O
);

    reg [`PE_COL*`DATA_WIDTH-1:0]       mat_b_data_r;
    reg [`PE_COL-1:0]                   mat_b_valid_r;
    reg [`PE_COL*`PE_ROW_ID_WIDTH-1:0]  en_pe_row_id_r;

    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            mat_b_data_r      <= 'h0;
            mat_b_valid_r     <= 'h0;
            en_pe_row_id_r    <= 'h0;
        end
        else begin
            mat_b_data_r      <= LOADER_MAT_B_DATA_I;
            mat_b_valid_r     <= LOADER_MAT_B_VALID_I;
            en_pe_row_id_r    <= LOADER_MAT_B_PE_ROW_ID_I;
        end
    end

    assign LOADER_MAT_B_DATA_O = mat_b_data_r;
    assign LOADER_MAT_B_VALID_O = mat_b_valid_r;
    assign LOADER_MAT_B_PE_ROW_ID_O = en_pe_row_id_r;

endmodule