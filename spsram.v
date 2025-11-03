module spsram #(
    parameter DEPTH=1024,
    parameter ADDR_WIDTH=14,
    parameter DATA_WIDTH=8
)(
    input                           clka,
    input                           ena,
    input                           wea,
    input       [ADDR_WIDTH-1:0]    addra,
    input       [DATA_WIDTH-1:0]    dina,
    output reg  [DATA_WIDTH-1:0]    douta
);

    reg [DATA_WIDTH-1:0] mem_r [0:DEPTH-1];

    // Initialization
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem_r[i] = 'h0;
        end
    end

    // Port A
    // SRAM Configuration: Active row, write :0, read: 1
    always @(posedge clka) begin
        if (!ena) begin
            if (!wea)
                mem_r[addra] <= dina; 

            douta <= mem_r[addra];
        end
    end

endmodule    