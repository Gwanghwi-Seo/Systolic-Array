`timescale 1ns/1ps

`include "../systolic.vh"

module tb_systolic_ctrl_decoder;

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

    logic                          REQ_DEC_ISRAM_EN_O       ; // Active low
    logic                          REQ_DEC_ISRAM_WE_O       ;
    logic [`ADDR_WIDTH-1:0]        REQ_DEC_ISRAM_ADDR_O     ;
    logic [`DATA_WIDTH-1:0]        REQ_DEC_ISRAM_WDATA_O    ;
    logic [`BANK_NUM_WIDTH-1:0]    REQ_DEC_ISRAM_BANK_NUM_O ;

    logic                          CPL_DEC_ISRAM_VALID_I    ;
    logic [`DATA_WIDTH-1:0]        CPL_DEC_ISRAM_RDATA_I    ;

    logic                          REQ_DEC_WSRAM_EN_O       ; // Active low
    logic                          REQ_DEC_WSRAM_WE_O       ;
    logic [`ADDR_WIDTH-1:0]        REQ_DEC_WSRAM_ADDR_O     ;
    logic [`DATA_WIDTH-1:0]        REQ_DEC_WSRAM_WDATA_O    ;
    logic [`BANK_NUM_WIDTH-1:0]    REQ_DEC_WSRAM_BANK_NUM_O ;

    logic                          CPL_DEC_WSRAM_VALID_I    ;
    logic [`DATA_WIDTH-1:0]        CPL_DEC_WSRAM_RDATA_I    ;

    logic                          REQ_DEC_PSRAM_EN_O       ; // Active low
    logic                          REQ_DEC_PSRAM_WE_O       ;
    logic [`ADDR_WIDTH-1:0]        REQ_DEC_PSRAM_ADDR_O     ;
    logic [`PSUM_WIDTH-1:0]        REQ_DEC_PSRAM_WDATA_O    ;
    logic [`BANK_NUM_WIDTH-1:0]    REQ_DEC_PSRAM_BANK_NUM_O ;

    logic                          CPL_DEC_PSRAM_VALID_I    ;
    logic [`PSUM_WIDTH-1:0]        CPL_DEC_PSRAM_RDATA_I    ;

    `ifdef VCS
        initial begin
            $fsdbDumpvars(0, tb_systolic_ctrl_decoder, "+all");
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

    initial begin
        RST_N <= 0;
        REQ_CPU_OPC_I <= 'h0;
        REQ_CPU_DATA_I <= 'h0;

        repeat(10) @(posedge CLK);
        RST_N <= 1;

        set_param(`PARAM_M, 5);
        set_param(`PARAM_N, 6);
        set_param(`PARAM_K, 21);

        get_param(`PARAM_M);
        get_param(`PARAM_N);
        get_param(`PARAM_K);

        store_sram(`TRG_ISRAM, 1, 0, 1);
        store_sram(`TRG_ISRAM, 1, 1, 2);
        store_sram(`TRG_ISRAM, 1, 2, 3);
        store_sram(`TRG_ISRAM, 1, 3, 4);
        store_sram(`TRG_ISRAM, 1, 4, 5);

        load_sram(`TRG_ISRAM, 1, 0);
        load_sram(`TRG_ISRAM, 1, 1);
        load_sram(`TRG_ISRAM, 1, 2);
        load_sram(`TRG_ISRAM, 1, 3);
        load_sram(`TRG_ISRAM, 1, 4);

        store_sram(`TRG_ISRAM, `PE_ROW-1, 0, 1);
        store_sram(`TRG_ISRAM, `PE_ROW-1, 1, 2);
        store_sram(`TRG_ISRAM, `PE_ROW-1, 2, 3);
        store_sram(`TRG_ISRAM, `PE_ROW-1, 3, 4);
        store_sram(`TRG_ISRAM, `PE_ROW-1, 4, 5);

        store_sram(`TRG_WSRAM, 1, 0, 1);
        store_sram(`TRG_WSRAM, 1, 1, 2);
        store_sram(`TRG_WSRAM, 1, 2, 3);
        store_sram(`TRG_WSRAM, 1, 3, 4);
        store_sram(`TRG_WSRAM, 1, 4, 5);

        repeat(10) @(posedge CLK);
        $finish;
    end

    systolic_ctrl_decoder U_CTRL_DEC (
        .CLK                      (CLK                      ),
        .RST_N                    (RST_N                    ),

        .REQ_CPU_OPC_I            (REQ_CPU_OPC_I            ), 
        .REQ_CPU_VALID_I          (REQ_CPU_VALID_I          ), 
        .REQ_CPU_READY_O          (REQ_CPU_READY_O          ), 
        .REQ_CPU_DATA_I           (REQ_CPU_DATA_I           ), 
                                   
        .CPL_CPU_VALID_O          (CPL_CPU_VALID_O          ), 
        // .CPL_CPU_READY_I          (CPL_CPU_READY_I          ), 
        .CPL_CPU_DATA_O           (CPL_CPU_DATA_O           ), 
                                   
        .REQ_DEC_ISRAM_EN_O       (REQ_DEC_ISRAM_EN_O       ), 
        .REQ_DEC_ISRAM_WE_O       (REQ_DEC_ISRAM_WE_O       ), 
        .REQ_DEC_ISRAM_ADDR_O     (REQ_DEC_ISRAM_ADDR_O     ), 
        .REQ_DEC_ISRAM_WDATA_O    (REQ_DEC_ISRAM_WDATA_O    ), 
        .REQ_DEC_ISRAM_BANK_NUM_O (REQ_DEC_ISRAM_BANK_NUM_O ), 
                                   
        .CPL_DEC_ISRAM_VALID_I    (CPL_DEC_ISRAM_VALID_I    ), 
        .CPL_DEC_ISRAM_RDATA_I    (CPL_DEC_ISRAM_RDATA_I    ), 
                                   
        .REQ_DEC_WSRAM_EN_O       (REQ_DEC_WSRAM_EN_O       ), 
        .REQ_DEC_WSRAM_WE_O       (REQ_DEC_WSRAM_WE_O       ), 
        .REQ_DEC_WSRAM_ADDR_O     (REQ_DEC_WSRAM_ADDR_O     ), 
        .REQ_DEC_WSRAM_WDATA_O    (REQ_DEC_WSRAM_WDATA_O    ), 
        .REQ_DEC_WSRAM_BANK_NUM_O (REQ_DEC_WSRAM_BANK_NUM_O ), 
                                   
        .CPL_DEC_WSRAM_VALID_I    (CPL_DEC_WSRAM_VALID_I    ), 
        .CPL_DEC_WSRAM_RDATA_I    (CPL_DEC_WSRAM_RDATA_I    ), 
                                   
        .REQ_DEC_PSRAM_EN_O       (REQ_DEC_PSRAM_EN_O       ), 
        .REQ_DEC_PSRAM_WE_O       (REQ_DEC_PSRAM_WE_O       ), 
        .REQ_DEC_PSRAM_ADDR_O     (REQ_DEC_PSRAM_ADDR_O     ), 
        .REQ_DEC_PSRAM_WDATA_O    (REQ_DEC_PSRAM_WDATA_O    ), 
        .REQ_DEC_PSRAM_BANK_NUM_O (REQ_DEC_PSRAM_BANK_NUM_O ), 
                                   
        .CPL_DEC_PSRAM_VALID_I    (CPL_DEC_PSRAM_VALID_I    ), 
        .CPL_DEC_PSRAM_RDATA_I    (CPL_DEC_PSRAM_RDATA_I    ) 
    );

    systolic_sramc U_SRAMC (
        .CLK                      (CLK),
        .RST_N                    (RST_N),
    
        .REQ_DEC_ISRAM_EN_I       (REQ_DEC_ISRAM_EN_O       ),
        .REQ_DEC_ISRAM_WE_I       (REQ_DEC_ISRAM_WE_O       ),
        .REQ_DEC_ISRAM_ADDR_I     (REQ_DEC_ISRAM_ADDR_O     ),
        .REQ_DEC_ISRAM_WDATA_I    (REQ_DEC_ISRAM_WDATA_O    ),
        .REQ_DEC_ISRAM_BANK_NUM_I (REQ_DEC_ISRAM_BANK_NUM_O ),
                                   
        .CPL_DEC_ISRAM_VALID_O    (CPL_DEC_ISRAM_VALID_I    ),
        .CPL_DEC_ISRAM_RDATA_O    (CPL_DEC_ISRAM_RDATA_I    ),
                                   
        .REQ_DEC_WSRAM_EN_I       (REQ_DEC_WSRAM_EN_O       ),
        .REQ_DEC_WSRAM_WE_I       (REQ_DEC_WSRAM_WE_O       ),
        .REQ_DEC_WSRAM_ADDR_I     (REQ_DEC_WSRAM_ADDR_O     ),
        .REQ_DEC_WSRAM_WDATA_I    (REQ_DEC_WSRAM_WDATA_O    ),
        .REQ_DEC_WSRAM_BANK_NUM_I (REQ_DEC_WSRAM_BANK_NUM_O ),
                                   
        .CPL_DEC_WSRAM_VALID_O    (CPL_DEC_WSRAM_VALID_I    ),
        .CPL_DEC_WSRAM_RDATA_O    (CPL_DEC_WSRAM_RDATA_I    ),
                                   
        .REQ_DEC_PSRAM_EN_I       (REQ_DEC_PSRAM_EN_O       ),
        .REQ_DEC_PSRAM_WE_I       (REQ_DEC_PSRAM_WE_O       ),
        .REQ_DEC_PSRAM_ADDR_I     (REQ_DEC_PSRAM_ADDR_O     ),
        .REQ_DEC_PSRAM_WDATA_I    (REQ_DEC_PSRAM_WDATA_O    ),
        .REQ_DEC_PSRAM_BANK_NUM_I (REQ_DEC_PSRAM_BANK_NUM_O ),
                                   
        .CPL_DEC_PSRAM_VALID_O    (CPL_DEC_PSRAM_VALID_I    ),
        .CPL_DEC_PSRAM_RDATA_O    (CPL_DEC_PSRAM_RDATA_I    ),
    
        .REQ_MAT_ISRAM_EN_I       (/* floating */),
        .REQ_MAT_ISRAM_ADDR_I     (/* floating */),

        .REQ_MAT_WSRAM_EN_I       (/* floating */),
        .REQ_MAT_WSRAM_ADDR_I     (/* floating */),

        .REQ_MAT_PSRAM_EN_I       (/* floating */),
        .REQ_MAT_PSRAM_ADDR_I     (/* floating */),

        .REQ_PEARR_PSRAM_EN_I     (/* floating */),
        .REQ_PEARR_PSRAM_ADDR_I   (/* floating */),
        .REQ_PEARR_PSRAM_WDATA_I  (/* floating */),
    
        .CPL_LOADER_ISRAM_VALID_O (/* floating */),
        .CPL_LOADER_ISRAM_RDATA_O (/* floating */),

        .CPL_LOADER_WSRAM_VALID_O (/* floating */),
        .CPL_LOADER_WSRAM_RDATA_O (/* floating */),

        .CPL_LOADER_PSRAM_VALID_O (/* floating */),
        .CPL_LOADER_PSRAM_RDATA_O (/* floating */)
    );

endmodule