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
	localparam THRESH_LOW = 200;
	localparam THRESH_HIGH = 800;
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			btn_L_out <= 0; 
			btn_R_out <= 0; 
			btn_U_out <= 0; 
			btn_D_out <= 0; 
		end
		else begin
			if(x_axis_in < THRESH_LOW) btn_L_out <= 1;
			else btn_L_out <= 0;
			if(x_axis_in > THRESH_HIGH) btn_R_out <= 1;
			else btn_R_out <= 0;
			if(y_axis_in < THRESH_LOW) btn_D_out <= 1;
			else btn_D_out <= 0;
			if(y_axis_in > THRESH_HIGH) btn_U_out <= 1;
			else btn_U_out <= 0;
		end
	end
endmodule
