`include "systolic.vh"

module systolic_mat_psum_loader (
    input                            CLK,
    input                            RST_N,   

    input [`PE_COL-1:0]              LOADER_MAT_PSUM_VALID_I,
    input [`ADDR_WIDTH*`PE_COL-1:0]  LOADER_MAT_PSUM_ADDR_I,
    input [`PSUM_WIDTH*`PE_COL-1:0]  LOADER_MAT_PSUM_DATA_I,

    output [`PE_COL-1:0]             LOADER_MAT_PSUM_VALID_O,
    output [`ADDR_WIDTH*`PE_COL-1:0] LOADER_MAT_PSUM_ADDR_O,
    output [`PSUM_WIDTH*`PE_COL-1:0] LOADER_MAT_PSUM_DATA_O
);

genvar i;
generate
    for (i = 0; i < `PE_COL; i = i+1) begin: G_MAT_PSUM_LOADER_LINE
        systolic_mat_psum_delay_line #(
            .DEPTH (i+1)
        ) U_MAT_PSUM_LOADER_LINE (
            .CLK      (CLK),
            .RST_N    (RST_N),

            .VALID_I  (LOADER_MAT_PSUM_VALID_I[i]),
            .ADDR_I   (LOADER_MAT_PSUM_ADDR_I[`ADDR_WIDTH*i +: `ADDR_WIDTH]),
            .PSUM_I   (LOADER_MAT_PSUM_DATA_I[`PSUM_WIDTH*i +: `PSUM_WIDTH]),

            .VALID_O  (LOADER_MAT_PSUM_VALID_O[i]),
            .ADDR_O   (LOADER_MAT_PSUM_ADDR_O[`ADDR_WIDTH*i +: `ADDR_WIDTH]),
            .PSUM_O   (LOADER_MAT_PSUM_DATA_O[`PSUM_WIDTH*i +: `PSUM_WIDTH])
        );
    end
endgenerate

`ifdef SIM
    wire                   sim_loader_mat_psum_valid_i[0:`PE_COL-1];
    wire [`ADDR_WIDTH-1:0] sim_loader_mat_psum_addr_i [0:`PE_COL-1];
    wire [`PSUM_WIDTH-1:0] sim_loader_mat_psum_data_i [0:`PE_COL-1];

    wire                   sim_loader_mat_psum_valid_o[0:`PE_COL-1];
    wire [`ADDR_WIDTH-1:0] sim_loader_mat_psum_addr_o [0:`PE_COL-1];
    wire [`PSUM_WIDTH-1:0] sim_loader_mat_psum_data_o [0:`PE_COL-1];

    genvar g;
    generate
        for (g = 0; g < `PE_COL; g = g+1) begin
            assign sim_loader_mat_psum_valid_i[g] = LOADER_MAT_PSUM_VALID_I[g];
            assign sim_loader_mat_psum_addr_i[g] = LOADER_MAT_PSUM_ADDR_I[`ADDR_WIDTH*g +: `ADDR_WIDTH];
            assign sim_loader_mat_psum_data_i[g] = LOADER_MAT_PSUM_DATA_I[`PSUM_WIDTH*g +: `PSUM_WIDTH];

            assign sim_loader_mat_psum_valid_o[g] = LOADER_MAT_PSUM_VALID_O[g];
            assign sim_loader_mat_psum_addr_o[g] = LOADER_MAT_PSUM_ADDR_O[`ADDR_WIDTH*g +: `ADDR_WIDTH];
            assign sim_loader_mat_psum_data_o[g] = LOADER_MAT_PSUM_DATA_O[`PSUM_WIDTH*g +: `PSUM_WIDTH];
        end
    endgenerate
`endif

endmodule