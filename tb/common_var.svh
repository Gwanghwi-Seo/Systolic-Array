`ifndef __COMMON_VAR_SVH__
`define __COMMON_VAR_SVH__

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


`endif