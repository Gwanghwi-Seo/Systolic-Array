`timescale 1ns/1ps

`include "systolic.vh"
`include "tb_util.svh"
`include "common_var.svh"

module tb_top;
    int dim_m, dim_n, dim_k;

    // handle declaration
    Matrix #(.WIDTH(`DATA_WIDTH)) mat_a;
    Matrix #(.WIDTH(`DATA_WIDTH)) mat_b;
    Matrix #(.WIDTH(`PSUM_WIDTH)) mat_c;

    `ifdef VCS
        initial begin
            $fsdbDumpvars(0, tb_top, "+all");
        end
    `endif

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end


    initial begin
        RST_N <= 0;
        REQ_CPU_OPC_I <= 'h0;
        REQ_CPU_DATA_I <= 'h0;

        dim_m = 8;
        dim_n = 8;
        dim_k = 8;

        mat_a = new("mat_a", dim_m, dim_k);
        mat_b = new("mat_b", dim_k, dim_n);

        mat_a.gen_rand();
        mat_b.gen_rand();

        mat_a.display();
        mat_b.display();

        load_mat_a_sram(mat_a, dim_m, dim_n, dim_k);
        load_mat_b_sram(mat_b, dim_m, dim_n, dim_k);
            
        repeat(10) @(posedge CLK);
        RST_N <= 1;


        // do begin
        //     @(posedge CLK);
        // end while (!CPL_CPU_VALID_O);

        // $display("==============================================");
        // $display("DUT Matrix C");
        // $display("==============================================");
        // for (int m = 0; m < `PE_ROW; m++) begin
        //     for (int n = 0; n < `PE_COL; n++) begin
        //         load_sram(`TRG_PSRAM, m, n);

        //         do begin
        //             @(posedge CLK);
        //         end while (!CPL_CPU_VALID_O);
        //         
        //         $write("%d ", $signed(CPL_CPU_DATA_O[`PSUM_WIDTH-1:0]));
        //     end
        //     $display("");
        // end

        repeat(10) @(posedge CLK);
        $finish;
    end

    systolic U_DUT (
        .CLK               (CLK),
        .RST_N             (RST_N),

        .REQ_CPU_OPC_I     (REQ_CPU_OPC_I),
        .REQ_CPU_VALID_I   (REQ_CPU_VALID_I),
        .REQ_CPU_READY_O   (REQ_CPU_READY_O),
        .REQ_CPU_DATA_I    (REQ_CPU_DATA_I),

        .CPL_CPU_VALID_O   (CPL_CPU_VALID_O),
        // .CPL_CPU_READY_I   (),
        .CPL_CPU_DATA_O    (CPL_CPU_DATA_O)
    );

endmodule
