`include "systolic.vh"

module systolic_ctrl_decoder(
    input CLK,
    input RST_N,

    // Top IF
    input  [`OPC_WIDTH-1:0]         REQ_CPU_OPC_I,
    input                           REQ_CPU_VALID_I,
    output                          REQ_CPU_READY_O,
    output [`req_WIDTH-1:0]       REQ_CPU_DATA_O,

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
                ST_DECODE       = 1,
                ST_MATMUL_REQ   = 2,
                ST_MATMUL_CPL   = 3,
                ST_NOP          = 4;

    localparam  WR = 1'b0,
                RD = 1'b1;

    reg [4:0] current_state_r, next_state_r;

    // req packet fields
    reg [2:0]   req_opc_r;
    reg [31:0]  req_data_r;

    wire [1:0]  req_param_trg;
    wire [15:0] req_param_data;
    wire [1:0]  req_sram_trg;
    wire [7:0]  req_sram_bank_num;
    wire [13:0] req_sram_addr;
    wire [7:0]  req_sram_wdata;

    always @* begin
        next_state_r = current_state_r;

        ISRAM_EN_O 

        case (1)
            current_state_r[ST_IDLE]: begin
                if (REQ_CPU_VALID_I && REQ_CPU_READY_O) begin
                    next_state_r = (1 << ST_DECODE);
                end
            end
            current_state_r[ST_DECODE]: begin
                case (req_opc_r)
                    `OPC_NOP: begin
                        next_state_r = (1 << ST_IDLE);
                    end
                    `OPC_SET_PARAM: begin
                        next_state_r = (1 << ST_IDLE);
                    end
                    `OPC_ST_SRAM: begin // Store to SRAM
                        case (req_sram_trg)
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

    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            current_state_r <= (1 << ST_IDLE);
        end
        else begin
            current_state_r <= next_state_r;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            req_opc_r  <= '0;
            req_data_r <= '0;
        end
        else begin
            if (REQ_CPU_VALID_I && REQ_CPU_READY_O) begin
                req_opc_r  <= REQ_CPU_OPC_I;
                req_data_r <= REQ_CPU_DATA_I;
            end
        end

    assign req_param_trg       = req_data_r[PARAM_TRG_OFFSET     +:  PARAM_TRG_WIDTH];
    assign req_param_data      = req_data_r[PARAM_DATA_OFFSET    +:  PARAM_DATA_WIDTH];
    assign req_sram_trg        = req_data_r[SRAM_TRG_OFFSET      +:  SRAM_TRG_WIDTH];
    assign req_sram_bank_num   = req_data_r[SRAM_BANK_NUM_OFFSET +:  SRAM_BANK_NUM_WIDTH];
    assign req_sram_addr       = req_data_r[SRAM_ADDR_OFFSET     +:  SRAM_ADDR_WIDTH];
    assign req_sram_wdata      = req_data_r[SRAM_WDATA_OFFSET    +:  SRAM_WDATA_WIDTH];

    assign REQ_CPU_READY_O == (current_state_r[ST_IDLE]);

endmodule