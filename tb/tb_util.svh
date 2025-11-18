`include "common_var.svh"

class Matrix #(parameter WIDTH = 8);
    rand bit signed [WIDTH-1:0] data[][];
    
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
                line = {line, $sformatf("%5d ", data[i][j])};
            end
            $display(line);
        end
        $display("------------------------\n");
    endfunction

    function Matrix#(WIDTH) multiply(Matrix#(WIDTH) B);
        Matrix#(PSUM_WIDTH) C;
        
        if (this.cols != B.rows) begin
            $error("[MatMul Error] Dimension Mismatch: (%0dx%0d) * (%0dx%0d)", 
                   this.rows, this.cols, B.rows, B.cols);
            return null;
        end

        // 결과 행렬 C 생성 (this.Rows x B.Cols)
        // PSUM_WIDTH 등 오버플로우 고려가 필요하다면 파라미터 조정 필요하지만,
        // 여기서는 기능 구현에 집중
        C = new("Golden_C", this.rows, B.cols);

        for (int i = 0; i < this.rows; i++) begin
            for (int j = 0; j < B.cols; j++) begin
                int sum = 0;
                for (int k = 0; k < this.cols; k++) begin
                    sum += this.data[i][k] * B.data[k][j];
                end
                C.data[i][j] = sum;
            end
        end
        
        return C;
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
    do begin
        @(posedge CLK);
    end while(!REQ_CPU_READY_O);

    REQ_CPU_OPC_I <= `OPC_MATMUL;
    REQ_CPU_VALID_I <= 1'b1;
    REQ_CPU_DATA_I <= 'h0;

    @(posedge CLK);
    REQ_CPU_VALID_I <= 0;
endtask

function automatic int ceil(int numerator, int denominator);
    return (numerator + denominator - 1) / denominator;
endfunction

task automatic load_mat_a_sram(ref Matrix mat_a, int dim_m, int dim_n, int dim_k);
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
                    
                end
            end
            else begin
                for (int k = 0; k < `PE_ROW; k++) begin
                    
                end
            end
        end
    end
    
endtask

task automatic load_mat_b_sram(ref Matrix mat_b, int dim_m, int dim_n, int dim_k);

endtask