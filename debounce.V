`timescale 1ns / 1ps

module debounce (
    input clk,          // 1MHz 클럭
    input rst_n,        // 리셋
    input raw_btn,      // 필터링되지 않은 원본 버튼 입력
    output reg clean_btn  // 채터링이 제거된 깨끗한 버튼 출력
);

    // 20ms 디바운싱 시간 (1MHz 클럭 기준)
    // 1 / 1,000,000Hz = 1us per tick. 20ms / 1us = 20000
    parameter DEBOUNCE_TIME = 20000; 

    reg [15:0] counter;
    reg internal_btn;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            internal_btn <= 0;
            clean_btn <= 0;
        end else begin
            // 원본 버튼 신호와 내부 상태가 다를 때만 카운터 동작
            if (raw_btn != internal_btn) begin
                if (counter == DEBOUNCE_TIME) begin
                    internal_btn <= raw_btn; // 안정화되었으므로 상태 변경
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                counter <= 0; // 상태가 같으면 카운터 리셋
            end
            
            clean_btn <= internal_btn; // 최종 출력은 안정화된 내부 상태
        end
    end
endmodule