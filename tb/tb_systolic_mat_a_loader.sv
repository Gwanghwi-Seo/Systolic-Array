`timescale 1ns / 1ps

`include "../systolic.vh"

module tb_systolic_mat_a_loader;
    logic                             CLK;
    logic                             RST_N;

    logic [`PE_ROW-1:0]               MAT_A_VALID_I ;
    logic [`PE_ROW*`DATA_WIDTH-1:0]   MAT_A_I       ;

    wire [`PE_ROW-1:0]                MAT_A_VALID_O ;
    wire [`PE_ROW*`DATA_WIDTH-1:0]    MAT_A_O       ;
    
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end

    initial begin
        MAT_A_VALID_I <= 'h0;
        MAT_A_I <= 'h0;
        RST_N <= 1'b0;

        repeat(10) @(posedge CLK);
        RST_N <= 1'b1;

        for (integer i = 0; i < `PE_ROW; i++) begin
            MAT_A_VALID_I <= (1 << `PE_ROW) - 1;

            for (integer j = 0; j < `PE_ROW; j++) begin
                MAT_A_I[`DATA_WIDTH*j +: `DATA_WIDTH] <= i+1;
            end

            @(posedge CLK);
        end

        MAT_A_VALID_I <= 'h0;
        repeat(10) @(posedge CLK);
        $finish;
    end

    systolic_mat_a_loader U_DUT (
        .CLK            (CLK            ),
        .RST_N          (RST_N          ),
        .MAT_A_VALID_I  (MAT_A_VALID_I  ),
        .MAT_A_I        (MAT_A_I        ),
        .MAT_A_VALID_O  (MAT_A_VALID_O  ),
        .MAT_A_O        (MAT_A_O        )
    );

endmodule