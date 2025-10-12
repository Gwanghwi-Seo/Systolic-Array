`include "systolic.vh"

module systolic_ctrl_matmul (
    input CLK,
    input RST_N,

    // Ctrl decoder IF
    input MATMUL_START_I,
    input PARAM_S_I,
    input PARAM_IC_I,
    input PARAM_OC_I,

    input PARAM_ISRAM_BASE_ADDR_I,
    input PARAM_WSRAM_BASE_ADDR_I,

    output MATMUL_DONE_O

    // SRAMC IF
    output [`PE_ROW-1:0] REQ_ISRAM1_EN_O,
    output [`ADDR_WIDTH-1:0] REQ_ISRAM1_ADDR_O,
    
    output [`PE_COL-1:0] REQ_WSRAM1_EN_O,
    output [`ADDR_WIDTH-1:0] REQ_WSRAM1_ADDR_O,

    output [`PE_COL-1:0] REQ_PSRAM1_EN_O,
    output REQ_PSRAM1_WE_O,

);

endmodule