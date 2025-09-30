`include "systolic.vh"

module systolic_ctrl_decoder(
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

    // SRAMC IF
    output                          REQ_ISRAM_EN_O, // Active low
    output                          REQ_ISRAM_WE_O,
    output [`DATA_WIDTH-1:0]        REQ_ISRAM_WDATA_O,
    output [`ADDR_WIDTH-1:0]        REQ_ISRAM_ADDR_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_ISRAM_BANK_NUM_O,

    input                           CPL_ISRAM_VALID_I,
    input  [`DATA_WIDTH-1:0]        CPL_ISRAM_RDATA_I,

    output                          REQ_WSRAM_EN_O, // Active low
    output                          REQ_WSRAM_WE_O,
    output [`DATA_WIDTH-1:0]        REQ_WSRAM_WDATA_O,
    output [`ADDR_WIDTH-1:0]        REQ_WSRAM_ADDR_O,
    output [`BANK_NUM_WIDTH-1:0]    REQ_WSRAM_BANK_NUM_O,

    input                           CPL_WSRAM_VALID_I,
    input  [`DATA_WIDTH-1:0]        CPL_WSRAM_RDATA_I,

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
                ST_DONE         = 'd5;

    localparam  WR = 1'b0,
                RD = 1'b1;

    localparam  NUM_STATE = 6;

    reg [NUM_STATE-1:0] current_state_r, next_state_r;

    // req packet fields
    reg [`OPC_WIDTH-1:0]        req_opc_r;
    reg [`REQ_WIDTH-1:0]        req_data_r;

    wire [`PARAM_TRG_WIDTH-1:0] req_param_trg;
    wire [`PARAM_WIDTH-1:0]     req_param_data;
    wire [`SRAM_TRG_WIDTH-1:0]  req_sram_trg;
    wire [`BANK_NUM_WIDTH-1:0]  req_sram_bank_num;
    wire [`ADDR_WIDTH-1:0]      req_sram_addr;
    wire [`DATA_WIDTH-1:0]      req_sram_wdata;

    reg [`PARAM_WIDTH-1:0]      param_s_r;
    reg [`PARAM_WIDTH-1:0]      param_ic_r;
    reg [`PARAM_WIDTH-1:0]      param_oc_r;
    reg [`PARAM_WIDTH-1:0]      param_isram_base_addr_r;
    reg [`PARAM_WIDTH-1:0]      param_wsram_base_addr_r;

    reg [`DATA_WIDTH-1:0]       ld_isram_rdata_r;
    reg [`DATA_WIDTH-1:0]       ld_wsram_rdata_r;
    reg [`PSUN_WIDTH-1:0]       ld_psram_rdata_r;

    wire [`PARAM_WIDTH-1:0]     cpl_get_param;
    wire [`PSUM_WIDTH-1:0]      cpl_ld_sram;
    wire                        cpl_matmul_done;

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
                        next_state_r = (1 << ST_DONE);
                    end
                    `OPC_SET_PARAM: begin
                        next_state_r = (1 << ST_DONE);
                    end
                    `OPC_GET_PARAM: begin
                        next_state_r = (1 << ST_DONE);
                    end
                    `OPC_ST_SRAM: begin // Store to SRAM
                        next_state_r = (1 << ST_DONE);
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
                next_state_r = (1 << ST_DONE);
            end
            current_state_r[ST_MATMUL_REQ]: begin
                next_state_r = (1 << ST_MATMUL_CPL);
            end
            current_state_r[ST_MATMUL_CPL]: begin
                if (MATMUL_DONE_I) begin
                    next_state_r = (1 << ST_DONE);
                end
            end
            current_state_r[ST_DONE]: begin
                next_state_r = (1 << ST_IDLE);
            end
            default:;
        endcase
    end

    // State transition
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            current_state_r <= (1 << ST_IDLE);
        end
        else begin
            current_state_r <= next_state_r;
        end
    end

    // Request fetch
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
    end

    // Set param
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            param_s_r                 <= 'h0;
            param_ic_r                <= 'h0;
            param_oc_r                <= 'h0;
            param_isram_base_addr_r   <= 'h0;
            param_wsram_base_addr_r   <= 'h0;
        end
        else begin
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

    // Load SRAM data latching
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            ld_isram_rdata_r <= 'h0;
            ld_wsram_rdata_r <= 'h0;
            ld_psram_rdata_r <= 'h0;
        end
        else begin
            if (current_state_r[ST_SRAM_RD_CPL] && CPL_ISRAM_VALID_I) begin
                ld_isram_rdata_r <= CPL_ISRAM_RDATA_I;
            end
            if (current_state_r[ST_SRAM_RD_CPL] && CPL_WSRAM_VALID_I) begin
                ld_wsram_rdata_r <= CPL_WSRAM_RDATA_I;
            end
            if (current_state_r[ST_SRAM_RD_CPL] && CPL_PSRAM_VALID_I) begin
                ld_psram_rdata_r <= CPL_PSRAM_RDATA_I;
            end
        end
    end

    assign cpl_get_param = { {(`REQ_WIDTH -`PARAM_WIDTH){1'b0}}, 
                             (req_param_trg == `PARAM_S)                 ? param_s_r :
                             (req_param_trg == `PARAM_IC)                ? param_ic_r :
                             (req_param_trg == `PARAM_OC)                ? param_oc_r :
                             (req_param_trg == `PARAM_ISRAM_BASE_ADDR)   ? param_isram_base_addr_r :
                             (req_param_trg == `PARAM_WSRAM_BASE_ADDR)   ? param_wsram_base_addr_r : 'h0 };

    assign cpl_ld_sram =    (req_sram_addr == `ISRAM_ADDR) ? {16'h0, ld_isram_rdata_r} :
                            (req_sram_addr == `WSRAM_ADDR) ? {16'h0, ld_wsram_rdata_r} :
                            (req_sram_addr == `PSRAM_ADDR) ?         ld_psram_rdata_r  : 'h0;

    assign cpl_matmul_done = (req_opc_r == `OPC_MATMUL) && current_state_r[ST_DONE] ? 1'b1 : 1'b0;

    assign is_isram_access = (current_state_r[ST_DECODE] && (req_sram_trg == `TRG_ISRAM)) ? 1'b1 : 1'b0;
    assign is_wsram_access = (current_state_r[ST_DECODE] && (req_sram_trg == `TRG_WSRAM)) ? 1'b1 : 1'b0;
    assign is_psram_access = (current_state_r[ST_DECODE] && (req_sram_trg == `TRG_PSRAM)) ? 1'b1 : 1'b0;

    // output assignment
    assign REQ_CPU_READY_O = (current_state_r[ST_IDLE]) ? 1'b1 : 1'b0;
    assign CPL_CPU_VALID_O = (current_state_r[ST_DONE]) ? 1'b1 : 1'b0;

    assign CPL_CPU_DATA_O  = (CPL_CPU_VALID_O) ? (req_opc_r == `OPC_GET_PARAM ? {16'h0, cpl_get_param}   :
                                                  req_opc_r == `OPC_LD_SRAM   ? {8'h0,  cpl_ld_sram}     :
                                                  req_opc_r == `OPC_MATMUL    ? {31'h0, cpl_matmul_done} : 'h0)
                                              : 'h0;

    assign REQ_ISRAM_EN_O      = is_isram_access ? 1'b0 : 1'b1;
    assign REQ_ISRAM_WE_O      = is_isram_access && (req_opc_r == `ST_SRAM) ? 1'b0 : 1'b1;
    assign REQ_ISRAM_WDATA_O   = is_isram_access && (req_opc_r == `ST_SRAM) ? req_sram_wdata : 'h0;
    assign REQ_ISRAM_ADDR_O    = is_isram_access ? req_sram_addr : 'h0;

    assign REQ_WSRAM_EN_O      = is_wsram_access ? 1'b0 : 1'b1;
    assign REQ_WSRAM_WE_O      = is_wsram_access && (req_opc_r == `ST_SRAM)? 1'b0 : 1'b1;
    assign REQ_WSRAM_WDATA_O   = is_wsram_access && (req_opc_r == `ST_SRAM)? req_sram_wdata : 'h0;
    assign REQ_WSRAM_ADDR_O    = is_wsram_access ? req_sram_addr : 'h0;

    assign REQ_PSRAM_EN_O      = is_psram_access ? 1'b0 : 1'b1;
    assign REQ_PSRAM_WE_O      = is_psram_access && (req_opc_r == `ST_SRAM)? 1'b0 : 1'b1;
    assign REQ_PSRAM_WDATA_O   = is_psram_access && (req_opc_r == `ST_SRAM)? req_sram_wdata : 'h0;
    assign REQ_PSRAM_ADDR_O    = is_psram_access ? req_sram_addr : 'h0;

    assign MATMUL_START_O      = (current_state_r[ST_MATMUL_REQ]) ? 1'b1 : 1'b0;
endmodule