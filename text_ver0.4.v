//신호에 따라 LCD에 표시
//text 모듈에서 블루투스로 받은 메뉴 상태를 버튼 신호가 바로 다음 순간에 덮어써버리는 논리적인 오류 발생
//rx 기능 mode 모듈로 이동
//text.v를 수정하여 sw 스위치를 켜면 ADC 값을 표시
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
	input [9:0] x_adc,
	input [9:0] y_adc
);
	function [15:0] int_to_ascii(input [9:0] val);
		
		d3 = val / 1000;
		d2 = (val % 1000) / 100;
		d1 = (val % 100) / 10;
		d0 = val % 10;
		int_to_ascii = {(d3+8'h30), (d2+8'h30),(d1+8'h30),(d0+8'h30)};
	endfunction
	
	always@(*) begin	
		reg [3:0] x_d3, x_d2, x_d1, x_d0;
		reg [3:0] y_d3, y_d2, y_d1, y_d0;
		
		if(sw) begin
			x_d3 = x_adc / 1000;
			x_d2 = (x_adc % 1000) / 100;
			x_d1 = (x_adc % 100) / 10;
			x_d0 = x_adc % 10;
						
			row1 <= {"X: ", (x_d3 + 8'h30),(x_d2 + 8'h30),(x_d1 + 8'h30),(x_d0 + 8'h30), "     "};
			y_d3 = y_adc / 1000;
			y_d2 = (y_adc % 1000) / 100;
			y_d1 = (y_adc % 100) / 10;
			y_d0 = y_adc % 10;
			row1 <= {"Y: ", (y_d3 + 8'h30),(y_d2 + 8'h30),(y_d1 + 8'h30),(y_d0 + 8'h30), "     "};
            
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
				2'd2: row2 <= "  Timer 120min ";
				default: row2 <= "                ";
			endcase
		end
	end
endmodule	
			
