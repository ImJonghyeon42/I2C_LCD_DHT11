//UART로부터 데이터(uart_data_valid, uart_data_in)를 직접 입력받도록 포트를 추가
//블루투스 데이터가 들어오면, 버튼 입력보다 우선하여 메뉴 상태(btn_LR_out, btn_UD_out)를 변경
//Cotton -> Woody, Woody -> Citrus, Citrus->Cotton -> 잘 못 들어감
// uart_rx pc용 추가
//btn_OK 추가
// btn_OK 버튼을 꾹 누르면 pump_off
// btn_OK를 짧게 눌렀을 때(long_press_counter가 다 차기 전)
// manual_on 대신 pump_on 신호를 발생시켜 주기 타이머를 시작합니다.
//디버깅 용 led 추가
module mode_controller (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input btn_U,
    input btn_D,
	input btn_OK,
	input uart_data_valid_pc,
	input uart_data_valid,
    input [7:0] uart_data_in,
    input [7:0] uart_data_in_pc,
    output reg [1:0] btn_LR_out, 
    output reg [1:0] btn_UD_out,
	output reg pump_on,
	output reg manual_on,
	output reg pump_off,
	output reg [4:0] led,
	output reg mode_select
); 
    localparam LONG_PRESS_TARGET = 3_000_000; // 3초
    localparam MODE_SWITCH_TARGET = 2_000_000; // 2초
    localparam ONE_SECOND = 1_000_000; // 1초
    localparam TWO_SECOND = 2_000_000; // 2초
	reg [22:0] long_press_counter;
	reg [21:0] up_long_press_counter;

    reg btn_R_reg, btn_R_prev;
    reg btn_L_reg, btn_L_prev;
    reg btn_U_reg, btn_U_prev;
    reg btn_D_reg, btn_D_prev;
    reg btn_OK_reg, btn_OK_prev;
    
    wire btn_R_rise, btn_U_rise, btn_L_rise, btn_D_rise,btn_OK_rise;
    assign btn_R_rise = ~btn_R_prev & btn_R_reg;
    assign btn_L_rise = ~btn_L_prev & btn_L_reg;
    assign btn_U_rise = ~btn_U_prev & btn_U_reg;
    assign btn_D_rise = ~btn_D_prev & btn_D_reg;
    assign btn_OK_rise = ~btn_OK_prev & btn_OK_reg;

    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            btn_R_reg  <= 0; btn_R_prev  <= 0;
            btn_OK_reg  <= 0; btn_OK_prev  <= 0;
            btn_L_reg  <= 0; btn_L_prev  <= 0;
            btn_U_reg  <= 0; btn_U_prev  <= 0;
            btn_D_reg  <= 0; btn_D_prev  <= 0;
            btn_UD_out <= 0; btn_LR_out  <= 0;
			pump_on <= 0; pump_off <= 0; manual_on <= 0;
			long_press_counter <= 0;
			up_long_press_counter <= 0;
			mode_select <= 1'b0;
        end else begin
            btn_R_prev <= btn_R_reg;
            btn_L_prev <= btn_L_reg;
            btn_U_prev <= btn_U_reg;
            btn_D_prev <= btn_D_reg;
            btn_OK_prev <= btn_OK_reg;
            
            btn_R_reg <= btn_R;
            btn_L_reg <= btn_L;
            btn_U_reg <= btn_U;
            btn_D_reg <= btn_D;
            btn_OK_reg <= btn_OK;
			
			pump_on <= 1'b0;
			pump_off <= 1'b0;
			manual_on <= 1'b0;
			
			if(btn_U && !btn_L && !btn_R && !btn_D) begin
				if(up_long_press_counter < MODE_SWITCH_TARGET) begin
					up_long_press_counter <= up_long_press_counter + 1;
				end
			end else begin
				up_long_press_counter <= 0;
			end
			
			if(up_long_press_counter == MODE_SWITCH_TARGET) begin
				mode_select <= ~mode_select;
				up_long_press_counter <= 0;
			end
			
			if(btn_OK) begin 
				if(long_press_counter < LONG_PRESS_TARGET) long_press_counter <= long_press_counter + 1'b1;
			end
			else long_press_counter <= 0;
			
			if(long_press_counter == LONG_PRESS_TARGET) pump_off <= 1'b1;
			
			if (uart_data_valid) begin
                case (uart_data_in)
                    8'h01: btn_LR_out <= 2'd2; // Citrus -> 2'd0 -> 2'd2 
                    8'h02: btn_LR_out <= 2'd0; // Cotton -> 2'd1 -> 2'd0
                    8'h03: btn_LR_out <= 2'd1; // Woody -> 2'd2 -> 2'd1
                    8'h1E: btn_UD_out <= 2'd0; // Timer 30min
                    8'h3C: btn_UD_out <= 2'd1; // Timer 60min
                    8'h78: btn_UD_out <= 2'd2; // Timer 120min
					8'h04: pump_on <= 1'b1;
					8'h05: pump_off <= 1'b1;
                    default: ;
                endcase
            end
			
			else if (uart_data_valid_pc) begin
                case (uart_data_in_pc)
                    8'h01: btn_LR_out <= 2'd2; // Citrus -> 2'd0 -> 2'd2 
                    8'h02: btn_LR_out <= 2'd0; // Cotton -> 2'd1 -> 2'd0
                    8'h03: btn_LR_out <= 2'd1; // Woody -> 2'd2 -> 2'd1
                    default: ;
                endcase
			end
            
            else begin
				if(mode_select == 1'b0) begin
					if (btn_R_rise) begin
						if (btn_LR_out < 2'd2) btn_LR_out <= btn_LR_out + 1;
						else btn_LR_out <= 2'd0;
					end else if (btn_L_rise) begin
						if (btn_LR_out > 2'd0) btn_LR_out <= btn_LR_out - 1;
						else btn_LR_out <= 2'd2;
					end	

					if (btn_U_rise) begin
						if (btn_UD_out < 2'd2) btn_UD_out <= btn_UD_out + 1;
						else btn_UD_out <= 2'd0;
					end else if (btn_D_rise) begin
						if (btn_UD_out > 2'd0) btn_UD_out <= btn_UD_out - 1;
						else btn_UD_out <= 2'd2;
					end
				end
				
				if(btn_OK_rise && long_press_counter < LONG_PRESS_TARGET) begin
					if(mode_select == 1'b0) pump_on <= 1'b1; // manual_on <= 1'b1 => pump_on <= 1'b1;
				end
				
			end
			if(!btn_OK) led [2:4] <= 3'd0;
			else if (long_press_counter >= LONG_PRESS_TARGET) led [2:4] <= 3'b111;			
			else if (long_press_counter >= TWO_SECOND) led [2:4] <= 3'b011;
			else if(long_press_counter >= ONE_SECOND) led [2:4] <= 3'b001;
			else led [2:4] <= 3'd0;
			
			if(!btn_U) led [0:1] <= 2'b0;
			else if( up_long_press_counter >= MODE_SWITCH_TARGET) led [0:1] <= 2'b11; 
			else if( up_long_press_counter >= ONE_SECOND) led [0:1] <= 2'b01;
			else led [0:1] <= 2'd0; 
		end
	end
endmodule