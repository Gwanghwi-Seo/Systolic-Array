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
        bit [`BANK_NUM_WIDTH-1:0] bank_num,
        bit [`ADDR_WIDTH-1:0] addr,
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
        bit [`BANK_NUM_WIDTH-1:0] bank_num,
        bit [`ADDR_WIDTH-1:0] addr
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
        for (int i = 0; i < `PE_ROW; i++) begin
            for (int j = 0; j < `PE_ROW; j++) begin
                // trg, bank, addr, data
                store_sram(`TRG_ISRAM, i, j, (i+1));
            end
        end

        for (int i = 0; i < `PE_COL; i++) begin
            for (int j = 0; j < `PE_ROW; j++) begin
                // trg, bank, addr, data
                store_sram(`TRG_WSRAM, i, j, (i+1));
            end
        end

        start_matmul();

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
