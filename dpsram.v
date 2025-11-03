module dpsram #(
    parameter DEPTH=256,
    parameter ADDR_WIDTH=14,
    parameter DATA_WIDTH=24
)(
    input                           clka,
    input                           ena,
    input                           wea,
    input       [ADDR_WIDTH-1:0]    addra,
    input       [DATA_WIDTH-1:0]    dina,
    output reg  [DATA_WIDTH-1:0]    douta,

    input                           clkb,
    input                           enb,
    input                           web,
    input       [ADDR_WIDTH-1:0]    addrb,
    input       [DATA_WIDTH-1:0]    dinb,
    output reg  [DATA_WIDTH-1:0]    doutb
);

    reg [DATA_WIDTH-1:0] mem_r [0:DEPTH-1];

    // Initialize memory
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

    // Port B
    // SRAM Configuration: Active row, write :0, read: 1
    always @(posedge clkb) begin
        if (!enb) begin
            if (!web)
                mem_r[addrb] <= dinb;

            doutb <= mem_r[addrb];
        end
    end

    // This is a non-synthesizable check that only runs during simulation
    always @(posedge clka) begin
        if (!ena && !wea && !enb && !web && (addra == addrb)) begin
            $error("FATAL: Dual-port memory write collision...");
            $finish;
        end
    end

endmodule