`include "systolic.vh"

module systolic_ctrl_decoder(
    input CLK,
    input RST_N,

    // Top IF
    input                           INSTR_VALID_I,
    output                          INSTR_READY_O,
    output [`INSTR_WIDTH-1:0]       INSTR_DATA_O,

    output                          WB_PSRAM_VALID_O,
    output [`PSUM_WIDTH-1:0]        WB_PSRAM_DATA_O,

    output                          MATMUL_DONE_O,

    // SRAMC IF
    output                          ISRAM_EN_O, // Active low
    output                          ISRAM_WE_O,
    output [`ADDR_WIDTH-1:0]        ISRAM_ADDR_O,
    output [`DATA_WIDTH-1:0]        ISRAM_WDATA_O,

    output                          WSRAM_EN_O, // Active low
    output                          WSRAM_WE_O,
    output [`ADDR_WIDTH-1:0]        WSRAM_ADDR_O,
    output [`DATA_WIDTH-1:0]        WSRAM_WDATA_O,

    output                          PSRAM_EN_O, // Active low
    output                          PSRAM_WE_O,
    output [`ADDR_WIDTH-1:0]        PSRAM_ADDR_O,
    input [`PSUM_WIDTH-1:0]         PSRAM_RDATA_I,

    // MATMUL IF
    output                          MATMUL_START_O,
    input                           MATMUL_DONE_I,
    output [`PARAM_WIDTH-1:0]       PARAM_S_O,
    output [`PARAM_WIDTH-1:0]       PARAM_IC_O,
    output [`PARAM_WIDTH-1:0]       PARAM_OC_O,

    output [`PARAM_WIDTH-1:0]       PARAM_ISRAM_BASE_ADDR_O,
    output [`PARAM_WIDTH-1:0]       PARAM_WSRAM_BASE_ADDR_O,
    output [`PARAM_WIDTH-1:0]       PARAM_PSRAM_BASE_ADDR_O, 
);

    // State definition
    localparam  ST_IDLE         = 0,
                ST_GRANT        = 1,
                ST_DECODE       = 2,       
                ST_MATMUL_REQ   = 3,        
                ST_MATMUL_CPL   = 4,        
                ST_NOP          = 5;      

    reg [6:0] current_state_r, next_state_r;

    always @* begin
        next_state_r = current_state_r;

        case (1)
            current_state_r[ST_IDLE]: begin
                next_state_r = INSTR_VALID_I ? (1 << ST_GRANT) : (1 << ST_IDLE);
            end
            current_state_r[ST_GRANT]: begin
                next_state_r = (1 << ST_DECODE);
            end
            current_state_r[ST_DECODE]: begin
                case (instr_opc_r)
                    `OPC_NOP: begin
                        next_state_r = (1 << ST_IDLE);
                    end
                    `OPC_SET_PARAM: begin
                        next_state_r = (1 << ST_IDLE);
                    end
                    `OPC_ST_SRAM: begin // Store to SRAM
                        case (instr_sram_trg_r)
                        // TODO: Add ST_SRAM request handling, MATMUL Request handling
                            `TRG_ISRAM: begin
                                next_state_r = (1 << ST_IDLE);
                            end
                            `TRG_WSRAM: begin
                                next_state_r = (1 << ST_IDLE);
                            end
                            `TRG_PSRAM: begin
                                next_state_r = (1 << ST_IDLE);
                            end
                            default: next_state_r = (1 << ST_IDLE);
                        endcase
                    end
                endcase
            end
            current_state_r[ST_MATMUL_REQ]: begin
                
            end
            current_state_r[ST_MATMUL_CPL]: begin
                
            end
            current_state_r[ST_NOP]: begin

            end
            default: next_state_r = (1 << ST_IDLE);
        endcase
    end


endmodule