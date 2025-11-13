`timescale 1ns/1ps

`include "systolic.vh"

module tb_top;

    logic CLK;
    logic RST_N;

    // Top IF
    logic [`OPC_WIDTH-1:0]         REQ_CPU_OPC_I            ;
    logic                          REQ_CPU_VALID_I          ;
    logic                          REQ_CPU_READY_O          ;
    logic [`REQ_WIDTH-1:0]         REQ_CPU_DATA_I           ;

    logic                          CPL_CPU_VALID_O          ;
    // logic                          CPL_CPU_READY_I          ;
    logic [`REQ_WIDTH-1:0]         CPL_CPU_DATA_O           ;

    logic signed [`DATA_WIDTH-1:0] mat_a[`PE_ROW][`PE_COL];
    logic signed [`DATA_WIDTH-1:0] mat_b[`PE_ROW][`PE_COL];
    logic signed [`PSUM_WIDTH-1:0] mat_c[`PE_ROW][`PE_COL];

    int dim_m, dim_n, dim_k;

    `ifdef VCS
        initial begin
            $fsdbDumpvars(0, tb_top, "+all");
        end
    `endif

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    task automatic set_param(
        bit [`PARAM_TRG_WIDTH-1:0] param_type,
        bit [`PARAM_WIDTH-1:0] param_data
    );
        do begin
            @(posedge CLK);
        end while(!REQ_CPU_READY_O);

        REQ_CPU_OPC_I <= `OPC_SET_PARAM;
        REQ_CPU_VALID_I <= 1'b1;
        REQ_CPU_DATA_I[`PARAM_TRG_OFFSET +: `PARAM_TRG_WIDTH] <= param_type;
        REQ_CPU_DATA_I[`PARAM_OFFSET +: `PARAM_WIDTH] <= param_data;

        @(posedge CLK);
        REQ_CPU_OPC_I <= 0;
        REQ_CPU_VALID_I <= 0;
        REQ_CPU_DATA_I <= 0;
    endtask

    task automatic get_param(
        bit [`PARAM_TRG_WIDTH-1:0] trg
    );
        do begin
            @(posedge CLK);
        end while(!REQ_CPU_READY_O);

        REQ_CPU_OPC_I <= `OPC_GET_PARAM;
        REQ_CPU_VALID_I <= 1'b1;
        REQ_CPU_DATA_I[`SRAM_TRG_OFFSET +: `SRAM_TRG_WIDTH] <= trg;

        @(posedge CLK);
        REQ_CPU_VALID_I <= 0;

    endtask

    task automatic store_sram (
        bit [`SRAM_TRG_WIDTH-1:0] trg,
        bit [`ADDR_WIDTH-1:0] addr,
        bit [`BANK_NUM_WIDTH-1:0] bank_num,
        bit [`DATA_WIDTH-1:0] data
    );

        do begin
            @(posedge CLK);
        end while(!REQ_CPU_READY_O);

        REQ_CPU_OPC_I <= `OPC_ST_SRAM;
        REQ_CPU_VALID_I <= 1'b1;
        REQ_CPU_DATA_I[`SRAM_TRG_OFFSET +: `SRAM_TRG_WIDTH] <= trg;
        REQ_CPU_DATA_I[`BANK_NUM_OFFSET +: `BANK_NUM_WIDTH] <= bank_num;
        REQ_CPU_DATA_I[`ADDR_OFFSET     +: `ADDR_WIDTH]     <= addr;
        REQ_CPU_DATA_I[`DATA_OFFSET     +: `DATA_WIDTH]     <= data;

        @(posedge CLK);
        REQ_CPU_VALID_I <= 0;
    endtask

    task automatic load_sram (
        bit [`SRAM_TRG_WIDTH-1:0] trg,
        bit [`ADDR_WIDTH-1:0] addr,
        bit [`BANK_NUM_WIDTH-1:0] bank_num
    );
        do begin
            @(posedge CLK);
        end while(!REQ_CPU_READY_O);

        REQ_CPU_OPC_I   <= `OPC_LD_SRAM;
        REQ_CPU_VALID_I <= 1'b1;
        REQ_CPU_DATA_I[`SRAM_TRG_OFFSET +: `SRAM_TRG_WIDTH] <= trg;
        REQ_CPU_DATA_I[`BANK_NUM_OFFSET +: `BANK_NUM_WIDTH] <= bank_num;
        REQ_CPU_DATA_I[`ADDR_OFFSET     +: `ADDR_WIDTH]     <= addr;

        @(posedge CLK);
        REQ_CPU_VALID_I <= 0;
    endtask

    task automatic start_matmul();
        do begin
            @(posedge CLK);
        end while(!REQ_CPU_READY_O);

        REQ_CPU_OPC_I <= `OPC_MATMUL;
        REQ_CPU_VALID_I <= 1'b1;
        REQ_CPU_DATA_I <= 'h0;

        @(posedge CLK);
        REQ_CPU_VALID_I <= 0;
    endtask

    task automatic run_normal_case();
        dim_m = `PE_ROW;
        dim_n = `PE_COL;
        dim_k = `PE_ROW;

        set_param(`PARAM_M, dim_m);
        set_param(`PARAM_N, dim_n);
        set_param(`PARAM_K, dim_k);

        get_param(`PARAM_M);
        get_param(`PARAM_N);
        get_param(`PARAM_K);

        // 8x8 matmul
        for (int m = 0; m < `PE_ROW; m++) begin
            for (int k = 0; k < `PE_ROW; k++) begin
                // trg, addr, bank, data
                logic signed [`DATA_WIDTH-1:0] rand_mat_a;
                rand_mat_a = $random;

                mat_a[m][k] = rand_mat_a;

                // store_sram(`TRG_ISRAM, i, j, (i+1));
                store_sram(`TRG_ISRAM, m, k, rand_mat_a);
            end
        end

        for (int k = 0; k < `PE_COL; k++) begin
            for (int n = 0; n < `PE_ROW; n++) begin
                // trg, bank, addr, data
                logic signed [7:0] rand_mat_b;
                rand_mat_b = $random;

                mat_b[k][n] = rand_mat_b;

                // store_sram(`TRG_WSRAM, i, j, (i+1));
                store_sram(`TRG_WSRAM, k, n, rand_mat_b);
            end
        end
    endtask

    task automatic print_matrix(
        input string name,
        input int    M,
        input int    N,
        input logic signed [`PSUM_WIDTH-1:0] matrix[][]
    );
        $display("==============================================");
        $display("--- %s (Size: %0d x %0d) ---", name, M, N);
        $display("==============================================");

        if (matrix.size() == 0) begin
            $display("  [Matrix is not allocated]");
            $display("==============================================");
            return;
        end

        for (int m = 0; m < M; m++) begin
            string s = ""; // 한 줄을 문자열로 만듭니다.
            for (int n = 0; n < N; n++) begin
                s = {s, $sformatf("%5d ", matrix[m][n])};
            end
            $display(s);
        end
        $display("==============================================================");
    endtask

    initial begin
        RST_N <= 0;
        REQ_CPU_OPC_I <= 'h0;
        REQ_CPU_DATA_I <= 'h0;

        repeat(10) @(posedge CLK);
        RST_N <= 1;

        start_matmul();

        do begin
            @(posedge CLK);
        end while (!CPL_CPU_VALID_O);

        $display("==============================================");
        $display("DUT Matrix C");
        $display("==============================================");
        for (int m = 0; m < `PE_ROW; m++) begin
            for (int n = 0; n < `PE_COL; n++) begin
                load_sram(`TRG_PSRAM, m, n);

                do begin
                    @(posedge CLK);
                end while (!CPL_CPU_VALID_O);
                
                $write("%d ", $signed(CPL_CPU_DATA_O[`PSUM_WIDTH-1:0]));
            end
            $display("");
        end

        $display("==============================================");
        $display("EXP Matrix C");
        $display("==============================================");
        for (int m = 0; m < `PE_ROW; m++)
            for (int n = 0; n < `PE_COL; n++)
                mat_c[m][n] = 0;

        for (int m = 0; m < `PE_ROW; m++) begin
            for (int n = 0; n < `PE_COL; n++) begin
                for (int k = 0; k < `PE_ROW; k++) begin
                    mat_c[m][n] += mat_a[m][k] * mat_b[k][n];
                end
            end
        end

        // display expected matrix C
        for (int m = 0; m < `PE_ROW; m++) begin
            for (int n = 0; n < `PE_COL; n++) begin
                $write("%d ", mat_c[m][n]);
            end
            $display("");
        end

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