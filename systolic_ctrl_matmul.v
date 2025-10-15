`include "systolic.vh"

module systolic_ctrl_matmul (
    input                            CLK,
    input                            RST_N,

    // Decoder IF
    input wire                       START_MATMUL_I,

    input wire [`DATA_WIDTH-1:0]     PARAM_S_I,
    input wire [`DATA_WIDTH*2-1:0]   PARAM_IC_I,
    input wire [`DATA_WIDTH-1:0]     PARAM_OC_I,
    input wire [`ADDR_WIDTH-1:0]     PARAM_ISRAM_BASE_ADDR_I,
    input wire [`ADDR_WIDTH-1:0]     PARAM_WSRAM_BASE_ADDR_I,

    output                           DONE_MATMUL_O

    // SRAMC IF
    output [`PE_ROW-1:0]             REQ_MAT_ISRAM_EN_O,
    output [`ADDR_WIDTH-1:0]         REQ_MAT_ISRAM_ADDR_O,

    output [`PE_COL-1:0]             REQ_MAT_WSRAM_EN_O,
    output [`ADDR_WIDTH-1:0]         REQ_MAT_WSRAM_ADDR_O,

    output [`PE_COL-1:0]             REQ_MAT_PSRAM_EN_O,
    output [`ADDR_WIDTH-1:0]         REQ_MAT_PSRAM_ADDR_O
);

    localparam  ST_IDLE         = 0,
                ST_SET_PARAM    = 1,
                ST_INIT_PSUM    = 2,
                ST_LD_MAT_A     = 3,
                ST_LD_MAT_B     = 4,
                ST_DONE         = 5;

    localparam  NUM_STATE       = 6;

    reg [NUM_STATE-1:0] current_state_r;
    reg [NUM_STATE-1:0] next_state;

    wire [`PARAM_WIDTH-1:0] m_loop_quo, n_loop_quo, k_loop_quo;
    wire [`LOG2(`PE_COL)-1:0] m_loop_rem, n_loop_rem, k_loop_rem;
    wire has_m_loop_rem, has_n_loop_rem, has_k_loop_rem;

    reg [`PARAM_WIDTH-1:0] m_loop_quo_r, n_loop_quo_r, k_loop_quo_r;
    reg [`LOG2(`PE_COL)-1:0] m_loop_rem_r, n_loop_rem_r, k_loop_rem_r;

    wire [`PARAM_WIDTH:0] m_loop_total, n_loop_total, k_loop_total;
    reg [`PARAM_WIDTH:0] cnt_m_loop_r, cnt_n_loop_r, cnt_k_loop_r;

    assign m_loop_quo = (PARAM_S_I  >> `LOG2(`PE_COL));
    assign n_loop_quo = (PARAM_OC_I >> `LOG2(`PE_COL));
    assign k_loop_quo = (PARAM_IC_I >> `LOG2(`PE_ROW));

    assign m_loop_rem = (PARAM_S_I  & ((1 << `LOG2(`PE_COL)) - 1));
    assign n_loop_rem = (PARAM_OC_I & ((1 << `LOG2(`PE_COL)) - 1));
    assign k_loop_rem = (PARAM_IC_I & ((1 << `LOG2(`PE_ROW)) - 1));

    assign has_m_loop_rem = (m_loop_rem != 'h0);
    assign has_n_loop_rem = (n_loop_rem != 'h0);
    assign has_k_loop_rem = (k_loop_rem != 'h0);

    assign m_loop_total = m_loop_quo_r + has_m_loop_rem;
    assign n_loop_total = n_loop_quo_r + has_n_loop_rem;
    assign k_loop_total = k_loop_quo_r + has_k_loop_rem;

    always @* begin
        next_state = current_state_r;

        case (1)
            current_state_r[ST_IDLE]: begin
                next_state = START_MATMUL_I ? (1 << ST_SET_PARAM) : (1 << ST_IDLE);
            end
            current_state_r[ST_SET_PARAM]: begin
                next_state = (1 << ST_INIT_PSUM);
            end
            current_state_r[ST_INIT_PSUM]: begin

            end
            current_state_r[ST_LD_MAT_A]: begin

            end
            current_state_r[ST_LD_MAT_B]: begin

            end
            current_state_r[ST_DONE]: begin
                next_state = (1 << ST_IDLE);
            end
        endcase
    end

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N)
            current_state_r <= (1 << ST_IDLE);
        else
            current_state_r <= next_state;
    end

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            m_loop_quo_r <= 'h0;
            n_loop_quo_r <= 'h0;
            k_loop_quo_r <= 'h0;

            m_loop_rem_r <= 'h0;
            n_loop_rem_r <= 'h0;
            k_loop_rem_r <= 'h0;
        end
        else begin
            if (current_state_r[ST_IDLE] && START_MATMUL_I) begin
                m_loop_quo_r <= m_loop_quo;
                n_loop_quo_r <= n_loop_quo;
                k_loop_quo_r <= k_loop_quo;

                m_loop_rem_r <= m_loop_rem;
                n_loop_rem_r <= n_loop_rem;
                k_loop_rem_r <= k_loop_rem;
            end
        end
    end

    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            cnt_m_loop_r <= 'h0;
            cnt_n_loop_r <= 'h0;
            cnt_k_loop_r <= 'h0;
        end
        else begin
        end
    end


endmodule