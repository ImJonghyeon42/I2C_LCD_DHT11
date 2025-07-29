`timescale 1ns/1ps

module text(
	input clk,
	input rst,
	output reg [127:0] row1,
	output reg [127:0] row2,
    input  [3:0] humidity10, humidity0,
    input  [3:0] temperature10, temperature0,
	input sw,
	input [1:0] btn_LR,
	input [1:0] btn_UD
);
	
	always@(posedge clk or negedge rst) begin
		if(~rst) begin
			row1 <= 128'h00;
			row2 <= 128'h00;
		end
		else begin				
			if(sw) begin
				row1 <= {"Temp: ", (temperature10 + 8'h30), (temperature0 + 8'h30), "'C      "};
                row2 <= {"Humi: " , (humidity10 + 8'h30), (humidity0 + 8'h30), "%       "};
			end 
			else begin
				case(btn_LR)
					2'd0: row1 <= "   Cotton      ";
					2'd1: row1 <= "    Woody      ";
					2'd2: row1 <= "   Citrus      ";
					default: row1 <= "                ";
				endcase
				case(btn_UD)
					2'd0: row2 <= "  Timer 30min  ";
					2'd1: row2 <= "  Timer 60min  ";
					2'd2: row2 <= " Timer 120min  ";
					default: row2 <= "                ";
				endcase
			end
		end
	end	
endmodule	
			