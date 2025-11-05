// pe.v (수정 완료)
`include "systolic.vh"

module systolic_pe (
    input                                   CLK,
    input                                   RST_N,

    // matrix A
    input                                   MAT_A_VALID_I,
    input signed [`DATA_WIDTH-1:0]          MAT_A_DATA_I,

    output reg                              MAT_A_VALID_O,
    output reg [`DATA_WIDTH-1:0]            MAT_A_DATA_O,
    
    // matrix B (weight stationary)
    input [`PE_ROW_ID_WIDTH-1:0]            PE_ROW_ID_I,
    input [`PE_ROW_ID_WIDTH-1:0]            MAT_B_PE_ROW_ID_I,
    input                                   MAT_B_VALID_I,
    input signed [`DATA_WIDTH-1:0]          MAT_B_DATA_I,

    output reg [`PE_ROW_ID_WIDTH-1:0]       MAT_B_PE_ROW_ID_O,
    output reg                              MAT_B_VALID_O,
    output reg [`DATA_WIDTH-1:0]            MAT_B_DATA_O,

    // psum
    input                                   MAT_PSUM_VALID_I,
    input [`ADDR_WIDTH-1:0]                 MAT_PSUM_ADDR_I,
    input signed [`PSUM_WIDTH-1:0]          MAT_PSUM_DATA_I,

    output reg                              MAT_PSUM_VALID_O,
    output reg [`ADDR_WIDTH-1:0]            MAT_PSUM_ADDR_O,
    output reg signed [`PSUM_WIDTH-1:0]     MAT_PSUM_DATA_O
);

    reg signed [`DATA_WIDTH-1:0] mat_b_data_r; // Captured matrix B element

    wire set_weight;
    wire en_mac;

    assign set_weight = MAT_B_VALID_I & (MAT_B_PE_ROW_ID_I == PE_ROW_ID_I);
    assign en_mac = MAT_A_VALID_I & MAT_PSUM_VALID_I;

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            MAT_A_DATA_O <= 'h0;
            MAT_A_VALID_O <= 1'b0;

            MAT_B_DATA_O <= 'h0;
            MAT_B_VALID_O <= 1'b0;
            MAT_B_PE_ROW_ID_O <= 'h0;

            MAT_PSUM_DATA_O <= 'h0;
            MAT_PSUM_VALID_O <= 1'b0;
            MAT_PSUM_ADDR_O <= 'h0;
        end
        else begin
            // Pass-through logic (systolic shift)
            MAT_A_DATA_O <= MAT_A_DATA_I;
            MAT_A_VALID_O <= MAT_A_VALID_I;

            MAT_B_DATA_O <= MAT_B_DATA_I;
            MAT_B_VALID_O <= MAT_B_VALID_I;
            MAT_B_PE_ROW_ID_O <= MAT_B_PE_ROW_ID_I;

            // psum pass-through is handled in the calculation block
            MAT_PSUM_VALID_O <= MAT_PSUM_VALID_I;
            MAT_PSUM_ADDR_O <= MAT_PSUM_ADDR_I;

            // Weight loading
            if (set_weight) begin
                mat_b_data_r <= MAT_B_DATA_I;
            end
            
            // MAC operation
            if (en_mac) begin
                MAT_PSUM_DATA_O <= MAT_A_DATA_I * mat_b_data_r + MAT_PSUM_DATA_I;
            end
            else begin
                MAT_PSUM_DATA_O <= MAT_PSUM_DATA_I; // Pass psum if not multiplying
            end
        end
    end
endmodule
