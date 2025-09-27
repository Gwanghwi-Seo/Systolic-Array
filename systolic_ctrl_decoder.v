`include "systolic.vh"

module systolic_ctrl_decoder(
    input CLK,
    input RST_N,

    // Top IF
    input  [`OPC_WIDTH-1:0]         REQ_CPU_OPC_I,
    input                           REQ_CPU_VALID_I,
    output                          REQ_CPU_READY_O,
    input [`REQ_WIDTH-1:0]          REQ_CPU_DATA_I,

    output                          CPL_CPU_VALID_O,
    // input                           CPL_CPU_READY_I,
    output [`REQ_WIDTH-1:0]         CPL_CPU_DATA_O,

    // SRAMC IF
    output                          REQ_ISRAM_EN_O, // Active low
    output                          REQ_ISRAM_WE_O,
    output [`DATA_WIDTH-1:0]        REQ_ISRAM_WDATA_O,
    output [`ADDR_WIDTH-1:0]        REQ_ISRAM_ADDR_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_ISRAM_BANK_NUM_O,

    input                           CPL_ISRAM_VALID_I,
    input  [`PSUM_WIDTH-1:0]        CPL_ISRAM_RDATA_I,

    output                          REQ_WSRAM_EN_O, // Active low
    output                          REQ_WSRAM_WE_O,
    output [`DATA_WIDTH-1:0]        REQ_WSRAM_WDATA_O,
    output [`ADDR_WIDTH-1:0]        REQ_WSRAM_ADDR_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_WSRAM_BANK_NUM_O,

    input                           CPL_WSRAM_VALID_I,
    input  [`PSUM_WIDTH-1:0]        CPL_WSRAM_RDATA_I,

    output                          REQ_PSRAM_EN_O, // Active low
    output                          REQ_PSRAM_WE_O,
    output [`ADDR_WIDTH-1:0]        REQ_PSRAM_ADDR_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_PSRAM_BANK_NUM_O,

    input                           CPL_PSRAM_VALID_I,
    input  [`PSUM_WIDTH-1:0]        CPL_PSRAM_RDATA_I,

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
    localparam  ST_IDLE         = 'd0,
                ST_DECODE       = 'd1,
                ST_SRAM_RD_CPL  = 'd2,
                ST_MATMUL_REQ   = 'd3,
                ST_MATMUL_CPL   = 'd4,
                ST_NOP          = 'd5;

    localparam  WR = 1'b0,
                RD = 1'b1;

    reg [5:0] current_state_r, next_state_r;

    // req packet fields
    reg [`OPC_WIDTH-1:0]   req_opc_r;
    reg [31:0]  req_data_r;

    wire [1:0]  req_param_trg;
    wire [15:0] req_param_data;
    wire [1:0]  req_sram_trg;
    wire [7:0]  req_sram_bank_num;
    wire [13:0] req_sram_addr;
    wire [7:0]  req_sram_wdata;

    reg [`PARAM_WIDTH-1:0] param_s_r;
    reg [`PARAM_WIDTH-1:0] param_ic_r;
    reg [`PARAM_WIDTH-1:0] param_oc_r;
    reg [`PARAM_WIDTH-1:0] param_isram_base_addr_r;
    reg [`PARAM_WIDTH-1:0] param_wsram_base_addr_r;

    // Instruction decoding
    assign req_param_trg       = req_data_r[PARAM_TRG_OFFSET     +:  PARAM_TRG_WIDTH];
    assign req_param_data      = req_data_r[PARAM_DATA_OFFSET    +:  PARAM_DATA_WIDTH];
    assign req_sram_trg        = req_data_r[SRAM_TRG_OFFSET      +:  SRAM_TRG_WIDTH];
    assign req_sram_bank_num   = req_data_r[SRAM_BANK_NUM_OFFSET +:  SRAM_BANK_NUM_WIDTH];
    assign req_sram_addr       = req_data_r[SRAM_ADDR_OFFSET     +:  SRAM_ADDR_WIDTH];
    assign req_sram_wdata      = req_data_r[SRAM_WDATA_OFFSET    +:  SRAM_WDATA_WIDTH];

    always @* begin
        next_state_r = current_state_r;

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
                    `OPC_GET_PARAM: begin
                        next_state_r = (1 << ST_IDLE);
                    end
                    `OPC_ST_SRAM: begin // Store to SRAM
                        next_state_r = (1 << ST_IDLE);
                    end
                    `OPC_LD_SRAM: begin
                        next_state_r = (1 << ST_SRAM_RD_CPL);
                    end
                    `OPC_MATMUL: begin
                        next_state_r = (1 << ST_MATMUL_REQ);
                    end
                endcase
            end
            current_state_r[ST_SRAM_RD_CPL]: begin
                next_state_r = (1 << ST_IDLE);
            end
            current_state_r[ST_MATMUL_REQ]: begin
                next_state_r = (1 << ST_MATMUL_CPL);
            end
            current_state_r[ST_MATMUL_CPL]: begin
                if (MATMUL_DONE_I) begin
                    next_state_r = (1 << ST_IDLE);
                end
            end
            current_state_r[ST_NOP]: begin
                next_state_r = (1 << ST_IDLE);
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

            if ((current_state_r[ST_DECODE]) && (req_opc_r == `OPC_SET_PARAM)) begin
                if (req_param_trg == `PARAM_S)
                    param_s_r <= req_param_data;
                else if (req_param_trg == `PARAM_IC)
                    param_ic_r <= req_param_data;
                else if (req_param_trg == `PARAM_OC)
                    param_oc_r <= req_param_data;
                else if (req_param_trg == `PARAM_ISRAM_BASE_ADDR)
                    param_isram_base_addr_r <= req_param_data;
                else if (req_param_trg == `PARAM_WSRAM_BASE_ADDR)
                    param_wsram_base_addr_r <= req_param_data;
            end
        end
    end

    assign REQ_CPU_READY_O = (current_state_r[ST_IDLE]) ? 1'b1 : 1'b0;
    assign CPL_CPU_VALID_O = (current_state_r[ST_DECODE] && (req_opc_r == `OPC_GET_PARAM)) ? 1'b1 :
                             (current_state_r[ST_SRAM_RD_CPL])                             ? 1'b1 :
                             (current_state_r[ST_MATMUL_CPL] && MATMUL_DONE_I)             ? 1'b1 : 1'b0;

    assign CPL_CPU_DATA_O  = (current_state_r[ST_DECODE] && (req_opc_r == `OPC_GET_PARAM)) ?
                                    (req_param_trg == `PARAM_S)  ? {16'b0, param_s_r} :
                                    (req_param_trg == `PARAM_IC) ? {16'b0, param_ic_r} :
                                    (req_param_trg == `PARAM_OC) ? {16'b0, param_oc_r} :
                                    (req_param_trg == `PARAM_ISRAM_BASE_ADDR) ? {16'b0, param_isram_base_addr_r} :
                                    (req_param_trg == `PARAM_WSRAM_BASE_ADDR) ? {16'b0, param_wsram_base_addr_r} :

                             (current_state_r[ST_SRAM_RD_CPL] && (req_sram_trg == `TRG_ISRAM)) ? {16'b0, CPL_ISRAM_RDATA_I} :
                             (current_state_r[ST_SRAM_RD_CPL] && (req_sram_trg == `TRG_WSRAM)) ? {16'b0, CPL_WSRAM_RDATA_I} :
                             (current_state_r[ST_SRAM_RD_CPL] && (req_sram_trg == `TRG_PSRAM)) ? {16'b0, CPL_PSRAM_RDATA_I} :
                             (current_state_r[ST_MATMUL_CPL] && MATMUL_DONE_I)                 ? 32'h1 : 32'h0;


    assign REQ_ISRAM_EN_O      = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_ISRAM) ) ? 1'b0 : 1'b1;
    assign REQ_ISRAM_WE_O      = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_ISRAM) ) ? 1'b0 : 1'b1;
    assign REQ_ISRAM_WDATA_O   = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_ISRAM) ) ? req_sram_wdata : 'h0;
    assign REQ_ISRAM_ADDR_O    = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_ISRAM) ) ? req_sram_addr : 'h0;

    assign REQ_WSRAM_EN_O      = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_WSRAM) ) ? 1'b0 : 1'b1;
    assign REQ_WSRAM_WE_O      = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_WSRAM) ) ? 1'b0 : 1'b1;
    assign REQ_WSRAM_WDATA_O   = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_WSRAM) ) ? req_sram_wdata : 'h0;
    assign REQ_WSRAM_ADDR_O    = (current_state_r[ST_DECODE] && (req_opc_r == `ST_SRAM) && (req_sram_trg == `TRG_WSRAM) ) ? req_sram_addr : 'h0;

    assign MATMUL_START_O = (current_state_r[ST_MATMUL_REQ]) ? 1'b1 : 1'b0;

endmodule