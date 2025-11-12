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

    // logic signed [7:0] mat_a[`PE_ROW][`PE_COL];
    // logic signed [7:0] mat_b[`PE_ROW][`PE_COL];
    // logic signed [23:0] mat_c[`PE_ROW][`PE_COL];

    logic signed [`DATA_WIDTH-1:0] mat_a[`PE_ROW][`PE_COL];
    logic signed [`DATA_WIDTH-1:0] mat_b[`PE_ROW][`PE_COL];
    logic signed [`PSUM_WIDTH-1:0] mat_c[`PE_ROW][`PE_COL];


    `ifdef VCS
        initial begin
            $fsdbDumpvars(0, tb_top, "+all");
        end
    `endif

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

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

        REQ_CPU_OPC_I <= `OPC_LD_SRAM;
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

    initial begin
        RST_N <= 0;
        REQ_CPU_OPC_I <= 'h0;
        REQ_CPU_DATA_I <= 'h0;

        repeat(10) @(posedge CLK);
        RST_N <= 1;

        set_param(`PARAM_M, `PE_ROW);
        set_param(`PARAM_N, `PE_COL);
        set_param(`PARAM_K, `PE_ROW);

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

        start_matmul();

        do begin
            @(posedge CLK);
        end while (!CPL_CPU_VALID_O);

        $display("==============================================");
        $display("Matrix A");
        $display("==============================================");
        for (int m = 0; m < `PE_ROW; m++) begin
            for (int k = 0; k < `PE_COL; k++) begin
                $write("%d ", mat_a[m][k]);
            end
            $display("");
        end

        $display("==============================================");
        $display("Matrix B");
        $display("==============================================");
        for (int k = 0; k < `PE_ROW; k++) begin
            for (int n = 0; n < `PE_COL; n++) begin
                $write("%d ", mat_b[k][n]);
            end
            $display("");
        end

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


//`timescale 1ns/1ps
//
//// Include all parameter definitions (PE_ROW, PE_COL, OPC_*, etc.)
//`include "systolic.vh"
//
//module tb_top;
//
//    logic CLK;
//    logic RST_N;
//
//    // Top IF (DUT Interface)
//    logic [`OPC_WIDTH-1:0]   REQ_CPU_OPC_I;
//    logic                    REQ_CPU_VALID_I;
//    wire                     REQ_CPU_READY_O; // Changed to wire
//    logic [`REQ_WIDTH-1:0]   REQ_CPU_DATA_I;
//
//    wire                     CPL_CPU_VALID_O; // Changed to wire
//    // logic                CPL_CPU_READY_I; // Not used
//    wire [`REQ_WIDTH-1:0]    CPL_CPU_DATA_O; // Changed to wire
//
//    // Local arrays for software model (golden reference)
//    // We use dynamic arrays to handle variable M, K, N
//    logic signed [`DATA_WIDTH-1:0] mat_a_sw[][];
//    logic signed [`DATA_WIDTH-1:0] mat_b_sw[][];
//    logic signed [`PSUM_WIDTH-1:0] mat_c_golden[][];
//    logic signed [`PSUM_WIDTH-1:0] mat_c_dut[][];
//
//// =================================================================
//// Clock and Waveform Dumping
//// =================================================================
//
//    `ifdef VCS
//        initial begin
//            $fsdbDumpvars(0, tb_top, "+all");
//        end
//    `endif
//
//    initial begin
//        CLK = 0;
//        forever #5 CLK = ~CLK;
//    end
//
//// =================================================================
//// Re-usable Tasks (from user)
//// =================================================================
//
//    task automatic set_param(
//        input logic [`PARAM_TRG_WIDTH-1:0] param_type,
//        input logic [`PARAM_WIDTH-1:0] param_data
//    );
//        do begin
//            @(posedge CLK);
//        end while(!REQ_CPU_READY_O);
//
//        REQ_CPU_OPC_I <= `OPC_SET_PARAM;
//        REQ_CPU_VALID_I <= 1'b1;
//        REQ_CPU_DATA_I  <= '0; // Clear previous data
//        REQ_CPU_DATA_I[`PARAM_TRG_OFFSET +: `PARAM_TRG_WIDTH] <= param_type;
//        REQ_CPU_DATA_I[`PARAM_OFFSET +: `PARAM_WIDTH] <= param_data;
//
//        @(posedge CLK);
//        REQ_CPU_VALID_I <= 1'b0;
//        REQ_CPU_DATA_I  <= '0;
//        REQ_CPU_OPC_I   <= '0;
//    endtask
//
//    task automatic get_param(
//        input logic [`PARAM_TRG_WIDTH-1:0] trg
//    );
//        do begin
//            @(posedge CLK);
//        end while(!REQ_CPU_READY_O);
//
//        REQ_CPU_OPC_I <= `OPC_GET_PARAM;
//        REQ_CPU_VALID_I <= 1'b1;
//        REQ_CPU_DATA_I  <= '0; // Clear previous data
//        REQ_CPU_DATA_I[`PARAM_TRG_OFFSET +: `PARAM_TRG_WIDTH] <= trg;
//
//        @(posedge CLK);
//        REQ_CPU_VALID_I <= 1'b0;
//        REQ_CPU_OPC_I   <= '0;
//    endtask
//
//    task automatic store_sram (
//        input logic [`SRAM_TRG_WIDTH-1:0] trg,
//        input logic [`BANK_NUM_WIDTH-1:0] bank_num,
//        input logic [`ADDR_WIDTH-1:0] addr,
//        input logic signed [`DATA_WIDTH-1:0] data // Made signed
//    );
//        do begin
//            @(posedge CLK);
//        end while(!REQ_CPU_READY_O);
//
//        REQ_CPU_OPC_I <= `OPC_ST_SRAM;
//        REQ_CPU_VALID_I <= 1'b1;
//        REQ_CPU_DATA_I  <= '0; // Clear previous data
//        REQ_CPU_DATA_I[`SRAM_TRG_OFFSET +: `SRAM_TRG_WIDTH] <= trg;
//        REQ_CPU_DATA_I[`BANK_NUM_OFFSET +: `BANK_NUM_WIDTH] <= bank_num;
//        REQ_CPU_DATA_I[`ADDR_OFFSET     +: `ADDR_WIDTH]     <= addr;
//        REQ_CPU_DATA_I[`DATA_OFFSET     +: `DATA_WIDTH]     <= data;
//
//        @(posedge CLK);
//        REQ_CPU_VALID_I <= 1'b0;
//        REQ_CPU_OPC_I   <= '0;
//    endtask
//
//    task automatic load_sram (
//        input logic [`SRAM_TRG_WIDTH-1:0] trg,
//        input logic [`BANK_NUM_WIDTH-1:0] bank_num,
//        input logic [`ADDR_WIDTH-1:0] addr
//    );
//        do begin
//            @(posedge CLK);
//        end while(!REQ_CPU_READY_O);
//
//        REQ_CPU_OPC_I <= `OPC_LD_SRAM;
//        REQ_CPU_VALID_I <= 1'b1;
//        REQ_CPU_DATA_I  <= '0; // Clear previous data
//        REQ_CPU_DATA_I[`SRAM_TRG_OFFSET +: `SRAM_TRG_WIDTH] <= trg;
//        REQ_CPU_DATA_I[`BANK_NUM_OFFSET +: `BANK_NUM_WIDTH] <= bank_num;
//        REQ_CPU_DATA_I[`ADDR_OFFSET     +: `ADDR_WIDTH]     <= addr;
//
//        @(posedge CLK);
//        REQ_CPU_VALID_I <= 1'b0;
//        REQ_CPU_OPC_I   <= '0;
//    endtask
//
//    task automatic start_matmul();
//        do begin
//            @(posedge CLK);
//        end while(!REQ_CPU_READY_O);
//
//        REQ_CPU_OPC_I <= `OPC_MATMUL;
//        REQ_CPU_VALID_I <= 1'b1;
//        REQ_CPU_DATA_I <= '0;
//
//        @(posedge CLK);
//        REQ_CPU_VALID_I <= 1'b0;
//        REQ_CPU_OPC_I   <= '0;
//    endtask
//
//// =================================================================
//// Helper functions for Test & Debugging
//// =================================================================
//
//    // Software model for matrix multiplication
//    task automatic sw_matmul(int M, int K, int N);
//        $display("[TB] Calculating golden reference...");
//        for (int m = 0; m < M; m++) begin
//            for (int n = 0; n < N; n++) begin
//                mat_c_golden[m][n] = 0; // Init accumulator
//                for (int k = 0; k < K; k++) begin
//                    mat_c_golden[m][n] += mat_a_sw[m][k] * mat_b_sw[k][n];
//                end
//            end
//        end
//        $display("[TB] Golden reference calculation complete.");
//    endtask 
//
//    // Helper task to print a matrix
//    task automatic print_matrix(int M, int N, logic signed [`PSUM_WIDTH-1:0] matrix[][]);
//        for (int m = 0; m < M; m++) begin
//            string s = "";
//            for (int n = 0; n < N; n++) begin
//                s = {s, $sformatf("%5d ", matrix[m][n])};
//            end
//            $display(s);
//        end
//    endtask
//
//// =================================================================
//// MAIN TEST TASK: run_matmul_test
//// =================================================================
//    task automatic run_matmul_test(input int M, int K, int N);
//        int error_count = 0;
//
//        $display("===============================================================");
//        $display("--- Starting Test: (M=%0d, K=%0d, N=%0d) ---", M, K, N);
//        $display("===============================================================");
//
//        // 1. Allocate and fill software matrices
//        mat_a_sw = new[M];
//        mat_b_sw = new[K];
//        mat_c_golden = new[M];
//        mat_c_dut = new[M];
//        
//        foreach (mat_a_sw[i]) mat_a_sw[i] = new[K];
//        foreach (mat_b_sw[i]) mat_b_sw[i] = new[N];
//        foreach (mat_c_golden[i]) mat_c_golden[i] = new[N];
//        foreach (mat_c_dut[i]) mat_c_dut[i] = new[N];
//
//        $display("[TB] 1. Generating test data...");
//        for (int m = 0; m < M; m++) for (int k = 0; k < K; k++) mat_a_sw[m][k] = (m+k+1) % 20; // Simple pattern
//        for (int k = 0; k < K; k++) for (int n = 0; n < N; n++) mat_b_sw[k][n] = (k+n+2) % 20; // Simple pattern
//
//        // 2. Calculate golden reference
//        sw_matmul(M, K, N);
//        
//        // 3. Set DUT parameters
//        $display("[TB] 2. Setting DUT parameters (M, K, N)...");
//        set_param(`PARAM_M, M);
//        set_param(`PARAM_N, N);
//        set_param(`PARAM_K, K);
//
//        // 4. Fill DUT SRAMs
//        $display("[TB] 3. Filling ISRAM (Matrix A)...");
//        for (int m = 0; m < M; m++) begin
//            for (int k = 0; k < K; k++) begin
//                // ISRAM Mapping: A[m][k] -> bank=k, addr=m
//                store_sram(`TRG_ISRAM, k, m, mat_a_sw[m][k]);
//            end
//        end
//
//        $display("[TB] 4. Filling WSRAM (Matrix B)...");
//        for (int k = 0; k < K; k++) begin
//            for (int n = 0; n < N; n++) begin
//                // WSRAM Mapping: B[k][n] -> bank=n, addr=k
//                store_sram(`TRG_WSRAM, n, k, mat_b_sw[k][n]);
//            end
//        end
//
//        // 5. Start DUT
//        $display("[TB] 5. Starting MATMUL...");
//        start_matmul();
//
//        // 6. Wait for MATMUL to complete
//        do begin
//            @(posedge CLK);
//        end while (!CPL_CPU_VALID_O);
//        $display("[TB] 6. MATMUL Complete signal received from DUT.");
//
//        // 7. Read back result matrix from DUT
//        $display("[TB] 7. Reading back PSRAM (Matrix C)...");
//        for (int m = 0; m < M; m++) begin
//            for (int n = 0; n < N; n++) begin
//                // PSRAM Mapping: C[m][n] -> bank=n, addr=m
//                load_sram(`TRG_PSRAM, n, m);
//                
//                // Wait for the CPL packet with the data
//                do begin
//                    @(posedge CLK);
//                end while (!CPL_CPU_VALID_O);
//                
//                mat_c_dut[m][n] = CPL_CPU_DATA_O[`PSUM_WIDTH-1:0];
//            end
//        end
//
//        // 8. Compare results
//        $display("[TB] 8. Comparing results...");
//        for (int m = 0; m < M; m++) begin
//            for (int n = 0; n < N; n++) begin
//                if (mat_c_dut[m][n] != mat_c_golden[m][n]) begin
//                    $error("[FAIL] Mismatch at C[%0d][%0d]: Golden=%0d, DUT=%0d", m, n, mat_c_golden[m][n], mat_c_dut[m][n]);
//                    error_count++;
//                end
//            end
//        end
//
//        // 9. Print results for debugging
//        $display("--- Golden Result (SW) ---");
//        print_matrix(M, N, mat_c_golden);
//        $display("--- DUT Result (HW) ---");
//        print_matrix(M, N, mat_c_dut);
//
//        if (error_count == 0) begin
//            $display("[PASS] Test (M=%0d, K=%0d, N=%0d) Passed!", M, K, N);
//        end else begin
//            $error("[FAIL] Test (M=%0d, K=%0d, N=%0d) Failed with %0d errors.", M, K, N, error_count);
//        end
//        $display("===============================================================\n");
//
//    endtask
//
//// =================================================================
//// Main Test Sequence
//// =================================================================
//    initial begin
//        // Reset sequence
//        RST_N <= 1'b0;
//        REQ_CPU_OPC_I <= '0;
//        REQ_CPU_DATA_I <= '0;
//        REQ_CPU_VALID_I <= 1'b0;
//        repeat(10) @(posedge CLK);
//        RST_N <= 1'b1;
//        $display("Time %t: [TB] Reset Released.", $time);
//
//        // --- Run Tests ---
//        
//        // Test 1: Full tile (assuming PE_ROW=8, PE_COL=4 for this example)
//        run_matmul_test(`PE_ROW, `PE_ROW, `PE_COL);
//        
//        // Test 2: Remainder case (M=5, K=5, N=3)
//        run_matmul_test(5, 5, 3);
//        
//        // Test 3: Large case (testing tiling logic)
//        run_matmul_test(10, 12, 6);
//
//        // --- End Simulation ---
//        repeat(10) @(posedge CLK);
//        $display("All tests complete.");
//        $finish;
//    end
//
//// =================================================================
//// DUT Instantiation
//// =================================================================
//    systolic U_DUT (
//        .CLK             (CLK),
//        .RST_N           (RST_N),
//        .REQ_CPU_OPC_I   (REQ_CPU_OPC_I),
//        .REQ_CPU_VALID_I (REQ_CPU_VALID_I),
//        .REQ_CPU_READY_O (REQ_CPU_READY_O),
//        .REQ_CPU_DATA_I  (REQ_CPU_DATA_I),
//        .CPL_CPU_VALID_O (CPL_CPU_VALID_O),
//        // .CPL_CPU_READY_I (1'b1), // Tie off CPL_READY to 1 (assuming DUT doesn't use it)
//        .CPL_CPU_DATA_O  (CPL_CPU_DATA_O)
//    );
//
//endmodule

