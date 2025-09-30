`include "systolic.vh"

module systolic_mat_a_loader (
    input                              CLK,
    input                              RST_N,

    // Data from Memory/Previous Stage
    input  [`PE_ROW-1:0]               MAT_A_VALID_I,
    input  [`PE_ROW*`DATA_WIDTH-1:0]   MAT_A_I,

    // Data to Systolic Array PEs
    output [`PE_ROW-1:0]               MAT_A_VALID_O,
    output [`PE_ROW*`DATA_WIDTH-1:0]   MAT_A_O
);

    // Pipeline registers for both Data and its Validity signal
    reg [`DATA_WIDTH-1:0] mat_a_data_r [0:`PE_ROW-1][0:`PE_ROW-1];
    reg                   mat_a_valid_r[0:`PE_ROW-1][0:`PE_ROW-1];

    integer row, col;

    // Sequential logic for the pipeline registers
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            // Reset all registers to 0
            for (row = 0; row < `PE_ROW; row = row + 1) begin
                for (col = 1; col < row; col = col + 1) begin
                    mat_a_data_r[row][col]  <= 'h0;
                    mat_a_valid_r[row][col] <= 1'b0;
                end
            end
        end
        else begin
            for (row = 0; row < `PE_ROW; row = row + 1) begin
                // Stage 0: Load new data from input
                mat_a_data_r[row][0]  <= MAT_A_I[`DATA_WIDTH*row +: `DATA_WIDTH];
                mat_a_valid_r[row][0] <= MAT_A_VALID_I[row];

                // Stage 1 to N: Shift data and valid signal from the previous stage
                for (col = 1; col < row; col = col + 1) begin
                    mat_a_data_r[row][col]  <= mat_a_data_r[row][col-1];
                    mat_a_valid_r[row][col] <= mat_a_valid_r[row][col-1];
                end
            end
        end
    end

    genvar k;
    generate
        for (k = 0; k < `PE_ROW; k = k + 1) begin : gen_output_logic
            assign MAT_A_O[`DATA_WIDTH*k +: `DATA_WIDTH]  = mat_a_data_r[k][k];
            assign MAT_A_VALID_O[k]                       = mat_a_valid_r[k][k];
        end
    endgenerate

endmodule