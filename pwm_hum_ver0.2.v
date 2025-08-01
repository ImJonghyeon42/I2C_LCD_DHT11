//문법 오류: always 블록 안에서는 assign 문을 사용할 수 없습니다. 출력을 reg 타입으로 선언하고 직접 값을 할당
//논리 충돌: if 문을 else if 없이 여러 번 사용하여, 세 개의 PWM 로직이 매 클럭마다 서로 충돌하며 pwm_out 값을 덮어쓰려고 시도
//잘못된 PWM 생성 방식: PWM은 고정된 주기 안에서 High 신호의 비율(Duty Cycle)을 조절하는 방식입니다. 하지만 기존 코드는 주기가 고정되어 있지 않고, 카운터가 특정 값에 도달하면 바로 리셋되어 거의 항상 High 신호만 출력
`timescale 1ns/1ps

module pwm_hum (
	input clk,
	input rst,
	input [3:0] humidity10,
	output reg pwm
);

	localparam RERIOD = 1000 - 1; // 모터가 주로 1kHz에서 동작
	
	reg [9:0] counter = 0;
	reg [9:0] duty_cycle = 0;
	
	always@(*) begin
		case(humidity10)
			4'd0, 4'd1: //습도 20% 미만
				duty_cycle = (RERIOD * 20) / 100; // (999 * 20) / 100 = 19980 / 100 = 199 (정수 계산)
			4'd2, 4'd3, 4'd4: // 습도 50% 미만
				duty_cycle = (RERIOD * 50) / 100; 
			4'd5, 4'd6, 4'd7: // 습도 80% 미만
				duty_cycle = (RERIOD * 80) / 100; 
			default: //습도 80% 이상
				duty_cycle = 0;
		endcase
	end
	
	always@(posedge clk or negedge rst) begin
		if(~rst) begin
			counter <= 10'd0;
			pwm <= 1'b0;
		end
		else begin
			if(counter == RERIOD) begin
				counter <= 0;
			end else begin
				counter <= counter + 1'b1;
			end
			
			if(counter < duty_cycle) pwm <= 1'b1;
			else pwm <= 1'b0;
		end
	end
	
endmodule
	
	
