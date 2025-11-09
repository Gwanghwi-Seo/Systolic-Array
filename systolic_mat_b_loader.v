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
            // mat_b_data_r      <= LOADER_MAT_B_DATA_I;
            // mat_b_valid_r     <= LOADER_MAT_B_VALID_I;
            // en_pe_row_id_r    <= LOADER_MAT_B_PE_ROW_ID_I;

            if (LOADER_MAT_B_VALID_I) begin
                mat_b_data_r      <= LOADER_MAT_B_DATA_I;
                mat_b_valid_r     <= LOADER_MAT_B_VALID_I;
                en_pe_row_id_r    <= LOADER_MAT_B_PE_ROW_ID_I;
            end
        end
    end

    assign LOADER_MAT_B_DATA_O = mat_b_data_r;
    assign LOADER_MAT_B_VALID_O = mat_b_valid_r;
    assign LOADER_MAT_B_PE_ROW_ID_O = en_pe_row_id_r;

    `ifdef SIM
        wire  [`PE_ROW_ID_WIDTH-1:0]   sim_loader_mat_b_pe_row_id[0:`PE_COL-1];
        wire                           sim_loader_mat_b_valid    [0:`PE_COL-1];
        wire  [`DATA_WIDTH-1:0]        sim_loader_mat_b_data     [0:`PE_COL-1];

        generate
            genvar g;
            for (g=0; g < `PE_COL; g=g+1) begin
                assign sim_loader_mat_b_pe_row_id[g] = LOADER_MAT_B_PE_ROW_ID_O[`PE_ROW_ID_WIDTH*g +: `PE_ROW_ID_WIDTH];
                assign sim_loader_mat_b_valid[g] = LOADER_MAT_B_VALID_O[g];
                assign sim_loader_mat_b_data[g] = LOADER_MAT_B_DATA_O[`DATA_WIDTH*g +: `DATA_WIDTH];
            end
        endgenerate
    `endif
endmodule