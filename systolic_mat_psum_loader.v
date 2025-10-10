`include "systolic.vh"

module systolci_mat_psum_loader (
    input               CLK,
    input               RST_N,   

    input [`PE_COL-1:0] MAT_PSUM_VALID_I,
    input [`ADDR_WIDTH*`PE_COL-1:0] MAT_PSUM_ADDR_I,
    input [`PSUM_WIDTH*`PE_COL-1:0] MAT_PSUM_I,

    output [`PE_COL-1:0] MAT_PSUM_VALID_O,
    output [`ADDR_WIDTH*`PE_COL-1:0] MAT_PSUM_ADDR_O
    output [`PSUM_WIDTH*`PE_COL-1:0] MAT_PSUM_O
);

    reg                       mat_psum_valid_r[0:`PE_COL-1][0:`PE_COL-1];
    reg [`ADDR_WIDTH-1:0]     mat_psum_addr_r [0:`PE_COL-1][0:`PE_COL-1];
    reg [`PSUM_WIDTH-1:0]     mat_psum_data_r [0:`PE_COL-1][0:`PE_COL-1];

    integer row, col;

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            for (row = 0; row < `PE_COL; row = row + 1) begin
                for (col = 1; col < row; col = col + 1) begin
                    mat_psum_data_r[row][col]  <= 'h0;
                    mat_psum_addr_r[row][col]  <= 'h0;
                    mat_psum_valid_r[row][col] <= 1'b0;
                end
            end
        end
        else begin
            for (col = 0; col < `PE_COL; col = col + 1) begin
                mat_psum_addr_r[col][0]  <= MAT_PSUM_ADDR_I[`ADDR_WIDTH*col +: `ADDR_WIDTH];
                mat_psum_data_r[col][0]  <= MAT_PSUM_I[`PSUM_WIDTH*col +: `PSUM_WIDTH];
                mat_psum_valid_r[col][0] <= MAT_PSUM_VALID_I[col];

                for (row = 1; row < col; row = row + 1) begin
                    mat_psum_data_r[col][row]  <= mat_psum_data_r[col][row-1];
                    mat_psum_addr_r[col][row]  <= mat_psum_addr_r[col][row-1];
                    mat_psum_valid_r[col][row] <= mat_psum_valid_r[col][row-1];
                end
            end
        end
    end

    genvar k;
    generate
        for (k = 0; k < `PE_COL; k = k + 1) begin : G_PSUM_LOADER
            assign MAT_PSUM_VALID_O[k]                           = mat_psum_valid_r[k][k];
            assign MAT_PSUM_ADDR_O[`ADDR_WIDTH*k +: `ADDR_WIDTH] = mat_psum_addr_r[k][k];
            assign MAT_PSUM_O[`PSUM_WIDTH*k +: `PSUM_WIDTH]      = mat_psum_data_r[k][k];
        end
    endgenerate
endmodule