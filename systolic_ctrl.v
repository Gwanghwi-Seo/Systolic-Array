`include "systolic.vh"

module systolic_ctrl (
    input                           CLK,
    input                           RST_N,

    // Top IF
    input  [`OPC_WIDTH-1:0]         REQ_CPU_OPC_I,
    input                           REQ_CPU_VALID_I,
    output                          REQ_CPU_READY_O,
    input [`REQ_WIDTH-1:0]          REQ_CPU_DATA_I,

    output                          CPL_CPU_VALID_O,
    // input                           CPL_CPU_READY_I,
    output [`REQ_WIDTH-1:0]         CPL_CPU_DATA_O,

    // SRAMC IF
    output                          REQ_DEC_ISRAM_EN_O, // Active low
    output                          REQ_DEC_ISRAM_WE_O,
    output [`ADDR_WIDTH-1:0]        REQ_DEC_ISRAM_ADDR_O,
    output [`DATA_WIDTH-1:0]        REQ_DEC_ISRAM_WDATA_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_DEC_ISRAM_BANK_NUM_O,

    input                           CPL_DEC_ISRAM_VALID_I,
    input  [`DATA_WIDTH-1:0]        CPL_DEC_ISRAM_RDATA_I,

    output                          REQ_DEC_WSRAM_EN_O, // Active low
    output                          REQ_DEC_WSRAM_WE_O,
    output [`ADDR_WIDTH-1:0]        REQ_DEC_WSRAM_ADDR_O,
    output [`DATA_WIDTH-1:0]        REQ_DEC_WSRAM_WDATA_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_DEC_WSRAM_BANK_NUM_O,

    input                           CPL_DEC_WSRAM_VALID_I,
    input  [`DATA_WIDTH-1:0]        CPL_DEC_WSRAM_RDATA_I,

    output                          REQ_DEC_PSRAM_EN_O, // Active low
    output                          REQ_DEC_PSRAM_WE_O,
    output [`ADDR_WIDTH-1:0]        REQ_DEC_PSRAM_ADDR_O,
    output [`PSUM_WIDTH-1:0]        REQ_DEC_PSRAM_WDATA_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_DEC_PSRAM_BANK_NUM_O,

    input                           CPL_DEC_PSRAM_VALID_I,
    input  [`PSUM_WIDTH-1:0]        CPL_DEC_PSRAM_RDATA_I,

    output [`PE_ROW-1:0]            REQ_MAT_ISRAM_EN_O,
    output [`ADDR_WIDTH-1:0]        REQ_MAT_ISRAM_ADDR_O,

    output [`PE_ROW_ID_WIDTH-1:0]   REQ_MAT_WSRAM_PE_ROW_ID_O,
    output [`PE_COL-1:0]            REQ_MAT_WSRAM_EN_O,
    output [`ADDR_WIDTH-1:0]        REQ_MAT_WSRAM_ADDR_O,

    output [`PE_COL-1:0]            REQ_MAT_PSRAM_EN_O,
    output [`ADDR_WIDTH-1:0]        REQ_MAT_PSRAM_ADDR_O
);

    wire start_matmul;
    wire done_matmul;
    wire param_m;
    wire param_n;
    wire param_k;

    systolic_ctrl_decoder U_CTRL_DEC (
        .CLK                        (CLK                     ),
        .RST_N                      (RST_N                   ),

        .REQ_CPU_OPC_I              (REQ_CPU_OPC_I           ),
        .REQ_CPU_VALID_I            (REQ_CPU_VALID_I         ),
        .REQ_CPU_READY_O            (REQ_CPU_READY_O         ),
        .REQ_CPU_DATA_I             (REQ_CPU_DATA_I          ),
                                   
        .CPL_CPU_VALID_O            (CPL_CPU_VALID_O         ),
        // .CPL_CPU_READY_I            (CPL_CPU_READY_I         ),
        .CPL_CPU_DATA_O             (CPL_CPU_DATA_O          ),

        .REQ_DEC_ISRAM_EN_O         (REQ_DEC_ISRAM_EN_O      ), // Ac), // Active low
        .REQ_DEC_ISRAM_WE_O         (REQ_DEC_ISRAM_WE_O      ),
        .REQ_DEC_ISRAM_ADDR_O       (REQ_DEC_ISRAM_ADDR_O    ),
        .REQ_DEC_ISRAM_WDATA_O      (REQ_DEC_ISRAM_WDATA_O   ),
        .REQ_DEC_ISRAM_BANK_NUM_O   (REQ_DEC_ISRAM_BANK_NUM_O),
                                    
        .CPL_DEC_ISRAM_VALID_I      (CPL_DEC_ISRAM_VALID_I   ),
        .CPL_DEC_ISRAM_RDATA_I      (CPL_DEC_ISRAM_RDATA_I   ),
                                    
        .REQ_DEC_WSRAM_EN_O         (REQ_DEC_WSRAM_EN_O      ), // Active low
        .REQ_DEC_WSRAM_WE_O         (REQ_DEC_WSRAM_WE_O      ),
        .REQ_DEC_WSRAM_ADDR_O       (REQ_DEC_WSRAM_ADDR_O    ),
        .REQ_DEC_WSRAM_WDATA_O      (REQ_DEC_WSRAM_WDATA_O   ),
        .REQ_DEC_WSRAM_BANK_NUM_O   (REQ_DEC_WSRAM_BANK_NUM_O),
                                    
        .CPL_DEC_WSRAM_VALID_I      (CPL_DEC_WSRAM_VALID_I   ),
        .CPL_DEC_WSRAM_RDATA_I      (CPL_DEC_WSRAM_RDATA_I   ),
                                    
        .REQ_DEC_PSRAM_EN_O         (REQ_DEC_PSRAM_EN_O      ), // Active low
        .REQ_DEC_PSRAM_WE_O         (REQ_DEC_PSRAM_WE_O      ),
        .REQ_DEC_PSRAM_ADDR_O       (REQ_DEC_PSRAM_ADDR_O    ),
        .REQ_DEC_PSRAM_WDATA_O      (REQ_DEC_PSRAM_WDATA_O   ),
        .REQ_DEC_PSRAM_BANK_NUM_O   (REQ_DEC_PSRAM_BANK_NUM_O),
                                    
        .CPL_DEC_PSRAM_VALID_I      (CPL_DEC_PSRAM_VALID_I   ),
        .CPL_DEC_PSRAM_RDATA_I      (CPL_DEC_PSRAM_RDATA_I   ),
    
        .START_MATMUL_O             (start_matmul            ),
        .DONE_MATMUL_I              (done_matmul             ),

        .PARAM_M_O                  (param_m                 ),
        .PARAM_N_O                  (param_n                 ),
        .PARAM_K_O                  (param_k                 )
    );

    systolic_ctrl_matmul U_CTRL_MATMUL (
        .CLK                       (CLK                     ),
        .RST_N                     (RST_N                   ),

        .START_MATMUL_I            (start_matmul            ),
        .DONE_MATMUL_O             (done_matmul             ),

        .PARAM_M_I                 (param_m                 ),
        .PARAM_N_I                 (param_n                 ),
        .PARAM_K_I                 (param_k                 ),

        .REQ_MAT_ISRAM_EN_O        (REQ_MAT_ISRAM_EN_O      ),
        .REQ_MAT_ISRAM_ADDR_O      (REQ_MAT_ISRAM_ADDR_O    ),

        .REQ_MAT_WSRAM_PE_ROW_ID_O (REQ_MAT_WSRAM_PE_ROW_ID_O),
        .REQ_MAT_WSRAM_EN_O        (REQ_MAT_WSRAM_EN_O      ),
        .REQ_MAT_WSRAM_ADDR_O      (REQ_MAT_WSRAM_ADDR_O    ),

        .REQ_MAT_PSRAM_EN_O        (REQ_MAT_PSRAM_EN_O      ),
        .REQ_MAT_PSRAM_ADDR_O      (REQ_MAT_PSRAM_ADDR_O    )
    );

endmodule