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
	input [1:0] btn_UD,
	input rx_vaild,
	input [7:0] rx_data_in
);

	reg [1:0] current_lr_state;
	reg [1:0] current_ud_state;
	
	always@(posedge clk or negedge rst) begin
		if(~rst) begin
			current_lr_state <= 2'd0;
			current_ud_state <= 2'd0;
		end
		else if (rx_vaild) begin
			case(rx_data_in)
				8'h01: current_lr_state <= 2'd0;
				8'h02: current_lr_state <= 2'd1;
				8'h03: current_lr_state <= 2'd2;
				8'h1E: current_ud_state <= 2'd0;
				8'h3C: current_ud_state <= 2'd1;
				8'h78: current_ud_state <= 2'd2;
				default: ;
			endcase
		end
		else begin
			current_lr_state <= btn_LR;
			current_ud_state <= btn_UD;
		end
	end
	
	always@(*) begin			
		if(sw) begin
			row1 <= {"Temp: ", (temperature10 + 8'h30), (temperature0 + 8'h30), "'C      "};
            row2 <= {"Humi: " , (humidity10 + 8'h30), (humidity0 + 8'h30), "%       "};
		end 
		else begin
			case(current_lr_state)
				2'd0: row1 <= "   Cotton      ";
				2'd1: row1 <= "    Woody      ";
				2'd2: row1 <= "   Citrus      ";
				default: row1 <= "                ";
			endcase
			case(current_ud_state)
				2'd0: row2 <= "  Timer 30min  ";
				2'd1: row2 <= "  Timer 60min  ";
				2'd2: row2 <= "  Timer 120min ";
				default: row2 <= "                ";
			endcase
		end
	end
endmodule	
			