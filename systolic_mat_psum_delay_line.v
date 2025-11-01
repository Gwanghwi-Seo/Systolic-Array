`include "systolic.vh"

module systolic_mat_psum_delay_line #(
    parameter DEPTH = 1
) (
    input                        CLK,
    input                        RST_N,

    input                        VALID_I,
    input   [`ADDR_WIDTH-1:0]    ADDR_I,
    input   [`PSUM_WIDTH-1:0]    PSUM_I,

    output                       VALID_O,
    output  [`ADDR_WIDTH-1:0]    ADDR_O,
    output  [`PSUM_WIDTH-1:0]    PSUM_O
);
    reg                   valid_pipe_r[0:DEPTH-1];
    reg [`ADDR_WIDTH-1:0] addr_pipe_r [0:DEPTH-1];
    reg [`PSUM_WIDTH-1:0] psum_pipe_r [0:DEPTH-1];

    integer i;
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                valid_pipe_r[i] <= 1'b0;
                addr_pipe_r[i] <= 'h0;
                psum_pipe_r[i] <= 'h0;
            end
        end
        else begin
            valid_pipe_r[0] <= VALID_I;
            addr_pipe_r[0]  <= ADDR_I;
            psum_pipe_r[0]  <= PSUM_I;

            for (i = 1; i < DEPTH; i = i + 1) begin
                valid_pipe_r[i] <= valid_pipe_r[i-1];
                addr_pipe_r[i]  <= addr_pipe_r[i-1];
                psum_pipe_r[i]  <= psum_pipe_r[i-1];
            end
        end
    end

    assign VALID_O = valid_pipe_r[DEPTH-1];
    assign ADDR_O  = addr_pipe_r[DEPTH-1];
    assign PSUM_O  = psum_pipe_r[DEPTH-1];
endmodule