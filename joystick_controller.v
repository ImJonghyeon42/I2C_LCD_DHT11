`timescale 1ns/1ps
module joystick_controller(
	input clk_1MHz,
	input clk_100MHz,
	input rst_n,
//-------조이스틱 아날로그 입력----
	input joy_x_p,
	input joy_x_n,
	input joy_y_p,
	input joy_y_n,
//----------최종 제어 출력---------------
	output reg joystick_up,
	output reg joystick_down,
	output reg joystick_left,
	output reg joystick_right,
//=========디버깅 용===============
	output wire [11:0] x_axis_data,
	output wire [11:0] y_axis_data
);
//--------XADC 내부 신호-----------
	wire	[6:0]	channel_out;
	wire			eoc_out;
	wire			drdy_out;
	wire	[15:0]	do_out;
	
	reg	[6:0]	daddr_in;
	reg			den_in;
//-----------X축, Y축 데이터 저장 레지스터------------
	reg	[11:0]	x_data_reg;
	reg	[11:0]	y_data_reg;
//----------FSM 상태 정의--------------------
	localparam	READ_X = 0;
	localparam	WAIT_X = 1;
	localparam	READ_Y = 2;
	localparam	WAIT_X = 3;
	reg	[1:0]	state = READ_X;

	localparam THRESHOLD_LOW = 1000;
	localparam THRESHOLD_HIGH = 3000;
	
	xadc_wiz_0	xadc_inst(
		.daddr_in(daddr_in),
		.dclk_in(clk_100MHz),
		.den_in(den_in),
		.di_in(0),
		.dwe_in(0),
		.busy_out(),
		.vauxp6(joy_x_p),
		.vauxp6(joy_x_n),
		.vauxp7(joy_y_p),
		.vauxp7(joy_y_n),
		.vn_in(1'b0),
		.vp_in(1'b0),
		.alarm_out(),
		.do_out(do_out),
		.eoc_out(eoc_out),
		.channel_out(channel_out),
		.drdy_out(drdy_out)
	);
	
	always@(posedge clk_1MHz or negedge rst_n) begin
		if(~rst_n) begin
			state <= READ_X;
			den_in <= 0;
			daddr_in <= 0;
			x_data_reg <= 0;
			y_data_reg <= 0;
		end 
		else begin
			case(state)
				READ_X: begin
					daddr_in <= 7'h16; //x축 채널 주소(vauxp6)->Xilinx FPGA의 공식 데이터시트에 명시된 하드웨어 고유 주소
					den_in <= 1'b1;
					state <= WAIT_X;
				end
				WAIT_X: begin
					den_in <= 1'b0;
					if(drdy_out) begin
						x_data_reg <= do_out[15:4];
						state <= READ_Y;
					end
				end
				READ_Y: begin
					daddr_in <= 7'h17; //Y축 채널 주소(vauxp7)
					den_in <= 1'b1;
					state <= WAIT_Y;
				end
				WAIT_Y: begin
					den_in <= 1'b0;
					if(drdy_out) begin
						x_data_reg <= do_out[15:4];
						state <= READ_X;
					end
				end
			endcase
		end
	end		
// 디지털 값으로 변환된 조이스틱 데이터를 기반으로 제어 신호 생성
// 이 부분은 엣지 검출(Edge Detection)을 추가하여 펄스 신호로 만드는 것이 좋습니다.	
	always@(posedge clk_1MHz or negedge rst_n) begin
		if(~rst_n) begin
			joystick_up <= 1'b0;
			joystick_down <= 1'b0;
			joystick_right <= 1'b0;
			joystick_left <= 1'b0;
		end
		else begin
// 임계값(Threshold) 설정 (12비트: 0~4095, 중앙값: ~2048)
// 이 값들은 7세그먼트 디버깅을 통해 실제 조이스틱에 맞게 조정해야 합니다.		

			
			if (x_data_reg > DEAD_ZONE_LOW && x_data_reg < DEAD_ZONE_HIGH && y_data_reg > DEAD_ZONE_LOW && y_data_reg < DEAD_ZONE_HIGH) begin
				joystick_up <= 1'b0;
				joystick_down <= 1'b0;
				joystick_right <= 1'b0;
				joystick_left <= 1'b0;
			end	
			else begin
				if(y_data_reg > THRESHOLD_HIGH) joystick_up <= 1'b1;
				else if(y_data_reg < THRESHOLD_LOW) joystick_down <= 1'b1;
			
				if(x_data_reg < THRESHOLD_LOW) joystick_left <= 1'b1;
				else if(x_data_reg > THRESHOLD_HIGH) joystick_right <= 1'b1;
			end
		end
	end
	
	assign x_axis_data = x_data_reg;
	assign y_axis_data = y_data_reg;
endmodule

			

