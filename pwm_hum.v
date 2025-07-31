//문법 오류: always 블록 안에서는 assign 문을 사용할 수 없습니다. 출력을 reg 타입으로 선언하고 직접 값을 할당
//논리 충돌: if 문을 else if 없이 여러 번 사용하여, 세 개의 PWM 로직이 매 클럭마다 서로 충돌하며 pwm_out 값을 덮어쓰려고 시도
//잘못된 PWM 생성 방식: PWM은 고정된 주기 안에서 High 신호의 비율(Duty Cycle)을 조절하는 방식입니다. 하지만 기존 코드는 주기가 고정되어 있지 않고, 카운터가 특정 값에 도달하면 바로 리셋되어 거의 항상 High 신호만 출력
`timescale 1ns/1ps

module pwm_hum #(parameter duty_50 = 49_000_000, duty_20 = 19_000_000, duty_80 = 79_000_000)
(	input clk,
	input rst,
	input [3:0] humidity10,
	output reg pwm
);
	reg [27:0] cnt_20;
	reg [27:0] cnt_50;
	reg [27:0] cnt_80;
	reg pwm_out;
	
	always@(posedge clk or negedge rst) begin
		if(rst) begin
			cnt_20 <= 28'd0;
			cnt_50 <= 28'd0;
			cnt_80 <= 28'd0;
		end
		
		else if(humidity10 > 4'd8) pwm_out = 0;
		
		else begin
			if(cnt_20 > duty_20 && humidity10 < 4'd2) begin
				cnt_20 <= 28'd0;
				pwm_out <= 0;
			end
			else begin
				cnt_20 <= cnt_20 + 1'b1;
				pwm_out <= 1;
			end
			
			if(cnt_50 > duty_50 && humidity10 < 4'd5) begin
				cnt_50 <= 28'd0;
				pwm_out <= 0;
			end
			else begin
				cnt_50 <= cnt_50 + 1'b1;
				pwm_out <= 1;
			end
			
			if(cnt_80 > duty_80 && humidity10 < 4'd8) begin
				cnt_80 <= 28'd0;
				pwm_out <= 0;
			end
			else begin
				cnt_80 <= cnt_80 + 1'b1;
				pwm_out <= 1;
			end
			
		end
		
		assign pwm = pwm_out;
		
	end
			
endmodule
	
	