//신호에 따라 LCD에 표시
//text 모듈에서 블루투스로 받은 메뉴 상태를 버튼 신호가 바로 다음 순간에 덮어써버리는 논리적인 오류 발생
//rx 기능 mode 모듈로 이동
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

	always@(*) begin			
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
				2'd2: row2 <= "  Timer 120min ";
				default: row2 <= "                ";
			endcase
		end
	end
endmodule	
			