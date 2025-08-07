`timescale 1ns/1ps

// CH1 하나만 읽는 테스트용 모듈
module test_adc_ch1_reader (
    input clk,
    input rst_n,
    input start,
    output reg [9:0] adc_data_out, // 출력 포트 1개로 단순화
    output reg data_valid,
    // SPI Interface
    output reg spi_sck,
    output reg spi_cs,
    output reg spi_mosi,
    input      spi_miso
);
    // FSM 상태 정의
    localparam S_IDLE = 2'd0;
    localparam S_COMM = 2'd1;
    localparam S_DONE = 2'd2;

    localparam COMM_BITS = 17; // CH1 통신에 필요한 총 클럭 수

    reg [4:0] bit_count;
    reg [1:0] state = S_IDLE; 
    reg [9:0] data_buffer;
    
    // CH1(Single-Ended)을 읽기 위한 고정 명령어: Start | SGL | D2 | D1 | D0 => 11001
    localparam CMD_CH1 = 5'b11001; 

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= S_IDLE;
            spi_cs <= 1'b1;
            spi_sck <= 1'b0;
            spi_mosi <= 1'b0;
            data_valid <= 1'b0;
            bit_count <= 0;
            adc_data_out <= 0;
            data_buffer <= 0; 
        end else begin
            data_valid <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (start) begin
                        spi_cs <= 1'b0;
                        bit_count <= 0;
                        state <= S_COMM;
                    end
                end
                
                S_COMM: begin
                    spi_sck <= ~spi_sck;
                    if (spi_sck == 1'b0) begin // Falling edge
                        // 처음 5비트 동안 CH1 명령어 전송
                        if (bit_count < 5) spi_mosi <= CMD_CH1[4 - bit_count];
                        else spi_mosi <= 1'b0;
                    end else begin // Rising edge
                        // Null Bit(6번째 클럭) 이후부터 데이터 수신
                        if (bit_count >= 6) data_buffer <= {data_buffer[8:0], spi_miso};
                        bit_count <= bit_count + 1;
                    end
                    
                    if (bit_count == COMM_BITS) begin
                        state <= S_DONE;
                    end
                end
                
                S_DONE: begin
                    spi_cs <= 1'b1;
                    spi_sck <= 1'b0;
                    adc_data_out <= data_buffer;
                    data_valid <= 1'b1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule