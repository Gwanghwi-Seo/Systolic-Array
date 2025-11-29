`include "systolic.vh"

// Oct 26 2025
// Todo: add final signal when the last iteration of matrix multiplication
// (psum loader), last signal accepted -> FSM state will changed to ST_IDLE.

// Oct 29 2025
// Todo: remove m-dim info, due to the systolic array does not need m order (only n, k)

module systolic_ctrl_matmul (
    input                            CLK,
    input                            RST_N,

    // Decoder IF
    input wire                       START_MATMUL_I,
    output                           DONE_MATMUL_O,

    input wire [`PARAM_WIDTH-1:0]    PARAM_M_I,
    input wire [`PARAM_WIDTH-1:0]    PARAM_N_I,
    input wire [`PARAM_WIDTH-1:0]    PARAM_K_I,

    // SRAMC IF
    output [`PE_ROW-1:0]             REQ_MAT_ISRAM_EN_O,
    output [`ADDR_WIDTH-1:0]         REQ_MAT_ISRAM_ADDR_O,

    output [`PE_ROW_ID_WIDTH-1:0]    REQ_MAT_WSRAM_PE_ROW_ID_O,
    output [`PE_COL-1:0]             REQ_MAT_WSRAM_EN_O,
    output [`ADDR_WIDTH-1:0]         REQ_MAT_WSRAM_ADDR_O,

    output [`PE_COL-1:0]             REQ_MAT_PSRAM_EN_O,
    output                           REQ_MAT_PSRAM_WE_O,
    output [`ADDR_WIDTH-1:0]         REQ_MAT_PSRAM_ADDR_O
);

    localparam  ST_IDLE         = 0,
                ST_SET_PARAM    = 1,
                ST_INIT_PSUM    = 2,
                ST_LD_MAT_A     = 3,
                ST_LD_MAT_B     = 4,
                ST_WAIT_MATMUL  = 5,
                ST_DONE         = 6;

    localparam  NUM_STATE       = 7;

    reg [NUM_STATE-1:0]         current_state_r;
    reg [NUM_STATE-1:0]         next_state;

    reg [`PARAM_WIDTH-1:0]      n_rem_r, k_rem_r;
    reg [`PARAM_WIDTH-1:0]      m_iter_max_r, n_iter_max_r, k_iter_max_r;
    reg [`PARAM_WIDTH-1:0]      m_iter_r, n_iter_r, k_iter_r;

    reg  [`ADDR_WIDTH-1:0]     base_isram_addr_r, base_wsram_addr_r, base_psram_addr_r;
    reg  [`ADDR_WIDTH-1:0]     isram_addr_r, wsram_addr_r, psram_addr_r;
    wire [`ADDR_WIDTH-1:0]     isram_addr_max, wsram_addr_max, psram_addr_max;
    wire                        is_isram_addr_max, is_wsram_addr_max, is_psram_addr_max;
    // reg [`PE_ROW_ID_WIDTH-1:0]  wsram_pe_row_id_r;

    wire                        is_last_m, is_last_n, is_last_k;
    wire                        has_n_rem, has_k_rem;

    wire [`PE_ROW-1:0]          isram_load_mask;
    wire [`PE_COL-1:0]          wsram_load_mask, psram_load_mask, psram_init_mask;

    // one matmul needs psum loading cycle + `PE_ROW depth
    reg [$clog2(`PE_ROW):0]     wait_matmul_count_r;
    wire                        is_matmul_done;

    assign is_last_m = (m_iter_r == (m_iter_max_r - `PARAM_WIDTH'd1));
    assign is_last_n = (n_iter_r == (n_iter_max_r - `PARAM_WIDTH'd1));
    assign is_last_k = (k_iter_r == (k_iter_max_r - `PARAM_WIDTH'd1));

    assign has_n_rem = (n_rem_r != 'h0);
    assign has_k_rem = (k_rem_r != 'h0);

    assign isram_addr_max = PARAM_M_I;
    // assign wsram_addr_max = is_last_k && has_k_rem ? k_rem_r : `PARAM_WIDTH'd`PE_ROW;
    assign wsram_addr_max = is_last_n && has_k_rem ? k_rem_r : `PARAM_WIDTH'd`PE_ROW;
    assign psram_addr_max = PARAM_M_I;

    assign isram_load_mask = is_last_k & has_k_rem ? ((1 << k_rem_r)-1) : ((1 << `PE_ROW)-1);
    assign wsram_load_mask = is_last_n & has_n_rem ? ((1 << n_rem_r)-1) : ((1 << `PE_COL)-1);
    assign psram_load_mask = is_last_n & has_n_rem ? ((1 << n_rem_r)-1) : ((1 << `PE_COL)-1);
    assign psram_init_mask = ((1 << `PE_COL)-1);

    assign is_isram_addr_max = (isram_addr_r == (isram_addr_max - `PARAM_WIDTH'd1));
    assign is_wsram_addr_max = (wsram_addr_r == (wsram_addr_max - `PARAM_WIDTH'd1));
    assign is_psram_addr_max = (psram_addr_r == (psram_addr_max - `PARAM_WIDTH'd1));

    assign is_matmul_done = (wait_matmul_count_r == ((1 << ($clog2(`PE_ROW)+1)) - 1)); // wait_matmul_count_r == 2*PE_ROW

    // State transition comb logic
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
                next_state = is_psram_addr_max & is_last_m ? (1 << ST_LD_MAT_B) : (1 << ST_INIT_PSUM);
            end
            current_state_r[ST_LD_MAT_B]: begin
                next_state = is_wsram_addr_max ? (1 << ST_LD_MAT_A) : (1 << ST_LD_MAT_B);
            end
            current_state_r[ST_LD_MAT_A]: begin
                next_state = is_isram_addr_max ? (is_last_n & is_last_k ? (1 << ST_WAIT_MATMUL) : (1 << ST_LD_MAT_B)) : (1 << ST_LD_MAT_A);
            end
            current_state_r[ST_WAIT_MATMUL]: begin
                next_state = is_matmul_done ? (1 << ST_DONE) : (1 << ST_WAIT_MATMUL);
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

    // Iteration variable
    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            m_iter_r <= 'h0;
            n_iter_r <= 'h0;
            k_iter_r <= 'h0;

            m_iter_max_r <='h0;
            n_iter_max_r <='h0;
            k_iter_max_r <='h0;

            n_rem_r <= 'h0;
            k_rem_r <= 'h0;
        end
        else begin
            if (current_state_r[ST_SET_PARAM]) begin
                m_iter_r <= 'h0;
                n_iter_r <= 'h0;
                k_iter_r <= 'h0;

                m_iter_max_r <= (PARAM_M_I + `PE_COL - 1) >> $clog2(`PE_COL); // ceil operation
                n_iter_max_r <= (PARAM_N_I + `PE_COL - 1) >> $clog2(`PE_COL);
                k_iter_max_r <= (PARAM_K_I + `PE_ROW - 1) >> $clog2(`PE_ROW);

                n_rem_r <= (PARAM_N_I & ((1 << $clog2(`PE_COL)) - 1)); // Modulo
                k_rem_r <= (PARAM_K_I & ((1 << $clog2(`PE_ROW)) - 1));
            end

            if (is_psram_addr_max)
                m_iter_r <= m_iter_r + `PARAM_WIDTH'd1;

            if (current_state_r[ST_LD_MAT_B] | current_state_r[ST_LD_MAT_A])
                k_iter_r <= k_iter_r + `PARAM_WIDTH'd1;

            if (is_last_k && is_isram_addr_max) begin
                k_iter_r <= 'h0;
                n_iter_r <= n_iter_r + `PARAM_WIDTH'd1;
            end

            if (is_last_k && is_wsram_addr_max) begin
                k_iter_r <= 'h0;
            end

        end
    end

    // SRAM address count
    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            base_isram_addr_r <= 'h0;
            base_wsram_addr_r <= 'h0;
            base_psram_addr_r <= 'h0;

            isram_addr_r <= 'h0;
            wsram_addr_r <= 'h0;
            psram_addr_r <= 'h0;

            wait_matmul_count_r <= 'h0;
        end
        else begin
            // wsram addr
            if (current_state_r[ST_LD_MAT_B]) begin
                if (is_wsram_addr_max) begin
                    wsram_addr_r <= 'h0;

                    if (is_last_k)
                        base_wsram_addr_r <= base_wsram_addr_r + wsram_addr_r;
                end
                else begin
                    wsram_addr_r <= wsram_addr_r + 1;
                end

                // // Note: The pe_row_id must be synchronized with wsram_valid_r
                // // Due to load wsram consumes 1-cycle,
                // // Simply assign wsram_pe_row_id = wsram_addr_r is prohibited.
                // wsram_pe_row_id_r <= wsram_addr_r;
            end

            // psram addr
            if (current_state_r[ST_INIT_PSUM]) begin
                if (is_last_m && is_psram_addr_max)
                    psram_addr_r <= 'h0;
                else
                    psram_addr_r <= psram_addr_r + 1'd1;
            end
            else if (current_state_r[ST_LD_MAT_A]) begin
                if (is_last_k && is_psram_addr_max)
                    if (is_last_n)
                        base_psram_addr_r <= 'h0;
                    else
                        base_psram_addr_r <= base_psram_addr_r + psram_addr_r;
                else
                    psram_addr_r <= psram_addr_r + 1'd1;
            end
           
            // isram addr
            if (current_state_r[ST_LD_MAT_A]) begin
                if (is_last_k && is_isram_addr_max) begin
                    isram_addr_r <= 'h0;
                end
                else begin
                    isram_addr_r <= isram_addr_r + 1'd1;
                end
            end

            // wait matmul count
            if (current_state_r[ST_WAIT_MATMUL])
                wait_matmul_count_r <= wait_matmul_count_r + 1'd1;
            else
                wait_matmul_count_r <= 'h0;
        end
    end

    // output assignment
    assign DONE_MATMUL_O = current_state_r[ST_DONE];

    assign REQ_MAT_ISRAM_EN_O   = current_state_r[ST_LD_MAT_A] ? isram_load_mask : 'h0;
    assign REQ_MAT_ISRAM_ADDR_O = base_isram_addr_r + isram_addr_r;

    // assign REQ_MAT_WSRAM_PE_ROW_ID_O = wsram_pe_row_id_r;
    assign REQ_MAT_WSRAM_PE_ROW_ID_O = wsram_addr_r[`PE_ROW_ID_WIDTH-1:0];
    assign REQ_MAT_WSRAM_EN_O   = current_state_r[ST_LD_MAT_B] ? wsram_load_mask : 'h0;
    assign REQ_MAT_WSRAM_ADDR_O = base_wsram_addr_r + wsram_addr_r;

    assign REQ_MAT_PSRAM_EN_O   = current_state_r[ST_INIT_PSUM] ? psram_init_mask :
                                  current_state_r[ST_LD_MAT_A] ? psram_load_mask : 'h0;
    assign REQ_MAT_PSRAM_WE_O  = current_state_r[ST_INIT_PSUM] ? 1'b0 : 1'b1;
    assign REQ_MAT_PSRAM_ADDR_O = base_psram_addr_r + psram_addr_r;

    `ifdef SIM
        // string sim_current_state;
        reg [127:0] sim_current_state;

        always @* begin
            case (1'b1)
                current_state_r[ST_IDLE]:           sim_current_state = "ST_IDLE";
                current_state_r[ST_SET_PARAM]:      sim_current_state = "ST_SET_PARAM";
                current_state_r[ST_INIT_PSUM]:      sim_current_state = "ST_INIT_PSUM";
                current_state_r[ST_LD_MAT_A]:       sim_current_state = "ST_LD_MAT_A";
                current_state_r[ST_LD_MAT_B]:       sim_current_state = "ST_LD_MAT_B";
                current_state_r[ST_WAIT_MATMUL]:    sim_current_state = "ST_WAIT_MATMUL";
                current_state_r[ST_DONE]:           sim_current_state = "ST_DONE";
                default:                            sim_current_state = "ST_UNKNOWN";
            endcase
        end
    `endif

endmodule