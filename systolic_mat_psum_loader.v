`include "systolic.vh"

module systolic_mat_psum_loader (
    input                            CLK,
    input                            RST_N,   

    input [`PE_COL-1:0]              MAT_PSUM_VALID_I,
    input [`ADDR_WIDTH*`PE_COL-1:0]  MAT_PSUM_ADDR_I,
    input [`PSUM_WIDTH*`PE_COL-1:0]  MAT_PSUM_I,

    output [`PE_COL-1:0]             MAT_PSUM_VALID_O,
    output [`ADDR_WIDTH*`PE_COL-1:0] MAT_PSUM_ADDR_O,
    output [`PSUM_WIDTH*`PE_COL-1:0] MAT_PSUM_O
);

genvar i;
generate
    for (i = 0; i < `PE_COL; i = i+1) begin: G_MAT_PSUM_LOADER_LINE
        systolic_mat_psum_delay_line #(
            .DEPTH (i+1)
        ) U_MAT_PSUM_LOADER_LINE (
            .CLK      (CLK),
            .RST_N    (RST_N),

            .VALID_I  (MAT_PSUM_VALID_I[i]),
            .ADDR_I   (MAT_PSUM_ADDR_I[`ADDR_WIDTH*i +: `ADDR_WIDTH]),
            .PSUM_I   (MAT_PSUM_I[`PSUM_WIDTH*i +: `PSUM_WIDTH]),

            .VALID_O  (MAT_PSUM_VALID_O[i]),
            .ADDR_O   (MAT_PSUM_ADDR_O[`ADDR_WIDTH*i +: `ADDR_WIDTH]),
            .PSUM_O   (MAT_PSUM_O[`PSUM_WIDTH*i +: `PSUM_WIDTH])
        );
    end
endgenerate

endmodule