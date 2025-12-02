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

        repeat(10) @(posedge CLK);
        RST_N <= 1;

        dim_m = 80;
        dim_k = 80;
        dim_n = 80;

        mat_a = new("mat_a", dim_m, dim_k);
        mat_b = new("mat_b", dim_k, dim_n);

        mat_a.gen_rand();
        mat_b.gen_rand();

        mat_a.display();
        mat_b.display();

        set_param(`PARAM_M, dim_m);
        set_param(`PARAM_N, dim_n);
        set_param(`PARAM_K, dim_k);

        store_mat_a_sram(mat_a, dim_m, dim_n, dim_k);
        store_mat_b_sram(mat_b, dim_m, dim_n, dim_k);

        start_matmul();
        show_dut_matmul(dim_m, dim_n);

         // check golden reference
         mat_a.multiply(mat_b);

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
