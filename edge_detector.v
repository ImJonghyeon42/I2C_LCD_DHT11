`timescale 1ns/1ps
module edge_detector(
	input clk,
	input cp_in,
	input reset,
	output p_edge,
	output n_edge
);

	reg cp_in_old, cp_in_cur;
	
	always@(posedge clk or negedge reset) begin
		if(~reset) begin
			cp_in_old <= 1'b0; cp_in_cur <= 1'b0;
		end 
		else begin
			cp_in_old<= cp_in_cur;
			cp_in_cur<=cp_in;
		end
	end
	
	assign p_edge = ~cp_in_old & cp_in_cur;
	assign n_edge = cp_in_old & ~cp_in_cur;
endmodule
