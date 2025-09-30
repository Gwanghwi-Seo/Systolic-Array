module systolic_mat_b_loader (
    input CLK,
    input RST_N,

    input   [`PE_COL-1:0]                    MAT_B_VALID_I,
    input   [`PE_COL*`PE_ROW_ID_WIDTH-1:0]   EN_PE_ROW_ID_I,
    input   [`PE_COL*`DATA_WIDTH-1:0]        MAT_B_I,

    output  [`PE_COL-1:0]                    MAT_B_VALID_O,
    output  [`PE_COL*`PE_ROW_ID_WIDTH-1:0]   EN_PE_ROW_ID_O,
    output  [`PE_COL*`DATA_WIDTH-1:0]        MAT_B_O
);

    reg [`PE_COL*`DATA_WIDTH-1:0]       mat_a_data_r;
    reg [`PE_COL-1:0]                   mat_a_valid_r;
    reg [`PE_COL*`PE_ROW_ID_WIDTH-1:0]  en_pe_row_id_r;

    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            mat_a_data_r      <= 'h0;
            mat_a_valid_r     <= 'h0;
            en_pe_row_id_r    <= 'h0;
        end
        else begin
            mat_a_data_r      <= MAT_B_I;
            mat_a_valid_r     <= MAT_B_VALID_I;
            en_pe_row_id_r    <= EN_PE_ROW_ID_I;
        end
    end

    assign MAT_B_O          = mat_a_data_r;
    assign MAT_B_VALID_O    = mat_a_valid_r;
    assign EN_PE_ROW_ID_O   = en_pe_row_id_r;

endmodule