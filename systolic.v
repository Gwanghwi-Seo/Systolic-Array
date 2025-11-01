`include "systolic.vh"

module systolic (
    input                           CLK,
    input                           RST_N,

    // Top IF
    input  [`OPC_WIDTH-1:0]         REQ_CPU_OPC_I,
    input                           REQ_CPU_VALID_I,
    output                          REQ_CPU_READY_O,
    input [`REQ_WIDTH-1:0]          REQ_CPU_DATA_I,

    output                          CPL_CPU_VALID_O,
    input                           CPL_CPU_READY_I,
    output [`REQ_WIDTH-1:0]         CPL_CPU_DATA_O,
);

    systolic_ctrl U_CTRL(
        .CLK                        (CLK                ),
        .RST_N                      (RST_N              ),

        // TOP IF
        .REQ_CPU_OPC_I              (REQ_CPU_OPC_I      ),
        .REQ_CPU_VALID_I            (REQ_CPU_VALID_I    ),
        .REQ_CPU_READY_O            (REQ_CPU_READY_O    ),
        .REQ_CPU_DATA_I             (REQ_CPU_DATA_I     ),

        .CPL_CPU_VALID_O            (CPL_CPU_VALID_O    ),
        .CPL_CPU_READY_I            (CPL_CPU_READY_I    ),
        .CPL_CPU_DATA_O             (CPL_CPU_DATA_O     ),
        
        // SRAMC IF
        .REQ_DEC_ISRAM_EN_O         (), // Active low
        .REQ_DEC_ISRAM_WE_O         (),
        .REQ_DEC_ISRAM_ADDR_O       (),
        .REQ_DEC_ISRAM_WDATA_O      (),
        .REQ_DEC_ISRAM_BANK_NUM_O   (),

        .CPL_DEC_ISRAM_VALID_I      (),
        .CPL_DEC_ISRAM_RDATA_I      (),

        .REQ_DEC_WSRAM_EN_O         (), // Active low
        .REQ_DEC_WSRAM_WE_O         (),
        .REQ_DEC_WSRAM_ADDR_O       (),
        .REQ_DEC_WSRAM_WDATA_O      (),
        .REQ_DEC_WSRAM_BANK_NUM_O   (),

        .CPL_DEC_WSRAM_VALID_I      (),
        .CPL_DEC_WSRAM_RDATA_I      (),

        .REQ_DEC_PSRAM_EN_O         (), // Active low
        .REQ_DEC_PSRAM_WE_O         (),
        .REQ_DEC_PSRAM_ADDR_O       (),
        .REQ_DEC_PSRAM_WDATA_O      (),
        .REQ_DEC_PSRAM_BANK_NUM_O   (),

        .CPL_DEC_PSRAM_VALID_I      (),
        .CPL_DEC_PSRAM_RDATA_I      (),

        // CTRL MATMUL IF
        .REQ_MAT_ISRAM_EN_O         (),
        .REQ_MAT_ISRAM_ADDR_O       (),

        .REQ_MAT_WSRAM_EN_O         (),
        .REQ_MAT_WSRAM_ADDR_O       (),

        .REQ_MAT_PSRAM_EN_O         (),
        .REQ_MAT_PSRAM_ADDR_O       ()
    );

    systolic_sramc U_SRAMC (
        .CLK                        (),
        .RST_N                      (),
    
        .REQ_DEC_ISRAM_EN_I         (),
        .REQ_DEC_ISRAM_WE_I         (),
        .REQ_DEC_ISRAM_ADDR_I       (),
        .REQ_DEC_ISRAM_WDATA_I      (),
        .REQ_DEC_ISRAM_BANK_NUM_I   (),

        .CPL_DEC_ISRAM_VALID_O      (),
        .CPL_DEC_ISRAM_RDATA_O      (),

        .REQ_DEC_WSRAM_EN_I         (),
        .REQ_DEC_WSRAM_WE_I         (),
        .REQ_DEC_WSRAM_ADDR_I       (),
        .REQ_DEC_WSRAM_WDATA_I      (),
        .REQ_DEC_WSRAM_BANK_NUM_I   (),

        .CPL_DEC_WSRAM_VALID_O      (),
        .CPL_DEC_WSRAM_RDATA_O      (),

        .REQ_DEC_PSRAM_EN_I         (),
        .REQ_DEC_PSRAM_WE_I         (),
        .REQ_DEC_PSRAM_ADDR_I       (),
        .REQ_DEC_PSRAM_WDATA_I      (),
        .REQ_DEC_PSRAM_BANK_NUM_I   (),

        .CPL_DEC_PSRAM_VALID_O      (),
        .CPL_DEC_PSRAM_RDATA_O      (),

        .REQ_MAT_ISRAM_EN_I         (),
        .REQ_MAT_ISRAM_ADDR_I       (),

        .REQ_MAT_WSRAM_EN_I         (),
        .REQ_MAT_WSRAM_ADDR_I       (),

        .REQ_MAT_PSRAM_EN_I         (),
        .REQ_MAT_PSRAM_ADDR_I       (),

        .REQ_PEARR_PSRAM_EN_I       (),
        .REQ_PEARR_PSRAM_ADDR_I     (),
        .REQ_PEARR_PSRAM_WDATA_I    (),
    
        .CPL_LOADER_ISRAM_VALID_O   (),
        .CPL_LOADER_ISRAM_RDATA_O   (),

        .CPL_LOADER_WSRAM_VALID_O   (),
        .CPL_LOADER_WSRAM_RDATA_O   (),

        .CPL_LOADER_PSRAM_VALID_O   (),
        .CPL_LOADER_PSRAM_RDATA_O   ()
    );

    systolic_pe_array U_PE_ARRAY (
        .CLK                        (),
        .RST_N                      (),
    
        .MAT_A_VALID_I              (),
        .MAT_A_I                    (),
    
        .EN_PE_ROW_ID_I             (),
        .MAT_B_VALID_I              (),
        .MAT_B_I                    (),
    
        .MAT_PSUM_VALID_I           (),
        .MAT_PSUM_ADDR_I            (),
        .MAT_PSUM_I                 (),
    
        .MAT_PSUM_VALID_O           (),
        .MAT_PSUM_O                 (),
        .MAT_PSUM_ADDR_O            ()
    );

    systolic_mat_a_loader U_MAT_A_LOADER(
        .CLK                        (),
        .RST_N                      (),
    
        .MAT_A_VALID_I              (),
        .MAT_A_I                    (),
    
        .MAT_A_VALID_O              (),
        .MAT_A_O                    ()
    );

    systolic_mat_b_loader U_MAT_B_LOADER(
        .CLK                        (),
        .RST_N                      (),

        .MAT_B_VALID_I              (),
        .EN_PE_ROW_ID_I             (),
        .MAT_B_I                    (),

        .MAT_B_VALID_O              (),
        .EN_PE_ROW_ID_O             (),
        .MAT_B_O        
    );

    systolic_mat_psum_loader U_MAT_PSUM_LOADER(
        .CLK                        (),
        .RST_N                      (),   

        .MAT_PSUM_VALID_I           (),
        .MAT_PSUM_ADDR_I            (),
        .MAT_PSUM_I                 (),

        .MAT_PSUM_VALID_O           (),
        .MAT_PSUM_ADDR_O            (),
        .MAT_PSUM_O                 ()
    );

endmodule