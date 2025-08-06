//민감도 문제: 조이스틱의 미세한 떨림만으로도 메뉴가 계속 바뀌는 현상
//축 간섭(Crosstalk) 문제: X축을 움직였는데 Y축 메뉴(Timer)가 바뀌는 현상
// -> 벽한 축 분리: X축과 Y축을 처리하는 상태 머신(FSM)을 완전히 분리했습니다. 이제 X축의 값은 Y축 FSM에 어떠한 영향도 주지 않으므로, 축 간섭(Crosstalk) 문제가 완벽히 해결됩니다.
// -> 홀드(Hold) & 지연: 조이스틱이 데드존을 벗어나면 바로 신호를 보내지 않고, S_HOLD 상태로 들어가 HOLD_COUNT_TARGET 만큼의 시간 동안 기다립니다. 아주 짧은 순간적인 떨림은 이 시간을 채우지 못하고 다시 S_IDLE로 돌아가므로, 의도적인 움직임만 감지하게 되어 민감도 문제가 해결됩니다.

module joystick_to_button(
	input clk,
	input rst_n,
	input [9:0] x_axis_in,
	input [9:0] y_axis_in,
	output reg btn_L_out,
	output reg btn_R_out,
	output reg btn_U_out,
	output reg btn_D_out
);
	localparam DEAD_ZONE_LOW = 200;
	localparam DEAD_ZONE_HIGH = 800;
	
	localparam HOLD_COUNT_TARGET = 5000;
	
	localparam S_IDLE = 2'd0;
	localparam S_HOLD = 2'd1;
	localparam S_FIRE = 2'd2;
	
	reg [1:0] state_x = S_IDLE;
	reg [15:0] hold_counter_x = 0;
	
	reg [1:0] state_y = S_IDLE;
	reg [15:0] hold_counter_y = 0;
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			state_x <= S_IDLE;
			hold_counter_x <= 0;
			btn_L_out <= 0; 
			btn_R_out <= 0; 
		end
		else begin
			btn_L_out <= 0;
			btn_R_out <= 0;
			case(state_x)
				S_IDLE: begin	
					if(x_axis_in < DEAD_ZONE_LOW || x_axis_in > DEAD_ZONE_HIGH) begin
						state_x <= S_HOLD;
						hold_counter_x <= 0;
					end
				end
				S_HOLD: begin
					if(x_axis_in >= DEAD_ZONE_LOW && x_axis_in <= DEAD_ZONE_HIGH) begin
						state_x <= S_IDLE;
					end else if (hold_counter_x == HOLD_COUNT_TARGET) begin
						if(x_axis_in < DEAD_ZONE_LOW) btn_L_out <= 1'b1;
						if(x_axis_in > DEAD_ZONE_LOW) btn_R_out <= 1'b1;
						state_x <= S_FIRE;
					end else begin
						hold_counter_x <= hold_counter_x + 1;
					end
				end
				S_FIRE: begin					
					if(x_axis_in >= DEAD_ZONE_LOW && x_axis_in <= DEAD_ZONE_HIGH) begin
						state_x <= S_IDLE;
					end
				end
			endcase
		end
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			state_y <= S_IDLE;
			hold_counter_y <= 0;
			btn_U_out <= 0; 
			btn_D_out <= 0; 
		end
		else begin
			btn_U_out <= 0;
			btn_D_out <= 0;
			case(state_y)
				S_IDLE: begin	
					if(y_axis_in < DEAD_ZONE_LOW || y_axis_in > DEAD_ZONE_HIGH) begin
						state_y <= S_HOLD;
						hold_counter_y <= 0;
					end
				end
				S_HOLD: begin
					if(y_axis_in >= DEAD_ZONE_LOW && y_axis_in <= DEAD_ZONE_HIGH) begin
						state_y <= S_IDLE;
					end else if (hold_counter_y == HOLD_COUNT_TARGET) begin
						if(y_axis_in > DEAD_ZONE_HIGH) btn_U_out <= 1'b1;
						if(y_axis_in < DEAD_ZONE_HIGH) btn_D_out <= 1'b1;
						state_y <= S_FIRE;
					end else begin
						hold_counter_y <= hold_counter_y + 1;
					end
				end
				S_FIRE: begin					
					if(y_axis_in >= DEAD_ZONE_LOW && y_axis_in <= DEAD_ZONE_HIGH) begin
						state_y <= S_IDLE;
					end
				end
			endcase
		end
	end				
endmodule
