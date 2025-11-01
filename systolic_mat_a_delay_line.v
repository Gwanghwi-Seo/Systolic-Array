`include "systolic.vh"

module systolic_mat_a_delay_line #(
    parameter DEPTH = 1     // not consider 0-depth
) (
    input                    CLK,
    input                    RST_N,
    input                    VALID_I,
    input [`DATA_WIDTH-1:0]  DATA_I,

    output                   VALID_O,
    output [`DATA_WIDTH-1:0] DATA_O
);

    reg [`DATA_WIDTH-1:0] data_pipe_r  [0: DEPTH-1];
    reg                   valid_pipe_r [0: DEPTH-1];

    integer i;
    always @(posedge CLK, negedge RST_N) begin
        if (!RST_N) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                data_pipe_r[i] <= 'h0;
                valid_pipe_r[i] <= 1'b0;
            end
        end
        else begin
            // pipe stage 0
            valid_pipe_r[0] <= VALID_I;
            data_pipe_r[0] <= DATA_I;

            // pipe stage 1 to N
            for (i = 1; i < DEPTH; i = i+1) begin
                valid_pipe_r[i] <= valid_pipe_r[i-1];
                data_pipe_r[i] <= data_pipe_r[i-1];
            end
        end
    end

    assign VALID_O = valid_pipe_r[DEPTH-1];
    assign DATA_O = data_pipe_r[DEPTH-1];

endmodule