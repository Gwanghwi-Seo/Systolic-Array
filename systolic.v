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

    // Top IF
    wire                          req_dec_isram_en        ; // Active low
    wire                          req_dec_isram_we        ;
    wire [`ADDR_WIDTH-1:0]        req_dec_isram_addr      ;
    wire [`DATA_WIDTH-1:0]        req_dec_isram_wdata     ;
    wire [`BANK_NUM_WIDTH-1:0]    req_dec_isram_bank_num  ;

    wire                          cpl_dec_isram_valid     ;
    wire [`DATA_WIDTH-1:0]        cpl_dec_isram_rdata     ;

    wire                          req_dec_wsram_en        ; // Active low
    wire                          req_dec_wsram_we        ;
    wire [`ADDR_WIDTH-1:0]        req_dec_wsram_addr      ;
    wire [`DATA_WIDTH-1:0]        req_dec_wsram_wdata     ;
    wire [`BANK_NUM_WIDTH-1:0]    req_dec_wsram_bank_num  ;

    wire                          cpl_dec_wsram_valid     ;
    wire [`DATA_WIDTH-1:0]        cpl_dec_wsram_rdata     ;

    wire                          req_dec_psram_en        ;;// Active low
    wire                          req_dec_psram_we        ;
    wire [`ADDR_WIDTH-1:0]        req_dec_psram_addr      ;
    wire [`PSUM_WIDTH-1:0]        req_dec_psram_wdata     ;
    wire [`BANK_NUM_WIDTH-1:0]    req_dec_psram_bank_num  ;

    wire                          cpl_dec_psram_valid     ;
    wire [`PSUM_WIDTH-1:0]        cpl_dec_psram_rdata     ;

    wire [`PE_ROW-1:0]            req_mat_isram_en        ;
    wire [`ADDR_WIDTH-1:0]        req_mat_isram_addr      ;

    wire [`PE_ROW_ID_WIDTH-1:0]   req_mat_wsram_pe_row_id ;
    wire [`PE_COL-1:0]            req_mat_wsram_en        ;
    wire [`ADDR_WIDTH-1:0]        req_mat_wsram_addr      ;

    wire [`PE_COL-1:0]            req_mat_psram_en        ;
    wire [`ADDR_WIDTH-1:0]        req_mat_psram_addr      ;


    // pe_array IF, write only
    wire [`PE_COL-1:0]             req_pearr_psram_en     ;
    wire [`ADDR_WIDTH-1:0]         req_pearr_psram_addr   ;
    wire [`PSUM_WIDTH*`PE_COL-1:0] req_pearr_psram_wdata  ;

    // Input, Weight, PSUM Loader If
    output [`PE_ROW-1:0]            cpl_loader_isram_valid;
    output [`DATA_WIDTH*`PE_ROW-1:0]cpl_loader_isram_rdata;

    output [`PE_COL-1:0]            cpl_loader_wsram_valid;
    output [`PE_COL-1:0]            cpl_loader_wsram_pe_row_id;
    output [`DATA_WIDTH*`PE_COL-1:0]cpl_loader_wsram_rdata;

    output [`PE_COL-1:0]            cpl_loader_psram_valid;
    output [`ADDR_WIDTH*`PE_COL-1:0]cpl_loader_psram_addr ;
    output [`PSUM_WIDTH*`PE_COL-1:0]cpl_loader_psram_rdata;

    systolic_ctrl U_CTRL(
        .CLK                        (CLK                ),
        .RST_N                      (RST_N              ),

        // TOP IF
        .REQ_CPU_OPC_I              (REQ_CPU_OPC_I      ),
        .REQ_CPU_VALID_I            (REQ_CPU_VALID_I    ),
        .REQ_CPU_READY_O            (REQ_CPU_READY_O    ),
        .REQ_CPU_DATA_I             (REQ_CPU_DATA_I     ),

        .CPL_CPU_VALID_O            (CPL_CPU_VALID_O    ),
        // .CPL_CPU_READY_I            (CPL_CPU_READY_I    ),
        .CPL_CPU_DATA_O             (CPL_CPU_DATA_O     ),
        
        // SRAMC IF
        .REQ_DEC_ISRAM_EN_O         (req_dec_isram_en       ), // Active low
        .REQ_DEC_ISRAM_WE_O         (req_dec_isram_we       ),
        .REQ_DEC_ISRAM_ADDR_O       (req_dec_isram_addr     ),
        .REQ_DEC_ISRAM_WDATA_O      (req_dec_isram_wdata    ),
        .REQ_DEC_ISRAM_BANK_NUM_O   (req_dec_isram_bank_num ),
                                     
        .CPL_DEC_ISRAM_VALID_I      (cpl_dec_isram_valid    ),
        .CPL_DEC_ISRAM_RDATA_I      (cpl_dec_isram_rdata    ),
                                     
        .REQ_DEC_WSRAM_EN_O         (req_dec_wsram_en       ), // Active low
        .REQ_DEC_WSRAM_WE_O         (req_dec_wsram_we       ),
        .REQ_DEC_WSRAM_ADDR_O       (req_dec_wsram_addr     ),
        .REQ_DEC_WSRAM_WDATA_O      (req_dec_wsram_wdata    ),
        .REQ_DEC_WSRAM_BANK_NUM_O   (req_dec_wsram_bank_num ),
                                     
        .CPL_DEC_WSRAM_VALID_I      (cpl_dec_wsram_valid    ),
        .CPL_DEC_WSRAM_RDATA_I      (cpl_dec_wsram_rdata    ),
                                     
        .REQ_DEC_PSRAM_EN_O         (req_dec_psram_en       ), // Active low
        .REQ_DEC_PSRAM_WE_O         (req_dec_psram_we       ),
        .REQ_DEC_PSRAM_ADDR_O       (req_dec_psram_addr     ),
        .REQ_DEC_PSRAM_WDATA_O      (req_dec_psram_wdata    ),
        .REQ_DEC_PSRAM_BANK_NUM_O   (req_dec_psram_bank_num ),
                                     
        .CPL_DEC_PSRAM_VALID_I      (cpl_dec_psram_valid    ),
        .CPL_DEC_PSRAM_RDATA_I      (cpl_dec_psram_rdata    ),
                                     
        .REQ_MAT_ISRAM_EN_O         (req_mat_isram_en       ),
        .REQ_MAT_ISRAM_ADDR_O       (req_mat_isram_addr     ),
                                     
        .REQ_MAT_WSRAM_PE_ROW_ID_O  (req_mat_wsram_pe_row_id),
        .REQ_MAT_WSRAM_EN_O         (req_mat_wsram_en       ),
        .REQ_MAT_WSRAM_ADDR_O       (req_mat_wsram_addr     ),
                                     
        .REQ_MAT_PSRAM_EN_O         (req_mat_psram_en       ),
        .REQ_MAT_PSRAM_ADDR_O       (req_mat_psram_addr     )
    );

    systolic_sramc U_SRAMC (
        .CLK                        (CLK                    ),
        .RST_N                      (RST_N                  ),
    
        .REQ_DEC_ISRAM_EN_I         (req_dec_isram_en       ),
        .REQ_DEC_ISRAM_WE_I         (req_dec_isram_we       ),
        .REQ_DEC_ISRAM_ADDR_I       (req_dec_isram_addr     ),
        .REQ_DEC_ISRAM_WDATA_I      (req_dec_isram_wdata    ),
        .REQ_DEC_ISRAM_BANK_NUM_I   (req_dec_isram_bank_num ),
                                     
        .CPL_DEC_ISRAM_VALID_O      (cpl_dec_isram_valid    ),
        .CPL_DEC_ISRAM_RDATA_O      (cpl_dec_isram_rdata    ),
                                     
        .REQ_DEC_WSRAM_EN_I         (req_dec_wsram_en       ),
        .REQ_DEC_WSRAM_WE_I         (req_dec_wsram_we       ),
        .REQ_DEC_WSRAM_ADDR_I       (req_dec_wsram_addr     ),
        .REQ_DEC_WSRAM_WDATA_I      (req_dec_wsram_wdata    ),
        .REQ_DEC_WSRAM_BANK_NUM_I   (req_dec_wsram_bank_num ),
                                     
        .CPL_DEC_WSRAM_VALID_O      (cpl_dec_wsram_valid    ),
        .CPL_DEC_WSRAM_RDATA_O      (cpl_dec_wsram_rdata    ),
                                     
        .REQ_DEC_PSRAM_EN_I         (req_dec_psram_en       ),
        .REQ_DEC_PSRAM_WE_I         (req_dec_psram_we       ),
        .REQ_DEC_PSRAM_ADDR_I       (req_dec_psram_addr     ),
        .REQ_DEC_PSRAM_WDATA_I      (req_dec_psram_wdata    ),
        .REQ_DEC_PSRAM_BANK_NUM_I   (req_dec_psram_bank_num ),
                                     
        .CPL_DEC_PSRAM_VALID_O      (cpl_dec_psram_valid    ),
        .CPL_DEC_PSRAM_RDATA_O      (cpl_dec_psram_rdata    ),
                                     
        .REQ_MAT_ISRAM_EN_I         (req_mat_isram_en       ),
        .REQ_MAT_ISRAM_ADDR_I       (req_mat_isram_addr     ),
        
        .REQ_MAT_WSRAM_PE_ROW_ID_I  (req_mat_wsram_pe_row_id),
        .REQ_MAT_WSRAM_EN_I         (req_mat_wsram_en       ),
        .REQ_MAT_WSRAM_ADDR_I       (req_mat_wsram_addr     ),
                                     
        .REQ_MAT_PSRAM_EN_I         (req_mat_psram_en       ),
        .REQ_MAT_PSRAM_ADDR_I       (req_mat_psram_addr     ),
                                     
        .REQ_PEARR_PSRAM_EN_I       (req_pearr_psram_en     ),
        .REQ_PEARR_PSRAM_ADDR_I     (req_pearr_psram_addr   ),
        .REQ_PEARR_PSRAM_WDATA_I    (req_pearr_psram_wdata  ),
    
        .CPL_LOADER_ISRAM_VALID_O   (cpl_loader_isram_valid ),
        .CPL_LOADER_ISRAM_RDATA_O   (cpl_loader_isram_rdata ),
                                      
        .CPL_LOADER_WSRAM_VALID_O   (cpl_loader_wsram_valid ),
        .CPL_LOADER_WSRAM_PE_ROW_ID_O(cpl_loader_wsram_pe_ro),
        .CPL_LOADER_WSRAM_RDATA_O   (cpl_loader_wsram_rdata ),
                                      
        .CPL_LOADER_PSRAM_VALID_O   (cpl_loader_psram_valid ),
        .CPL_LOADER_PSRAM_ADDR_O    (cpl_loader_psram_addr  ),
        .CPL_LOADER_PSRAM_RDATA_O   (cpl_loader_psram_rdata )
    );

    // TODO: Loader Renaming, loader_mat_a_ ...
    systolic_mat_a_loader U_MAT_A_LOADER(
        .CLK                        (),
        .RST_N                      (),

    );

    systolic_mat_b_loader U_MAT_B_LOADER(
        .CLK                        (),
        .RST_N                      (),

    );

    systolic_mat_psum_loader U_MAT_PSUM_LOADER(
        .CLK                        (),
        .RST_N                      (),   


    );

    systolic_pe_array U_PE_ARRAY (
        .CLK                        (),
        .RST_N                      (),
    
    );


endmodule