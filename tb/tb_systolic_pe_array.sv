`timescale 1ns/1ps

`include "../systolic.vh"

module tb_systolic_pe_array;

    logic CLK;
    logic RST_N;

    logic [`PE_ROW-1:0]                 MAT_A_VALID_I       ;
    logic [`DATA_WIDTH*`PE_ROW-1:0]     MAT_A_I             ;

    logic [`PE_ROW-1:0]                 MAT_A_VALID_O       ;
    logic [`DATA_WIDTH*`PE_ROW-1:0]     MAT_A_O             ;
    
    logic [`PE_ROW_ID_WIDTH*`PE_COL-1:0]EN_PE_ROW_ID_I;
    logic [`PE_COL-1:0]                 MAT_B_VALID_I ;
    logic [`DATA_WIDTH*`PE_COL-1:0]     MAT_B_I             ;

    logic [`PE_COL-1:0]                 MAT_PSUM_VALID_I    ;
    logic [`ADDR_WIDTH*`PE_COL-1:0]     MAT_PSUM_ADDR_I     ;
    logic [`PSUM_WIDTH*`PE_COL-1:0]     MAT_PSUM_I          ;

    logic [`PE_COL-1:0]                 MAT_PSUM_VALID_O    ;
    logic [`PSUM_WIDTH*`PE_COL-1:0]     MAT_PSUM_O          ;
    logic [`ADDR_WIDTH*`PE_COL-1:0]     MAT_PSUM_ADDR_O     ;

    logic [`PE_COL-1:0]                 PE_ARR_MAT_PSUM_VALID_O    ;
    logic [`PSUM_WIDTH*`PE_COL-1:0]     PE_ARR_MAT_PSUM_O          ;
    logic [`ADDR_WIDTH*`PE_COL-1:0]     PE_ARR_MAT_PSUM_ADDR_O     ;

    logic                   pe_arr_mat_psum_valid [0:`PE_COL-1];
    logic [`PSUM_WIDTH-1:0] pe_arr_mat_psum_data  [0:`PE_COL-1];
    logic [`ADDR_WIDTH-1:0] pe_arr_mat_psum_addr  [0:`PE_COL-1];

    integer i, j;

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    initial begin
        MAT_A_VALID_I    <= 'h0;
        MAT_A_I          <= 'h0;

        EN_PE_ROW_ID_I   <= 'h0; 
        MAT_B_VALID_I    <= 'h0; 
        MAT_B_I          <= 'h0; 

        MAT_PSUM_VALID_I <= 'h0; 
        MAT_PSUM_ADDR_I  <= 'h0; 
        MAT_PSUM_I       <= 'h0; 
        RST_N            <= 1'b0;

        repeat (10) @(posedge CLK);
        RST_N = 1'b1;

        // Weight (Matrix B fetch)
        for (i = 0; i < `PE_COL; i++) begin
            MAT_B_VALID_I  <= (1 << `PE_COL) - 1;

            for (j = 0; j < `PE_COL; j++) begin
                EN_PE_ROW_ID_I[`PE_ROW_ID_WIDTH*j +: `PE_ROW_ID_WIDTH] <= i;
                MAT_B_I[`DATA_WIDTH*j +: `DATA_WIDTH] <= i+1;
            end

            @(posedge CLK);
        end
        MAT_B_VALID_I <= 'h0;

        // Input (Matrix A fetch), PSUM (0 fetch)
        for (i = 0; i < `PE_ROW; i++) begin
            MAT_A_VALID_I <= (1 << `PE_ROW) - 1;
            MAT_PSUM_VALID_I <= (1 << `PE_ROW) - 1;
            MAT_PSUM_I <= 'h0;

            for (j = 0; j < `PE_ROW; j++) begin
                MAT_A_I[`DATA_WIDTH*j +: `DATA_WIDTH] <= i+1;
                MAT_PSUM_ADDR_I[`ADDR_WIDTH*j +: `ADDR_WIDTH] <= i;
            end

            @(posedge CLK);
        end
        MAT_A_VALID_I <= 'h0;
        MAT_PSUM_VALID_I <= 'h0;

        repeat (100) @(posedge CLK);
        $finish;
    end

    generate
        genvar col;
        for (col = 0; col < `PE_COL; col++) begin
            assign pe_arr_mat_psum_valid[col] = PE_ARR_MAT_PSUM_VALID_O[col];
            assign pe_arr_mat_psum_data [col] = PE_ARR_MAT_PSUM_O[`PSUM_WIDTH*col +: `PSUM_WIDTH];
            assign pe_arr_mat_psum_addr [col] = PE_ARR_MAT_PSUM_ADDR_O[`ADDR_WIDTH*col +: `ADDR_WIDTH];
        end
    endgenerate

    systolic_mat_a_loader U_MAT_A_LOADER(
        .CLK            (CLK),
        .RST_N          (RST_N),
    
        .MAT_A_VALID_I  (MAT_A_VALID_I),
        .MAT_A_I        (MAT_A_I),
    
        .MAT_A_VALID_O  (MAT_A_VALID_O),
        .MAT_A_O        (MAT_A_O)
    );

    systolic_mat_psum_loader U_MAT_PSUM_LOADER(
        .CLK                (CLK),
        .RST_N              (RST_N),   

        .MAT_PSUM_VALID_I   (MAT_PSUM_VALID_I),
        .MAT_PSUM_ADDR_I    (MAT_PSUM_ADDR_I),
        .MAT_PSUM_I         (MAT_PSUM_I),

        .MAT_PSUM_VALID_O   (MAT_PSUM_VALID_O),
        .MAT_PSUM_ADDR_O    (MAT_PSUM_ADDR_O),
        .MAT_PSUM_O         (MAT_PSUM_O)
    );

    systolic_pe_array U_PE_ARRAY (
        .CLK                (CLK                 ),
        .RST_N              (RST_N               ),
        .MAT_A_VALID_I      (MAT_A_VALID_O       ),
        .MAT_A_I            (MAT_A_O             ),
                             
        .EN_PE_ROW_ID_I     (EN_PE_ROW_ID_I      ),
        .MAT_B_VALID_I      (MAT_B_VALID_I       ),
        .MAT_B_I            (MAT_B_I             ),
                             
        .MAT_PSUM_VALID_I   (MAT_PSUM_VALID_O    ),
        .MAT_PSUM_ADDR_I    (MAT_PSUM_ADDR_O     ),
        .MAT_PSUM_I         (MAT_PSUM_O          ),
                             
        .MAT_PSUM_VALID_O   (PE_ARR_MAT_PSUM_VALID_O    ),
        .MAT_PSUM_O         (PE_ARR_MAT_PSUM_O          ),
        .MAT_PSUM_ADDR_O    (PE_ARR_MAT_PSUM_ADDR_O     )
    );


endmodule