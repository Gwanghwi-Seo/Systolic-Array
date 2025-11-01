`timescale 1ns / 1ps

`include "../systolic.vh"

module tb_systolic_mat_a_loader;
    logic CLK;
    logic RST_N;

    logic [`PE_ROW-1:0]               mat_a_valid_i;
    logic [`PE_ROW*`DATA_WIDTH-1:0]   mat_a_i;

    wire [`PE_ROW-1:0]                mat_a_valid_o;
    wire [`PE_ROW*`DATA_WIDTH-1:0]    mat_a_o;
    
    systolic_mat_a_loader U_DUT (
        .CLK            (CLK),
        .RST_N          (RST_N),
        .MAT_A_VALID_I  (mat_a_valid_i),
        .MAT_A_I        (mat_a_i),
        .MAT_A_VALID_O  (mat_a_valid_o),
        .MAT_A_O        (mat_a_o)
    );

    // 1. Clock 생성 (100MHz, 10ns 주기)
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK; // 5ns 마다 토글
    end

    // --- 테스트 시퀀스 및 자동 검증 ---
    initial begin
        $display("Time %t: [TB] 시뮬레이션 시작. 리셋을 활성화합니다.", $time);
        
        // 리셋 및 초기화
        RST_N = 1'b0;
        mat_a_valid_i = '0;
        mat_a_i       = '0;
        
        repeat (2) @(posedge CLK);
        RST_N = 1'b1; // 리셋 비활성화
        
        @(posedge CLK); // t=1

        // --- Cycle 1: 1-cycle 데이터 펄스 주입 ---
        mat_a_valid_i = (1 << `PE_ROW) - 1;
        for (int i = 0; i < `PE_ROW; i++) begin
            mat_a_i[`DATA_WIDTH*i +: `DATA_WIDTH] = i;
        end
        @(posedge CLK); // t=2

        // --- Cycle 2: 입력 비활성화 & Row 0 검증 ---
        // mat_a_valid_i = '0;
        // mat_a_i       = '0;
        mat_a_valid_i = (1 << `PE_ROW) - 1;
        for (int i = 0; i < `PE_ROW; i++) begin
            mat_a_i[`DATA_WIDTH*i +: `DATA_WIDTH] = `PE_ROW-i;
        end
        // Row 0 (Depth 0, 1-cycle delay) 출력 검사
        // check_output(0, mat_a_valid_o[0], mat_a_o[0*`DATA_WIDTH +: `DATA_WIDTH], 1'b1, 8'hA0);

        @(posedge CLK); // t=3
        mat_a_valid_i = '0;
        mat_a_i       = '0;

        // --- Cycle 3: Row 1 검증 ---
        // check_output(0, mat_a_valid_o[0], 'x, 1'b0, 'x); // Row 0은 이제 invalid
        // Row 1 (Depth 1, 2-cycle delay) 출력 검사
        // check_output(1, mat_a_valid_o[1], mat_a_o[1*`DATA_WIDTH +: `DATA_WIDTH], 1'b1, 8'hB1);

        @(posedge CLK); // t=4

        // --- Cycle 4: Row 2 검증 ---
        // check_output(1, mat_a_valid_o[1], 'x, 1'b0, 'x); // Row 1은 이제 invalid
        // Row 2 (Depth 2, 3-cycle delay) 출력 검사
        // check_output(2, mat_a_valid_o[2], mat_a_o[2*`DATA_WIDTH +: `DATA_WIDTH], 1'b1, 8'hC2);

        @(posedge CLK); // t=5

        // --- Cycle 5: Row 3 검증 ---
        // check_output(2, mat_a_valid_o[2], 'x, 1'b0, 'x); // Row 2는 이제 invalid
        // Row 3 (Depth 3, 4-cycle delay) 출력 검사
        // check_output(3, mat_a_valid_o[3], mat_a_o[3*`DATA_WIDTH +: `DATA_WIDTH], 1'b1, 8'hD3);

        @(posedge CLK); // t=6
        @(posedge CLK); // t=6
        @(posedge CLK); // t=6
        @(posedge CLK); // t=6

        // --- Cycle 6: 최종 상태 검증 ---
        // check_output(3, mat_a_valid_o[3], 'x, 1'b0, 'x); // Row 3은 이제 invalid

        // $display("Time %t: [PASS] 테스트 완료. 모든 Skew 출력이 정상적으로 확인되었습니다.", $time);
        $finish;
    end

    // --- 자동 검증을 위한 Helper Task ---
    task automatic check_output (
        int   row_index,
        logic actual_valid,
        logic [`DATA_WIDTH-1:0] actual_data,
        logic expected_valid,
        logic [`DATA_WIDTH-1:0] expected_data
    );
        // 유효하지 않을 때는 데이터 값을 비교하지 않음
        if (actual_valid === expected_valid && (actual_valid === 1'b0 || actual_data === expected_data)) begin
            $display("Time %t: [PASS] Row %0d: Valid=%b, Data=%h", $time, row_index, actual_valid, actual_data);
        end else begin
            $error("Time %t: [FAIL] Row %0d: Expected Valid=%b, Data=%h. Got Valid=%b, Data=%h",
                   $time, row_index, expected_valid, expected_data, actual_valid, actual_data);
            $finish;
        end
    endtask

endmodule