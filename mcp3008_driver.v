`timescale 1ns/1ps

module mcp3008_driver (
    input clk,
    input rst_n,
    input start,
	
    output reg [9:0] x_data_out, //최종 X축 10비트 데이터
    output reg [9:0] y_data_out, //최종 Y축 10비트 데이터
    output reg data_valid,
    // SPI Interface
    output reg spi_sck ,
    output reg spi_cs,
    output reg spi_mosi,
    input spi_miso
);
    
    // 상태 정의
    localparam S_IDLE = 3'd0;
    localparam S_COMM_X = 3'd1; // X축 통신
    localparam S_COMM_Y = 3'd2; // Y축 통신
    localparam S_DONE = 3'd3; // 완료 상태
	
	localparam COMM_BITS = 16; // 1 command + 1 null + 10 data + a few extra
	reg [4:0] bit_count;
	
    reg [1:0] state = S_IDLE;
    reg [9:0] x_buffer,y_buffer;
    // X축(채널0), Y축(채널1)을 읽기 위한 명령어
    localparam CMD_CH0 = 5'b11000;// {Start(1), SGL/DIFF(1), D2(0), D1(0), D0(0)} -> 5'b11000
    localparam CMD_CH1 = 5'b11001; // {Start(1), SGL/DIFF(1), D2(0), D1(0), D0(1)} -> 5'b11001

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // 초기화
            spi_cs <= 1'b1; // Chip Select는 Active Low이므로 평소에 High
            spi_sck <= 1'b0;
            spi_mosi <= 1'b0;
            state <= S_IDLE;
            data_valid <= 1'b0;
            bit_count <= 0;
			x_data_out <= 0;
			y_data_out <= 0;
			x_buffer <= 0; 
			y_buffer <= 0; 
        end else begin
            data_valid <= 1'b0; // 매 클럭마다 초기화, S_DONE에서만 1이 됨

            case (state)
                S_IDLE: begin
                    if (start) begin
                        spi_cs <= 1'b0; // 통신 시작, CS를 Low로                        
                        bit_count <= 0;
                        state <= S_COMM_X;
                    end
                end

                S_COMM_X: begin
                    spi_sck  <= ~spi_sck // 시스템 클럭의 2배 주기로 SCK 생성
                     // SCK의 상승 엣지에 MOSI를 출력하고, 하강 엣지에 MISO를 읽음
					if(spi_sck == 1'b0) begin // 상승 엣지 직전
						if(bit_count < 5) begin  // 5비트 명령어 전송
							spi_mosi <= CMD_CH0[4 - bit_count];
						end 
						else begin
							spi_mosi <= 1'b0;// 명령어 전송 후엔 0 출력
						end
					end
					else begin // 하강 엣지 직전 (MISO 읽는 타이밍)
						if(bit_count >= 6) begin// Null bit 이후부터 데이터 수신
							x_buffer <= {x_buffer[8:0], spi_miso};
						end
						bit_count <= bit_count + 1;
					end

					if(bit_count == COMM_BITS) begin
						bit_count <= 0; // Y축 통신을 위해 카운터 리셋
						state <= S_COMM_Y;
					end
				end
				
				S_COMM_Y: begin
                    spi_sck  <= ~spi_sck // 시스템 클럭의 2배 주기로 SCK 생성
                     // SCK의 상승 엣지에 MOSI를 출력하고, 하강 엣지에 MISO를 읽음
					if(spi_sck == 1'b0) begin // 상승 엣지 직전
						if(bit_count < 5) begin  // 5비트 명령어 전송
							spi_mosi <= CMD_CH1[4 - bit_count];
						end 
						else begin
							spi_mosi <= 1'b0;// 명령어 전송 후엔 0 출력
						end
					end
					else begin // 하강 엣지 직전 (MISO 읽는 타이밍)
						if(bit_count >= 6) begin// Null bit 이후부터 데이터 수신
							y_buffer <= {y_buffer[8:0], spi_miso};
						end
						bit_count <= bit_count + 1;
					end

					if(bit_count == COMM_BITS) begin
						state <= S_DONE;
					end
				end

                S_DONE: begin
                    spi_cs <= 1'b1; // 통신 종료
					spi_sck <= 1'b0;
                    x_data_out <= x_buffer; // 최종 데이터를 출력 레지스터로 전달
                    y_data_out <= y_buffer; // 최종 데이터를 출력 레지스터로 전달
                    data_valid <= 1'b1; // 데이터 유효 신호 1클럭 발생
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
