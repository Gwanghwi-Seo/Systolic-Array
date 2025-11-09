`include "systolic.vh"

module systolic_mat_a_loader (
    input                              CLK,
    input                              RST_N,

    // Data from Memory/Previous Stage
    input  [`PE_ROW-1:0]               LOADER_MAT_A_VALID_I,
    input  [`PE_ROW*`DATA_WIDTH-1:0]   LOADER_MAT_A_DATA_I,

    // Data to Systolic Array PEs
    output [`PE_ROW-1:0]               LOADER_MAT_A_VALID_O,
    output [`PE_ROW*`DATA_WIDTH-1:0]   LOADER_MAT_A_DATA_O
);

    genvar i;
    generate
        for (i = 0; i < `PE_ROW; i = i+1) begin: G_MAT_A_LOADER_LINE
            systolic_mat_a_delay_line #(
                .DEPTH      (i+1)
            ) U_MAT_A_LOADER_LINE (
                .CLK        (CLK),
                .RST_N      (RST_N),
                .VALID_I    (LOADER_MAT_A_VALID_I[i]),
                .DATA_I     (LOADER_MAT_A_DATA_I[`DATA_WIDTH*i +: `DATA_WIDTH]),

                .VALID_O    (LOADER_MAT_A_VALID_O[i]),
                .DATA_O     (LOADER_MAT_A_DATA_O[`DATA_WIDTH*i +: `DATA_WIDTH])
            );
        end
    endgenerate

    `ifdef SIM
        wire                   sim_mat_a_valid_i[0:`PE_ROW-1];
        wire [`DATA_WIDTH-1:0] sim_mat_a_i[0:`PE_ROW-1];

        wire                   sim_mat_a_valid_o[0:`PE_ROW-1];
        wire [`DATA_WIDTH-1:0] sim_mat_a_o[0:`PE_ROW-1];

        generate
            for (i = 0; i < `PE_ROW; i = i+1) begin
                assign sim_mat_a_valid_i[i] = LOADER_MAT_A_VALID_I[i];
                assign sim_mat_a_i[i] = LOADER_MAT_A_DATA_I[`DATA_WIDTH*i +: `DATA_WIDTH];

                assign sim_mat_a_valid_o[i] = LOADER_MAT_A_VALID_O[i];
                assign sim_mat_a_o[i] = LOADER_MAT_A_DATA_O[`DATA_WIDTH*i +: `DATA_WIDTH];
            end
        endgenerate
    `endif
endmodule