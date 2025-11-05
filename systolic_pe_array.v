// pe_array.v (수정 완료/M
`include "systolic.vh"

module systolic_pe_array (
    input                                       CLK,
    input                                       RST_N,

    // matrix A (Inputs for the first column)
    input [`PE_ROW-1:0]                         MAT_A_BANK_VALID_I,
    input [`DATA_WIDTH*`PE_ROW-1:0]             MAT_A_BANK_DATA_I,
    
    // matrix B (Inputs for the first row)
    input [`PE_ROW_ID_WIDTH*`PE_COL-1:0]        MAT_B_BANK_PE_ROW_ID_I,
    input [`PE_COL-1:0]                         MAT_B_BANK_VALID_I,
    input [`DATA_WIDTH*`PE_COL-1:0]             MAT_B_BANK_DATA_I,

    // PSUM (Inputs for the first row)
    input [`PE_COL-1:0]                         MAT_PSUM_BANK_VALID_I,
    input [`ADDR_WIDTH*`PE_COL-1:0]             MAT_PSUM_BANK_ADDR_I,
    input [`PSUM_WIDTH*`PE_COL-1:0]             MAT_PSUM_BANK_DATA_I,

    // PSUM (Outputs from the last row)
    output [`PE_COL-1:0]                        MAT_PSUM_BANK_VALID_O,
    output [`ADDR_WIDTH*`PE_COL-1:0]            MAT_PSUN_BANK_ADDR_O,
    output [`PSUM_WIDTH*`PE_COL-1:0]            MAT_PSUM_BANK_DATA_O
);

    // Wires for Matrix A dataflow (rightward)
    wire [`DATA_WIDTH-1:0]      mat_a_data    [0:`PE_ROW-1][0:`PE_COL]; // Note: PE_COL for output
    wire                        mat_a_valid   [0:`PE_ROW-1][0:`PE_COL];

    // Wires for Matrix B dataflow (downward)
    wire [`DATA_WIDTH-1:0]      mat_b_data    [0:`PE_ROW][0:`PE_COL-1]; // Note: PE_ROW for output
    wire                        mat_b_valid   [0:`PE_ROW][0:`PE_COL-1];
    wire [`PE_ROW_ID_WIDTH-1:0] mat_b_pe_row_id  [0:`PE_ROW][0:`PE_COL-1];

    // Wires for PSUM dataflow (downward)
    wire [`PSUM_WIDTH-1:0]      mat_psum_data [0:`PE_ROW][0:`PE_COL-1];
    wire                        mat_psum_valid[0:`PE_ROW][0:`PE_COL-1];
    wire [`ADDR_WIDTH-1:0]      mat_psum_addr [0:`PE_ROW][0:`PE_COL-1];

    genvar m, n;

    generate
        // Connect inputs to the boundaries of the wire grid
        for (m = 0; m < `PE_ROW; m = m + 1) begin
            assign mat_a_data[m][0]  = MAT_A_BANK_DATA_I[`DATA_WIDTH*m +: `DATA_WIDTH];
            assign mat_a_valid[m][0] = MAT_A_BANK_VALID_I[m];
        end
        for (n = 0; n < `PE_COL; n = n + 1) begin
            assign mat_b_data[0][n]   = MAT_B_BANK_DATA_I[`DATA_WIDTH*n +: `DATA_WIDTH];
            assign mat_b_valid[0][n]  = MAT_B_BANK_VALID_I[n];
            assign mat_b_pe_row_id[0][n] = MAT_B_BANK_PE_ROW_ID_I[`PE_ROW_ID_WIDTH*n +: `PE_ROW_ID_WIDTH];
            
            assign mat_psum_data[0][n]  = MAT_PSUM_BANK_DATA_I[`PSUM_WIDTH*n +: `PSUM_WIDTH];
            assign mat_psum_valid[0][n] = MAT_PSUM_BANK_VALID_I[n];
            assign mat_psum_addr[0][n]  = MAT_PSUM_BANK_ADDR_I[`ADDR_WIDTH*n +: `ADDR_WIDTH];
        end

        // Generate PE instances and wire them up
        for (m = 0; m < `PE_ROW; m = m + 1) begin: G_PE_ROW
            for (n = 0; n < `PE_COL; n = n + 1) begin: G_PE_COL
                systolic_pe U_PE(
                    .CLK                (CLK),
                    .RST_N              (RST_N),
                    
                    // Matrix A connections (from left)
                    .MAT_A_VALID_I      (mat_a_valid[m][n]),
                    .MAT_A_DATA_I       (mat_a_data[m][n]),

                    // Matrix A outputs (to right)
                    .MAT_A_VALID_O      (mat_a_valid[m][n+1]),
                    .MAT_A_O            (mat_a_data[m][n+1]),
                    
                    // Matrix B connections (from top)
                    .PE_ROW_ID_I        (m), // PE's own row ID
                    .MAT_B_PE_ROW_ID_I  (mat_b_pe_row_id[m][n]),
                    .MAT_B_VALID_I      (mat_b_valid[m][n]),
                    .MAT_B_DATA_I       (mat_b_data[m][n]),

                    // Matrix B outputs (to bottom)
                    .MAT_B_PE_ROW_ID_O  (mat_b_pe_row_id[m+1][n]),
                    .MAT_B_VALID_O      (mat_b_valid[m+1][n]),
                    .MAT_B_O            (mat_b_data[m+1][n]),
                    
                    // PSUM connections (from top)
                    .MAT_PSUM_VALID_I   (mat_psum_valid[m][n]),
                    .MAT_PSUM_ADDR_I    (mat_psum_addr[m][n]),
                    .MAT_PSUM_DATA_I    (mat_psum_data[m][n]),

                    // PSUM outputs (to bottom)
                    .MAT_PSUM_VALID_O   (mat_psum_valid[m+1][n]),
                    .MAT_PSUN_ADDR_O    (mat_psum_addr[m+1][n]),
                    .MAT_PSUM_DATA_O    (mat_psum_data[m+1][n])
                );
            end
        end

        // Connect outputs from the last row
        for (n = 0; n < `PE_COL; n = n + 1) begin
            assign MAT_PSUM_BANK_VALID_O[n] = mat_psum_valid[`PE_ROW][n];
            assign MAT_PSUN_BANK_ADDR_O[`ADDR_WIDTH*n +: `ADDR_WIDTH] = mat_psum_addr[`PE_ROW][n];
            assign MAT_PSUM_BANK_DATA_O[`PSUM_WIDTH*n +: `PSUM_WIDTH] = mat_psum_data[`PE_ROW][n];
        end
    endgenerate
endmodule
