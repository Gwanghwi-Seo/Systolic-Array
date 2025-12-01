`include "common_var.svh"

function automatic int ceil(int numerator, int denominator);
    return (numerator + denominator - 1) / denominator;
endfunction

class Matrix #(parameter WIDTH = 8);
    bit signed [WIDTH-1:0] data[][];
    
    int rows;
    int cols;
    string name;

    function new(string name = "Mat", int r, int c);
        this.name = name;
        this.rows = r;
        this.cols = c;
        
        // Allocate memory
        this.data = new[r];
        foreach (this.data[i]) begin
            this.data[i] = new[c];
        end
    endfunction

    function void gen_rand(int min_val = -(1<<(WIDTH-1)), int max_val = (1<<(WIDTH-1))-1);
        foreach (this.data[i, j]) begin
            this.data[i][j] = $random; 
        end
    endfunction

    function bit signed [WIDTH-1:0] get(int r, int c);
        if (r >= rows || c >= cols) begin
            $error("[%s] Index Out of Bounds: (%0d, %0d)", name, r, c);
            return 0;
        end
        return data[r][c];
    endfunction

    function void display();
        $display("\n--- %s (%0d x %0d) ---", name, rows, cols);
        for (int i = 0; i < rows; i++) begin
            string line = "";
            for (int j = 0; j < cols; j++) begin
                line = {line, $sformatf("%8d ", data[i][j])};
            end
            $display(line);
        end
        $display("------------------------\n");
    endfunction

    function void multiply(ref Matrix B);
        Matrix#(`PSUM_WIDTH) C;

        if (this.cols != B.rows) begin
           $error("[MatMul Error] Dimension Mismatch: (%0dx%0d) * (%0dx%0d)", 
                this.rows, this.cols, B.rows, B.cols);
            $finish(1);
        end

        C = new("Golden_C", this.rows, B.cols);

        for (int i = 0; i < this.rows; i++) begin
            for (int j = 0; j < B.cols; j++) begin
                int sum = 0;
                for (int k = 0; k < this.cols; k++) begin
                    sum += $signed(this.data[i][k]) * $signed(B.data[k][j]);
                end
                C.data[i][j] = sum;
            end
        end

        C.display();
    endfunction
endclass

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
    // do begin
    //     @(posedge CLK);
    // end while(!REQ_CPU_READY_O);

    wait(REQ_CPU_READY_O);
    @(posedge CLK);

    REQ_CPU_OPC_I <= `OPC_MATMUL;
    REQ_CPU_VALID_I <= 1'b1;
    REQ_CPU_DATA_I <= 'h0;

    @(posedge CLK);
    REQ_CPU_VALID_I <= 0;
endtask

task automatic show_dut_matmul(int dim_m, int dim_n);
    int base_psram_addr;
    int psram_addr;
    int psram_bank_num;
    int max_psram_bank_num;

    int n_iter_max;
    int n_rem;
    bit has_n_rem;

    n_iter_max = ceil(dim_n, `PE_COL);
    n_rem = dim_n % `PE_COL;

    if (n_rem != 0)
        has_n_rem = 1;

    $display("==============================================");
    $display("DUT Matrix C");
    $display("==============================================");

    do begin
        @(posedge CLK);
    end while (!CPL_CPU_VALID_O);

    for (int n = 0; n < n_iter_max; n++) begin
        base_psram_addr = n*dim_m;

        for (psram_addr = 0; psram_addr < dim_m; psram_addr++) begin
            if (n == n_iter_max - 1 && has_n_rem)
                max_psram_bank_num = n_rem;
            else
                max_psram_bank_num = `PE_COL;

            for (psram_bank_num = 0; psram_bank_num < max_psram_bank_num; psram_bank_num++) begin
                // TRG, ADDR, BANK#
                load_sram(`TRG_PSRAM, base_psram_addr + psram_addr, psram_bank_num);

                wait(CPL_CPU_VALID_O);
                @(posedge CLK);
                $write("%d ", $signed(CPL_CPU_DATA_O[`PSUM_WIDTH-1:0]));
            end
            $display("----");
        end
    end
endtask


task automatic store_mat_a_sram(ref Matrix mat_a, int dim_m, int dim_n, int dim_k);
    int base_col_idx, col_idx, row_idx;
    
    int max_i = ceil(dim_k, `PE_ROW);

    bit has_i_rem = 0;

    if (dim_k % `PE_ROW != 0)
        has_i_rem = 1'b1;

    for (int i = 0; i < max_i; i++) begin
        base_col_idx = i * `PE_ROW;

        for (int j = 0; j < dim_m; j++) begin
            row_idx = j;

            if (i == max_i - 1 && has_i_rem) begin
                for (int k = 0; k < dim_k % `PE_ROW; k++) begin
                    col_idx = base_col_idx + k;
                    // TRG, ADDR, BANK#, DATA
                    store_sram(`TRG_ISRAM, i*dim_m + row_idx, k, mat_a.get(row_idx, col_idx));
                end
            end
            else begin
                for (int k = 0; k < `PE_ROW; k++) begin
                    col_idx = base_col_idx + k;
                    // TRG, ADDR, BANK#, DATA
                    store_sram(`TRG_ISRAM, i*dim_m + row_idx, k, mat_a.get(row_idx, col_idx));
                end
            end
        end
    end
    
endtask

task automatic store_mat_b_sram(ref Matrix mat_b, int dim_m, int dim_n, int dim_k);
    int base_wsram_addr;
    int base_col_idx;
    int n_rem;
    bit has_n_rem;

    int n_iter_max;
    
    n_iter_max = ceil(dim_n, `PE_COL);

    n_rem = dim_n % `PE_COL;
    if (n_rem != 0)
        has_n_rem = 1;

    for (int n = 0; n < n_iter_max; n++) begin
        for (int k = 0; k < dim_k; k++) begin
            if (n == n_iter_max - 1 && has_n_rem) begin
                for (int col_idx = 0; col_idx < n_rem; col_idx++) begin
                    base_wsram_addr = n*dim_k;
                    base_col_idx = n*`PE_COL;

                    // TRG, ADDR, BANK#, DATA
                    store_sram(`TRG_WSRAM, base_wsram_addr+k, col_idx, mat_b.get(k, base_col_idx+col_idx));
                end
            end
            else begin
                for (int col_idx = 0; col_idx < `PE_COL; col_idx++) begin
                    base_wsram_addr = n*dim_k;
                    base_col_idx = n*`PE_COL;

                    // TRG, ADDR, BANK#, DATA
                    store_sram(`TRG_WSRAM, base_wsram_addr+k, col_idx, mat_b.get(k, base_col_idx+col_idx));
                end
            end
        end
    end

endtask