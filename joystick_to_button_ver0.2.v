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
	localparam DEAD_ZONE_LOW = 400;
	localparam DEAD_ZONE_HIGH = 600;
	
	localparam HOLD_COUNT_TARGET = 5000;
	
	localparam S_IDLE = 0;
	localparam S_HOLD = 1;
	localparam S_FIRE = 2;
	
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
						state_x <= S_FIRE;
					end else begin
						hold_counter_x <= hold_counter_x + 1;
					end
				end
				S_FIRE: begin
					if(x_axis_in < DEAD_ZONE_LOW) btn_L_out <= 1;
					if(x_axis_in > DEAD_ZONE_HIGH) btn_R_out <= 1;
					
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
						state_y <= S_FIRE;
					end else begin
						hold_counter_y <= hold_counter_y + 1;
					end
				end
				S_FIRE: begin
					if(y_axis_in < DEAD_ZONE_LOW) btn_U_out <= 1;
					if(y_axis_in > DEAD_ZONE_HIGH) btn_D_out <= 1;
					
					if(y_axis_in >= DEAD_ZONE_LOW && y_axis_in <= DEAD_ZONE_HIGH) begin
						state_y <= S_IDLE;
					end
				end
			endcase
		end
	end				
endmodule